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
extension KeyedDecodingContainer
{
    // -------------------------------------
    func decode(
        _ type: Dictionary<String, Any>.Type,
        forKey key: K) throws -> Dictionary<String, Any>
    {
        let container = try self.nestedContainer(
            keyedBy: JSONRPC.CodingKey.self,
            forKey: key
        )
        return try container.decode(type)
    }
    
    // -------------------------------------
    func decodeIfPresent(
        _ type: Dictionary<String, Any>.Type,
        forKey key: K) throws -> Dictionary<String, Any>?
    {
        guard contains(key) else { return nil }
        return try decode(type, forKey: key)
    }
    
    // -------------------------------------
    func decode(_ type: Array<Any?>.Type, forKey key: K) throws -> Array<Any?>
    {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }
    
    // -------------------------------------
    func decodeIfPresent(
        _ type: Array<Any?>.Type,
        forKey key: K) throws -> Array<Any?>?
    {
        guard contains(key) else { return nil }
        return try decode(type, forKey: key)
    }
    
    // -------------------------------------
    func decode(
        _ type: Dictionary<String, Any>.Type) throws -> Dictionary<String, Any>
    {
        var dict = Dictionary<String, Any>()
        
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
            for key in allKeys.sorted(by: {$0.stringValue < $1.stringValue }) {
                try decodeValue(for: key, into: &dict)
            }
        }
        else
        {
            for key in allKeys {
                try decodeValue(for: key, into: &dict)
            }
        }
        return dict
    }
    
    // -------------------------------------
    private func decodeValue(
        for key: K, into dict: inout [String: Any]) throws
    {
        if let boolValue = try? decodeIfPresent(Bool.self, forKey: key) {
            dict[key.stringValue] = boolValue
        }
        else if let intValue = try? decodeIfPresent(Int.self, forKey: key) {
            dict[key.stringValue] = intValue
        }
        else if let doubleValue =
            try? decodeIfPresent(Double.self, forKey: key)
        {
            dict[key.stringValue] = doubleValue
        }
        else if let stringValue =
            try? decodeIfPresent(String.self, forKey: key)
        {
            dict[key.stringValue] = stringValue
        }
        else if let customValue =
            try? decodeCustomTypesIfPresent(forKey: key)
        {
            dict[key.stringValue] = customValue
        }
        else if let nestedDictionary =
            try? decodeIfPresent(Dictionary<String, Any>.self, forKey: key)
        {
            dict[key.stringValue] = nestedDictionary
        }
        else if let nestedArray =
            try decodeIfPresent(Array<Any?>.self, forKey: key)
        {
            dict[key.stringValue] = nestedArray
        }
    }

    // -------------------------------------
    func decodeCustomTypesIfPresent<K>(
        forKey key: KeyedDecodingContainer<K>.Key) throws -> Any?
    {
        /* Example for decoding custom type
        if let fileMetaData =
            try decodeIfPresent(Asset.FileMetadata.self, forKey: key)
        {
            return fileMetaData
        }
         */
        
        return nil
    }
}
