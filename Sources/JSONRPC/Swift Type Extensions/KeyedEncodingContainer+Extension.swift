// Copyright 2021 Chip Jarred
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

// -------------------------------------
internal let runningUnitTests: Bool =
{
    let pInfo = ProcessInfo.processInfo
    return pInfo.environment["XCTestConfigurationFilePath"] != nil
}()

// -------------------------------------
extension KeyedEncodingContainer
{
    // -------------------------------------
    mutating func encode(_ array: [Any?], forKey key: K) throws
    {
        var container = nestedUnkeyedContainer(forKey: key)
        try container.encode(array)
    }
    
    // -------------------------------------
    mutating func encode(_ dict: [String: Any], forKey key: K) throws
    {
        var container =
            nestedContainer(keyedBy: JSONRPC.CodingKey.self, forKey: key)
        try container.encode(dict)
    }
    
    // -------------------------------------
    internal mutating func encode(_ dict: [String: Any]) throws
    {
        /*
         We want to use sorted keys for running in unit tests, because the
         keys returned by the Dictionary's .keys variable are not in the
         same order from run to run even when the exact same keys are
         inserted with the exact same values in the exact same order, or
         even when using Dictionary literals.
         
         By sorting the keys, we can ensure that the encoding is the same
         byte sequence between runs, which allows unit tests to easily
         verify them with simple comparisons.
         
         When not in unit tests, we don't want the overhead of sorting the
         keys.  Although most dictionaries are small, in principle they can
         be quite large.  We also don't want to have different behavior in
         general debug builds than in release builds, and we need unit test
         being run with a release build to behave consistently with unit
         tests run with debug builds.  So the test is not for DEBUG, but
         rather for whether we are running in XCTest.  Unfortunately that's not
         something that can be determined at compile-time, so this is a
         run-time test that cannot be eliminated by the compiler, but it is at
         least a reasonably fast test.
         */
        if runningUnitTests
        {
            for key in dict.keys.sorted() {
                try encodeValue(for: key, in: dict)
            }
        }
        else
        {
            for key in dict.keys {
                try encodeValue(for: key, in: dict)
            }
        }
    }
    
    // -------------------------------------
    private mutating func encodeValue(
        for key: String, in dict: [String: Any]) throws
    {
        guard let dictValue = dict[key] else { return }
            
        let codingKey = K(stringValue: key)!
        
        if let value = dictValue as? Bool {
            try encode(value, forKey: codingKey)
        }
        else if let value = dictValue as? Int {
            try encode(value, forKey: codingKey)
        }
        else if let value = dictValue as? Double {
            try encode(value, forKey: codingKey)
        }
        else if let value = dictValue as? String {
            try encode(value, forKey: codingKey)
        }
        else if let value = dictValue as? [Any?] {
            try encode(value, forKey: codingKey)
        }
        else if try encodeCustomTypes(dictValue, forKey: codingKey) {
            return
        }
        else if let value = dictValue as? [String: Any] {
            try encode(value, forKey: codingKey)
        }
        else
        {
            throw EncodingError.invalidValue(
                dictValue,
                EncodingError.Context(
                    codingPath: codingPath,
                    debugDescription:
                        "Unsupported type, \(type(of: dictValue)), for "
                        + "encoding"
                )
            )
        }
    }
    
    // -------------------------------------
    mutating func encodeCustomTypes(_ value: Any, forKey: K) throws -> Bool
    {
        /* Example of encoding custom type
         if let fileMetaData = value as? Asset.FileMetadata
         {
            try encode(fileMetaData, forKey: key)
            return true
         }
         */
        
        return false
    }
}
