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
extension UnkeyedEncodingContainer
{
    // -------------------------------------
    mutating func encode(_ array: [Any?]) throws
    {
        for element in array
        {
            if element == nil {
                try encodeNil()
            }
            else if let value = element as? Bool {
                try encode(value)
            }
            else if let value = element as? Int {
                try encode(value)
            }
            else if let value = element as? Double {
                try encode(value)
            }
            else if let value = element as? String {
                try encode(value)
            }
            else if let nestedArray = element as? [Any?]
            {
                var container = nestedUnkeyedContainer()
                try container.encode(nestedArray)
            }
            else if try encodeCustomTypes(element!) {
                continue
            }
            else if let nestedDict = element as? [String: Any] {
                try encode(nestedDict)
            }
            else
            {
                throw EncodingError.invalidValue(
                    element!,
                    EncodingError.Context(
                        codingPath: codingPath,
                        debugDescription:
                            "Unsupported type, \(type(of: element!)), for "
                            + "encoding"
                    )
                )
            }
        }
    }
    
    // -------------------------------------
    mutating func encode(_ dict: [String: Any]) throws
    {
        var container = nestedContainer(keyedBy: JSONRPC.CodingKey.self)
        try container.encode(dict)
    }
    
    // -------------------------------------
    mutating func encodeCustomTypes(_ value: Any) throws -> Bool
    {
        /* Example of encoding custom type
         if let fileMetaData = value as? Asset.FileMetadata
         {
            try encode(fileMetaData)
            return true
         }
         */
        
        return false
    }
}
