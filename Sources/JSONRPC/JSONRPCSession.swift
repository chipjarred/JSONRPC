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

import Async
import NIX

// -------------------------------------
public class JSONRPCSession: JSONRPCResponder, JSONRPCLogger
{
    typealias RequestID = Int
    public typealias RequestCompletion = (Response) -> Void
    
    public unowned var server: JSONRPCServer
    private let versionToUse: Version = .v2
    
    private let peerAddress: SocketAddress
    private let peerSocket: SocketIODescriptor
    
    private var curRequestIDMutex = SpinLock()
    private var _curRequestID: Int = 1
    private var nextRequestID: Int
    {
        return curRequestIDMutex.withLock
        {
            defer { _curRequestID += 1 }
            return _curRequestID
        }
    }
    
    private var writeMutex = Mutex()

    private var completionHandlersMutex = Mutex()
    private var completionHandlers: [RequestID: RequestCompletion] = [:]
    
    public var encoder = JSONEncoder()
    public var decoder = JSONDecoder()
    
    // -------------------------------------
    public init(
        from server: JSONRPCServer,
        forPeerSocket peerSocket: SocketIODescriptor,
        at peerAddress: SocketAddress)
    {
        self.server = server
        self.peerSocket = peerSocket
        self.peerAddress = peerAddress
    }
    
    // -------------------------------------
    deinit
    {
        if let error = NIX.close(peerSocket)
        {
            log(
                .warn,
                "\(Self.self): Failed to close peer socket: \(error)"
            )
        }
        
        self.log(.info, "Ended session with \(peerAddress).")
    }
    
    // -------------------------------------
    internal final func start()
    {
        self.log(.info, "Started session with \(peerAddress).")
        
        defer { server.sessionEnded(for: self) }
        
        var lineReader = SocketLineReader(logger: self)
        
        while true
        {
            guard let line = lineReader.readLine(from: peerSocket) else {
                break
            }
            
            log(.info, "\(Self.self): Received JSON: \"\(line)\"")
            
            do
            {
                if let response = try translateAndDispatch(jsonData: line)
                {
                    try write(response)
                    log(.info, "\(Self.self): Sent JSON: \"\(response)\"")
                }
            }
            catch { break }
        }
    }
    
    // -------------------------------------
    internal final func write(_ data: Data) throws
    {
        let bytesWritten: Int
        switch writeMutex.withLock({ NIX.write(peerSocket, data) })
        {
            case .success(let b): bytesWritten = b
            case .failure(let error):
                log(
                    .error,
                    "\(Self.self): Unable to write response to peer socket:"
                    + " \(error)"
                )
                throw ErrorCode.internalError
        }
        
        if bytesWritten != data.count
        {
            log(
                .error,
                "\(Self.self): Failed to write all bytes of data to "
                + "peer socket: \(bytesWritten) of \(data.count) bytes "
                + "written"
            )
            throw ErrorCode.internalError
        }
    }
    
    // -------------------------------------
    public final func handleNotification(_ notification: Notification) {
        unimplemented()
    }
    
    // -------------------------------------
    public final func handleRequest(_ request: Request) throws -> Response {
        unimplemented()
    }
    
    // -------------------------------------
    public final func handleResponse(_ response: Response)
    {
        /*
         If the response has an id, then it belongs to a specific request,
         so we send it to that request's completion handler, and remove that
         handler.
         
         If it doesn't have an id, then it's a non-specific response.  For now
         we broadcast it to all completion handlers, but we don't remove them.
         */
        if let responseID = response.id
        {
            let handler = completionHandlersMutex.withLock {
                completionHandlers.removeValue(forKey: responseID)
            }
            _ = async { handler?(response) }
        }
        else
        {
            completionHandlersMutex.withLock
            {
                for handler in completionHandlers.values {
                    _ = async { handler(response) }
                }
            }
        }
    }
    
    // -------------------------------------
    public final func request(
        method: String,
        completion: @escaping RequestCompletion)
    {
        request(method: method, parameters: nil, completion: completion)
    }
    
    // -------------------------------------
    public final func request(
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
    public final func request(
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
    private func request(
        method: String,
        parameters: Request.Parameters?,
        completion: @escaping RequestCompletion)
    {
        sendRequest(
            GeneralRequest(
                version: versionToUse,
                id: nextRequestID,
                method: method,
                params: parameters
            ),
            completion: completion
        )
    }
    
    // -------------------------------------
    public final func notify(method: String) {
        notify(method: method, parameters: nil)
    }
    
    // -------------------------------------
    public final func notify(method: String, parameters: [Any?]) {
        notify(method: method, parameters: .positional(parameters))
    }
    
    // -------------------------------------
    public final func notify(method: String, parameters: [String: Any]) {
        notify(method: method, parameters: .named(parameters))
    }

    // -------------------------------------
    private final func notify(method: String, parameters: Request.Parameters?)
    {
        sendRequest(
            GeneralRequest(
                version: versionToUse,
                id: nil,
                method: method,
                params: parameters
            ),
            completion: nil
        )
    }

    // -------------------------------------
    private func sendRequest(
        _ request: GeneralRequest,
        completion: RequestCompletion?)
    {
        assert(
            (request.id == nil) == (completion == nil),
            "Requests require both an id and a completion handler, and "
            + "Notifications must have neither."
        )
        
        // If there is a handler, register it
        if let completion = completion
        {
            completionHandlersMutex.withLock {
                self.completionHandlers[request.id!] = completion
            }
        }
        
        /*
         If we can't encode the request, immediately manufacture an parse error
         and handle it.
         */
        guard let data = try? encoder.encode(request) else
        {
            _ = async
            {
                self.handleResponse(
                    Response(for: request, error: .parseError)
                )
            }
            return
        }
        
        /*
         If we fail to write, immediately manufacture an internal error and
         handle it.
         */
        do { try write(data) }
        catch
        {
            if request.id != nil { // Notifications don't get responses
                handleResponse(Response(for: request, error: .internalError))
            }
        }
    }
}

// -------------------------------------
extension JSONRPCSession: Hashable
{
    // -------------------------------------
    public static func == (lhs: JSONRPCSession, rhs: JSONRPCSession) -> Bool {
        return lhs === rhs
    }
    
    // -------------------------------------
    public func hash(into hasher: inout Hasher) {
        hasher.combine(peerSocket.descriptor)
    }
}
