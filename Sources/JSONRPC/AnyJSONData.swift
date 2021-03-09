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
public enum AnyJSONData: Codable
{
    case boolean(_: Bool)
    case integer(_: Int)
    case double(_: Double)
    case string(_: String)
    case array(_: [Any?])
    case object(_: [String: Any])
    
    // -------------------------------------
    public init?<T: Codable>(_ value: T)
    {
        guard let json = try? JSONEncoder().encode(value),
              let anyData = try? JSONDecoder().decode(Self.self, from: json)
        else { return nil }
        
        self = anyData
    }
    
    // -------------------------------------
    public init(from decoder: Decoder) throws
    {
        if let value = try Self.decodeSingleValue(from: decoder) {
            self = value
        }
        else if let array = try Self.decodeArray(from: decoder) {
            self = array
        }
        else if let object = try Self.decodeObject(from: decoder) {
            self = object
        }
        else
        {
            throw DecodingError.valueNotFound(
                Self.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription:
                        "Unable to decode JSON - not a single value, nor "
                        + "an array, nor an object"
                )
            )
        }
    }
    
    // -------------------------------------
    private static func decodeSingleValue(from decoder: Decoder) throws -> Self?
    {
        let container = try decoder.singleValueContainer()
        
        if let value = try? container.decode(Bool.self) {
            return .boolean(value)
        }
        else if let value = try? container.decode(Int.self) {
            return.integer(value)
        }
        else if let value = try? container.decode(Double.self) {
            return .double(value)
        }
        else if let value = try? container.decode(String.self) {
            return .string(value)
        }
        
        return nil
    }
    
    // -------------------------------------
    private static func decodeArray(from decoder: Decoder) throws -> Self?
    {
        guard var container = try? decoder.unkeyedContainer() else {
            return nil
        }
        
        if let array = try? container.decode([Any?].self) {
            return .array(array)
        }

        return nil
    }
    
    // -------------------------------------
    private static func decodeObject(from decoder: Decoder) throws -> Self?
    {
        let container = try decoder.container(keyedBy: JSONRPC.CodingKey.self)
        
        if let dict = try? container.decode([String: Any].self) {
            return .object(dict)
        }

        return nil
    }

    // -------------------------------------
    public func encode(to encoder: Encoder) throws
    {
        switch self
        {
            case .boolean(let value):
                var container = encoder.singleValueContainer()
                try container.encode(value)
            case .integer(let value):
                var container = encoder.singleValueContainer()
                try container.encode(value)
            case .double(let value):
                var container = encoder.singleValueContainer()
                try container.encode(value)
            case .string(let value):
                var container = encoder.singleValueContainer()
                try container.encode(value)
            case .array(let value):
                var container = encoder.unkeyedContainer()
                try container.encode(value)
            case .object(let value):
                var container =
                    encoder.container(keyedBy: JSONRPC.CodingKey.self)
                try container.encode(value)
        }
    }
}
