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
public struct Response: Codable
{
    public typealias Result = AnyJSONData
            
    @inlinable public var version: Version { Version(rawValue: jsonrpc)! }

    public let jsonrpc: String? // For version 2 JSON-RPC
    public let id: Int
    public let result: Result?
    public let error: Error?
    
    // -------------------------------------
    internal init(for request: Request, result: [Any?])
    {
        self.init(
            version: request.version,
            id: request.id,
            result: .array(result),
            error: nil
        )
    }

    // -------------------------------------
    internal init(for request: Request, result: [String: Any])
    {
        self.init(
            version: request.version,
            id: request.id,
            result: .object(result),
            error: nil
        )
    }
    
    // -------------------------------------
    internal init<Object: Codable>(for request: Request, result: Object)
    {
        guard let anyData = Result(result) else {
            fatalError("Unable to encode \(result)")
        }
        
        self.init(
            version: request.version,
            id: request.id,
            result: anyData,
            error: nil
        )
    }

    // -------------------------------------
    internal init(for request: Request, error: Error)
    {
        self.init(
            version: request.version,
            id: request.id,
            result: nil,
            error: error
        )
    }
    
    // -------------------------------------
    internal init(for request: GeneralRequest, result: [Any?])
    {
        self.init(
            version: request.version,
            id: request.id!,
            result: .array(result),
            error: nil
        )
    }

    // -------------------------------------
    internal init(for request: GeneralRequest, result: [String: Any])
    {
        self.init(
            version: request.version,
            id: request.id!,
            result: .object(result),
            error: nil
        )
    }
    
    // -------------------------------------
    internal init<Object: Codable>(for request: GeneralRequest, result: Object)
    {
        guard let anyData = Result(result) else {
            fatalError("Unable to encode \(result)")
        }
        
        self.init(
            version: request.version,
            id: request.id!,
            result: anyData,
            error: nil
        )
    }

    // -------------------------------------
    internal init(for request: GeneralRequest, error: Error)
    {
        self.init(
            version: request.version,
            id: request.id!,
            result: nil,
            error: error
        )
    }
    
    // -------------------------------------
    @usableFromInline
    internal init(
        version: Version,
        id: Int,
        result: Result?,
        error: Error?)
    {
        precondition(
            (result == nil) != (error == nil),
            "Either result must be non-nil and error nil, or result must be"
            + " nil and error non-nil"
        )
        
        self.jsonrpc = version.rawValue
        self.id = id
        self.result = result
        self.error = error
    }
    
    // MARK:- Codable conformance
    // -------------------------------------
    public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKey.self)
        
        self.jsonrpc = try? container.decode(String.self, forKey: "jsonrpc")

        self.id = try container.decode(Int.self, forKey: "id")
        self.result = try? container.decode(Result.self, forKey: "result")
        self.error = try? container.decode(Error.self, forKey: "error")
        
        guard JSONRPC.isVersionValid(jsonrpc) else {
            try JSONRPC.throwInvalidVersion(for: jsonrpc!, decoder: decoder)
        }

        if (result == nil) && (error == nil)
        {
            throw DecodingError.typeMismatch(
                Self.self, DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Response has neither error nor response"
                )
            )
        }
        else if (result != nil) && (error != nil)
        {
            throw DecodingError.typeMismatch(
                Self.self, DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Response has both error and response"
                )
            )
        }
    }
    
    // -------------------------------------
    public func encode(to encoder: Encoder) throws
    {
        assert(JSONRPC.isVersionValid(jsonrpc))
        assert((result == nil) != (error == nil))
                
        var container = encoder.container(keyedBy: CodingKey.self)
        
        if let version = jsonrpc
        {   // Version 2
            try container.encode(version, forKey: "jsonrpc")
            
            try container.encode(id, forKey: "id")
            
            // Encode either result or error, but not both.
            if let result = self.result {
                try container.encode(result, forKey: "result")
            }
            else if let error = self.error {
                try container.encode(error, forKey: "error")
            }
            else
            {
                throw EncodingError.invalidValue(
                    Self.self, EncodingError.Context(
                        codingPath: container.codingPath,
                        debugDescription:
                            "Neither result nor error could be encoded or both "
                            + "are nil"
                    )
                )
            }
        }
        else
        { // Version 1
            try container.encode(self.id, forKey: "id")
            
            if let result = self.result {
                try container.encode(result, forKey: "result")
            }
            else { try container.encodeNil(forKey: "result") }
            
            if let error = self.error {
                try container.encode(error, forKey: "error")
            }
            else { try container.encodeNil(forKey: "error") }
        }
    }
}
