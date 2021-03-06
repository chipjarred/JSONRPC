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
public protocol JSONRPCSessionDelegate
{
    func willStart(session: JSONRPCSession)
    func didStart(session: JSONRPCSession)
    func willTerminate(session: JSONRPCSession)
    func didTerminate(session: JSONRPCSession)
    
    func respond(to request: Request, for session: JSONRPCSession) -> Response?
    func handle(_ notification: Notification, for session: JSONRPCSession)
}

// -------------------------------------
public extension JSONRPCSessionDelegate
{
    @inlinable func willStart(session: JSONRPCSession) { }
    @inlinable func didStart(session: JSONRPCSession) { }
    @inlinable func willTerminate(session: JSONRPCSession) { }
    @inlinable func didTerminate(session: JSONRPCSession) { }
    
    // -------------------------------------
    @inlinable
    func respond(to: Request, for session: JSONRPCSession) -> Response? {
        return nil
    }
    
    // -------------------------------------
    @inlinable
    func handle(_ notification: Notification, for session: JSONRPCSession) { }
    
    // -------------------------------------
    func response<R: Codable>(for request: Request, result: R) -> Response {
        return Response(for: request, result: result)
    }
    
    // -------------------------------------
    func response(for request: Request, result: [Any?]) -> Response {
        return Response(for: request, result: result)
    }
    
    // -------------------------------------
    func response(for request: Request, result: [String: Any]) -> Response {
        return Response(for: request, result: result)
    }
    
    // -------------------------------------
    func response(for request: Request, error: Error) -> Response {
        return Response(for: request, error: error)
    }
}

// -------------------------------------
public protocol JSONRPCServerSessionDelegate: JSONRPCSessionDelegate {
    init()
}
