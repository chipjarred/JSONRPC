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

// -------------------------------------
public struct Batch
{
    public typealias RequestCompletion = JSONRPCSession.RequestCompletion
    internal var requests: [(GeneralRequest, RequestCompletion?)] = []
    private let session: JSONRPCSession
    
    // -------------------------------------
    internal init(_ session: JSONRPCSession) { self.session = session }
    
    // -------------------------------------
    @inlinable
    public mutating func request(
        method: String,
        completion: @escaping RequestCompletion)
    {
        request(method: method, parameters: nil, completion: completion)
    }
    
    // -------------------------------------
    @inlinable
    public mutating func request(
        method: String,
        parameters: [Any?],
        completion: @escaping RequestCompletion)
    {
        request(
            method: method,
            parameters: .positional(parameters),
            completion: completion
        )
    }
    
    // -------------------------------------
    @inlinable
    public mutating func request(
        method: String,
        parameters: [String: Any],
        completion: @escaping RequestCompletion)
    {
        request(
            method: method,
            parameters: .named(parameters),
            completion: completion
        )
    }

    // -------------------------------------
    @usableFromInline
    internal mutating func request(
        method: String,
        parameters: Request.Parameters?,
        completion: @escaping RequestCompletion)
    {
        requests.append(
            (
                GeneralRequest(
                    version: session.versionToUse,
                    id: session.nextRequestID,
                    method: method,
                    params: parameters
                ),
                completion
            )
        )
    }
    
    // MARK:- Sending Notifications
    // -------------------------------------
    @inlinable
    public mutating func notify(method: String) {
        notify(method: method, parameters: nil)
    }
    
    // -------------------------------------
    @inlinable
    public mutating func notify(method: String, parameters: [Any?]) {
        notify(method: method, parameters: .positional(parameters))
    }
    
    // -------------------------------------
    @inlinable
    public mutating func notify(method: String, parameters: [String: Any]) {
        notify(method: method, parameters: .named(parameters))
    }

    // -------------------------------------
    @usableFromInline
    internal mutating func notify(
        method: String,
        parameters: Request.Parameters?)
    {
        requests.append(
            (
                GeneralRequest(
                    version: session.versionToUse,
                    id: nil,
                    method: method,
                    params: parameters
                ),
                nil
            )
        )
    }
}
