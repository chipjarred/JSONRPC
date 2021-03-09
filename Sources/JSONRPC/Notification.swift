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
public struct Notification
{
    public typealias Parameters = Request.Parameters
    
    @inlinable public var version: Version { Version(rawValue: jsonrpc)! }
    
    public let jsonrpc: String? // For version 2 JSON-RPC
    public let method: String
    public let params: Parameters?

    // -------------------------------------
    @usableFromInline
    internal init(from request: GeneralRequest)
    {
        precondition(request.id == nil, "Notifications may not have an id")
        self.init(
            version: request.version,
            method: request.method,
            params: request.params
        )
    }

    // -------------------------------------
    @usableFromInline
    internal init(
        version: Version,
        method: String,
        params: Parameters?)
    {
        self.jsonrpc = version.rawValue
        self.method = method
        self.params = params
    }
}
