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
public class JSONRPCSession: JSONRPCLogger
{
    typealias RequestID = Int
    public typealias RequestCompletion = (Response) -> Void
    
    public weak var server: JSONRPCServer?
    private let versionToUse: Version = .v2
    
    private let address: SocketAddress
    private let socket: SocketIODescriptor
    
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
    
    // -------------------------------------
    enum State
    {
        case initialized
        case started
        case quitting
        case terminated
    }
    
    private var state: State = .initialized
    
    public var delegate: JSONRPCSessionDelegate? = nil
    
    // -------------------------------------
    internal init(
        from server: JSONRPCServer,
        forPeerSocket peerSocket: SocketIODescriptor,
        at peerAddress: SocketAddress,
        delegate: JSONRPCSessionDelegate)
    {
        self.server = server
        self.socket = peerSocket
        self.address = peerAddress
        self.state = .initialized
        self.delegate = delegate
    }
    
    // -------------------------------------
    public init?(
        serverAddress: SocketAddress,
        delegate: JSONRPCSessionDelegate? = nil)
    {
        self.delegate = delegate
        
        let domain: SocketDomain
        let protocolFamily: ProtocolFamily
        switch serverAddress.family
        {
            case .inet4: (domain, protocolFamily) = (.inet4, .tcp)
            case .inet6: (domain, protocolFamily) = (.inet6, .tcp)
            case .unix : (domain, protocolFamily) = (.local, .ip)
        }
        
        switch NIX.socket(domain, .stream, protocolFamily)
        {
            case .success(let s): self.socket = s
            case .failure(let error):
                Self.log(.error, "Unable to create session socket: \(error)")
                return nil
        }
        
        self.address = serverAddress
        
        if let error = NIX.connect(socket, serverAddress)
        {
            _ = close(socket)
            Self.log(.error, "Unable to connect to \(serverAddress): \(error)")
            return nil
        }
        self.state = .initialized
        
        let sem = DispatchSemaphore(value: 0)
        _ = async
        {
            sem.signal()
            self.start()
        }
        sem.wait(); sem.signal()
    }
    
    // -------------------------------------
    deinit { cleanUp() }
    
    // -------------------------------------
    private func cleanUp()
    {
        guard state != .terminated else { return }
        state = .quitting
        defer { state = .terminated }
        
        delegate?.sessionWillTerminate()

        if let error = NIX.close(socket)
        {
            log(
                .warn,
                "\(Self.self): Failed to close peer socket: \(error)"
            )
        }
        
        self.log(.info, "Ended session with \(address).")
        
        delegate?.sessionDidTerminate()
        server = nil
    }
    
    // -------------------------------------
    public func terminate()
    {
        guard state != .terminated else { return }
        self.log(.info, "Session termination requested.")
        cleanUp()
    }
    
    // -------------------------------------
    internal final func start()
    {
        delegate?.sessionWillStart()
        
        state = .started
        self.log(.info, "Started session with \(address).")
        
        defer { cleanUp() }
        
        var lineReader = SocketLineReader(logger: self)
        
        delegate?.sessionDidStart()
        
        while state != .quitting
        {
            guard let line = lineReader.readLine(from: socket) else {
                break
            }
            
            dispatch(jsonData: line)
        }
        
        server?.sessionEnded(for: self)
    }
    
    // -------------------------------------
    internal final func write(_ data: Data) throws
    {
        var data = data
        data.append(SocketLineReader.newLine)
        let bytesWritten: Int
        switch writeMutex.withLock({ NIX.write(socket, data) })
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
    
    // MARK:- Handling incoming messages
    // -------------------------------------
    func dispatch(jsonData data: Data)
    {
        let decoder = JSONDecoder()
        if let genRequest = try? decoder.decode(GeneralRequest.self, from: data)
        {
            if genRequest.id == nil {
                handleNotification(Notification(from: genRequest))
            }
            else { handleRequest(Request(from: genRequest)) }
            
        }
        else if let response = try? decoder.decode(Response.self, from: data) {
            handleResponse(response)
        }
    }
    
    // -------------------------------------
    public final func handleNotification(_ notification: Notification) {
        _ = async { self.delegate?.handle(notification) }
    }
    
    // -------------------------------------
    public final func handleRequest(_ request: Request)
    {
        _ = async
        {
            self.send(self.delegate?.respond(to: request)
                ?? Response(for: request, error: .methodNotFound)
            )
        }
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
    
    // MARK:- Sending Requests
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
    
    // MARK:- Sending Notifications
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
        guard let data = try? JSONEncoder().encode(request) else
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
    
    // MARK:- Sending Responses
    // -------------------------------------
    private func send(_ response: Response)
    {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(response) else
        {
            log(.error, "Unable to encode response: \(response)")
            let errorResponse = Response(
                    version: versionToUse,
                    id: response.id,
                    result: nil,
                    error: .internalError
            )
            if let data = try? encoder.encode(errorResponse) {
                try? write(data)
            }
            return
        }
        
        do { try write(data) }
        catch { log(.error, "Unable to send response: \(response)") }
    }
}

// MARK:- Hashable Conformance
// -------------------------------------
extension JSONRPCSession: Hashable
{
    // -------------------------------------
    public static func == (lhs: JSONRPCSession, rhs: JSONRPCSession) -> Bool {
        return lhs === rhs
    }
    
    // -------------------------------------
    public func hash(into hasher: inout Hasher) {
        hasher.combine(socket.descriptor)
    }
}
