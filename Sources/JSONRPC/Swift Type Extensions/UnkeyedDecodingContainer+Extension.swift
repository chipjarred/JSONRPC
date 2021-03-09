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
extension UnkeyedDecodingContainer
{
    // -------------------------------------
    mutating func decode(_ type: Array<Any?>.Type) throws -> Array<Any?>
    {
        var array: [Any?] = []
        
        while isAtEnd == false
        {
            if try decodeNil() { array.append(nil) }
            else if let value = try? decode(Bool.self) { array.append(value) }
            else if let value = try? decode(Int.self) { array.append(value) }
            else if let value = try? decode(Double.self) { array.append(value) }
            else if let value = try? decode(String.self) { array.append(value) }
            else if let value = try? decodeCustomType() { array.append(value) }
            else if let nestedDictionary =
                try? decode(Dictionary<String, Any>.self)
            {
                array.append(nestedDictionary)
            }
            else if let nestedArray = try? decode(Array<Any?>.self) {
                array.append(nestedArray)
            }
        }
        return array
    }
    
    // -------------------------------------
    mutating func decode(
        _ type: Dictionary<String, Any>.Type) throws -> Dictionary<String, Any>
    {
        let nestedContainer =
            try self.nestedContainer(keyedBy: JSONRPC.CodingKey.self)
        return try nestedContainer.decode(type)
    }
    
    // -------------------------------------
    func decodeCustomType() throws -> Any
    {
        /* Example for decoding custom type
        if let fileMetaData = try decode(Asset.FileMetadata.self, forKey: key) {
            return fileMetaData
        }
         */
        
        throw DecodingError.valueNotFound(
            Any.self,
            DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "No value of a supported custom type found"
            )
        )
    }
}
