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
public enum ErrorCode: Int, Swift.Error, Codable, CustomStringConvertible
{
    /**
     Invalid JSON was received by the server.
     
     An error occurred on the server while parsing the JSON text.
     */
    case parseError     = -32700
    
    /// The JSON sent is not a valid Request object.
    case invalidRequest = -32600
    
    /// The method does not exist or is not available.
    case methodNotFound = -32601
    
    /// Invalid method parameter(s).
    case invalidParams  = -32602
    
    /// Internal JSON-RPC error.
    case internalError  = -32603
    
    // -------------------------------------
    public var message: String
    {
        switch self
        {
            case .parseError:
                return "Invalid JSON was received by the server."
            case .invalidRequest:
                return "The JSON sent is not a valid Request object."
            case .methodNotFound:
                return "The method does not exist or is not available."
            case .invalidParams:
                return "Invalid method parameter(s)."
            case .internalError:
                return "Internal JSON-RPC error."
        }
    }
    
    // -------------------------------------
    @inlinable
    public var localizedDescription: String {
        return "\(rawValue): \(message)"
    }
    
    // -------------------------------------
    @inlinable
    public var description: String { localizedDescription }
}

// -------------------------------------
public struct Error: Codable
{
    public let code: Int
    public let message: String
    public let data: AnyJSONData?
    
    // -------------------------------------
    @inlinable
    public init(code: Int, message: String, data: AnyJSONData?)
    {
        self.code = code
        self.message = message
        self.data = data
    }
    
    // -------------------------------------
    public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: JSONRPC.CodingKey.self)
        self.code = try container.decode(Int.self, forKey: "code")
        self.message = try container.decode(String.self, forKey: "message")
        self.data = try container.decodeIfPresent(
            JSONRPC.AnyJSONData.self,
            forKey: "data"
        )
    }
    
    // -------------------------------------
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: JSONRPC.CodingKey.self)
        try container.encode(self.code, forKey: "code")
        try container.encode(self.message, forKey: "message")
        
        if let data = self.data {
            try container.encode(data, forKey: "data")
        }
        else {
            try container.encode("", forKey: "data")
        }
    }
}
