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
public struct Request
{
    // -------------------------------------
    public enum Parameters: Codable
    {
        case positional([Any?])
        case named([String: Any])
        
        // -------------------------------------
        @inlinable
        public var count: Int
        {
            switch self
            {
                case .positional(let p): return p.count
                case .named(let p): return p.count
            }
        }
        
        // -------------------------------------
        @inlinable
        public var isEmpty: Bool { count == 0 }
        
        // -------------------------------------
        public init(from decoder: Decoder) throws
        {
            if var container = try? decoder.unkeyedContainer() {
                let params = try container.decode([Any?].self)
                self = .positional(params)
            }
            else
            {
                let container = try decoder.container(keyedBy: CodingKey.self)
                let params = try container.decode([String: Any].self)
                self = .named(params)
            }
        }
        
        // -------------------------------------
        public func encode(to encoder: Encoder) throws
        {
            switch self
            {
                case .positional(let params):
                    var container = encoder.unkeyedContainer()
                    try container.encode(params)
                case .named(let params):
                    var container = encoder.container(keyedBy: CodingKey.self)
                    try container.encode(params)
            }
        }
    }

    @inlinable public var version: Version { Version(rawValue: jsonrpc)! }
    
    public let jsonrpc: String? // For version 2 JSON-RPC
    public let id: Int
    public let method: String
    public let params: Parameters?
    
    // -------------------------------------
    @usableFromInline
    internal init(from request: GeneralRequest)
    {
        precondition(request.id != nil, "Request must have an id")
        
        self.init(
            version: request.version,
            id: request.id!,
            method: request.method,
            params: request.params
        )
    }
    
    // -------------------------------------
    @usableFromInline
    internal init(
        version: Version,
        id: Int,
        method: String,
        params: Parameters?)
    {
        self.jsonrpc = version.rawValue
        self.id = id
        self.method = method
        self.params = params
    }
}
