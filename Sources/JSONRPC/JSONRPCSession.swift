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
    public typealias RequestCompletion = (Result<AnyJSONData,Error>) -> Void
    
    public weak var server: JSONRPCServer?
    internal let versionToUse: Version = .v2
    
    private let address: SocketAddress
    private let socket: SocketIODescriptor
    
    private var curRequestIDMutex = SpinLock()
    private var _curRequestID: Int = 1
    internal var nextRequestID: Int
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
    public var sendLogger: ((Data) -> Void)? = nil
    public var receiveLogger: ((Data) -> Void)? = nil
    
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
    public static func connect(
        to host: String,
        port: Int,
        delegate: JSONRPCSessionDelegate? = nil) -> JSONRPCSession?
    {
        guard let (ip4ServerAddress, ip6ServerAddress) =
                socketAddress(for: host, port: port)
        else { return nil }

        // Prefer IPv6 if we can get it.  If not, fail-over to IPv4
        if let serverAddress = ip6ServerAddress,
           let client = JSONRPCSession(
            serverAddress: serverAddress,
            delegate: delegate)
        {
            return client
        }
        else if let serverAddress = ip4ServerAddress,
           let client = JSONRPCSession(
            serverAddress: serverAddress,
            delegate: delegate)
        {
            return client
        }
        else { unreachable() }
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
    private static func dnsLookup(host: String) -> [SocketAddress]?
    {
        let host = CFHostCreateWithName(nil, host as CFString)
            .takeRetainedValue()
        
        CFHostStartInfoResolution(host, .addresses, nil)
        
        var success: DarwinBoolean = false
        if let addresses = CFHostGetAddressing(host, &success)?
            .takeUnretainedValue() as NSArray?
        {
            var resultAddresses = [SocketAddress]()
            resultAddresses.reserveCapacity(addresses.count)
            for case let anAddress as NSData in addresses
            {
                let socketAddress = anAddress.bytes
                    .assumingMemoryBound(to: SocketAddress.self).pointee
                resultAddresses.append(socketAddress)
            }
            return resultAddresses
        }
        return nil
    }
    
    // -------------------------------------
    private static func socketAddress(
        for host: String,
        port: Int) -> (SocketAddress?, SocketAddress?)?
    {
        let addresses: [SocketAddress]
        switch NIX.sockaddr(for: host, port: port, socketType: .stream)
        {
            case .success(let addrs): addresses = addrs
            case .failure(_):
                guard let addrs = dnsLookup(host: host) else { return nil }
                addresses = addrs
        }
        
        guard addresses.count > 0 else { return nil }
        
        var ip4ServerAddress: SocketAddress? = nil
        var ip6ServerAddress: SocketAddress? = nil
        
        for address in addresses
        {
            if var address = address.asINET6
            {
                address.port = port
                ip6ServerAddress = ip6ServerAddress ?? SocketAddress(address)
            }
            else if var address = address.asINET4
            {
                address.port = port
                ip4ServerAddress = ip4ServerAddress ?? SocketAddress(address)
            }
        }
        
        return (ip4: ip4ServerAddress, ip6: ip6ServerAddress)
    }

    // -------------------------------------
    deinit { cleanUp() }
    
    // -------------------------------------
    private func cleanUp()
    {
        guard state != .terminated else { return }
        state = .quitting
        defer { state = .terminated }
        
        delegate?.willTerminate(session: self)

        if let error = NIX.close(socket)
        {
            log(
                .warn,
                "\(Self.self): Failed to close peer socket: \(error)"
            )
        }
        
        self.log(.info, "Ended session with \(address).")
        
        delegate?.didTerminate(session: self)
        server = nil
    }
    
    // -------------------------------------
    /**
     Set a closure to log raw JSON that is set
     */
    public func logSend(with logger: @escaping (Data) -> Void) {
        sendLogger = logger
    }
    
    // -------------------------------------
    /*
     Set a closure to log raw JSON that is received
     */
    public func logReceive(with logger: @escaping (Data) -> Void) {
        receiveLogger = logger
    }

    
    // -------------------------------------
    public final func terminate()
    {
        guard state != .terminated else { return }
        self.log(.info, "Session termination requested.")
        cleanUp()
    }
    
    // -------------------------------------
    internal final func start()
    {
        delegate?.willStart(session: self)
        
        state = .started
        self.log(.info, "Started session with \(address).")
        
        defer { cleanUp() }
        
        var lineReader = SocketLineReader(logger: self)
        
        delegate?.didStart(session: self)
        
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
        
        sendLogger?(data)
        
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
    private func dispatch(jsonData data: Data)
    {
        receiveLogger?(data)
        
        /*
         Although it's a good thing for type-safety, Swift makes us specify the
         type of thing we're decoding, so we have to try to decode each
         possibility.  Those are, in order, single notifications and single
         requests, single responses, batched requests and notifications, and
         finally batched responses.
         
         If it's none of those, then we try to parse it into some arbitray JSON
         data, just to see if it's valid JSON.  If it is, then we reply with an
         invalid request error.  If it's not even valid JSON, we reply with a
         parse error.
         */
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
        else if let batch =
            try? decoder.decode([GeneralRequest].self, from: data)
        {
            if batch.count > 0 { handleBatchedRequests(batch) }
            else {  _ = async { self.send(Response(error: .invalidRequest)) } }
        }
        else if let batch = try? decoder.decode([Response].self, from: data) {
            handleBatchedResponses(batch)
        }
        else if let _ = try? decoder.decode(AnyJSONData.self, from: data) {
            _ = async { self.send(Response(error: .invalidRequest)) }
        }
        else { _ = async { self.send(Response(error: .parseError)) } }
        
    }
    
    // -------------------------------------
    private func handleBatchedRequests(_ batch: [GeneralRequest])
    {
        /*
         Since JSON-RPC V2.0 spec says that batched requests receive batched
         responses, we can't just iterate through the batch dispatching the
         requests and notifications through the normal mechanism.  Instead, we
         have to capture the respones, put them into an array which we then
         encode and send as the batched response.
         */
        _ = async
        {
            /*
             Handle all of the requests and notifications in the batch
             asynchronously, collecting the futures for their responses
             */
            var futures = [Future<Response>]()
            futures.reserveCapacity(batch.count)
            
            for request in batch
            {
                if request.id == nil {
                    self.handleNotification(Notification(from: request))
                }
                else
                {
                    futures.append(
                        async { self.dispatch(request: Request(from: request)) }
                    )
                }
            }
            
            // Wait for each response, and put it into a response batch.
            var responses = [Response]()
            responses.reserveCapacity(futures.count)
            
            for future in futures {
                if let response = future.value { responses.append(response) }
            }
            
            // JSON-RPC V2.0 spec says not to return an empty response array
            guard responses.count > 0 else { return }
            
            // Encode and send the batched responses
            if let jsonData = try? JSONEncoder().encode(responses)
            {
                do { try self.write(jsonData) }
                catch
                {
                    self.log(
                        .error,
                        "Unable to send batch response: "
                        + "\(error.localizedDescription)"
                    )
                }
                
                self.send(.init(error: .internalError))
            }
            else
            {
                self.log(
                    .error,
                    "Unable to encode batch response: "
                    + "\(responses)"
                )
                self.send(.init(error: .internalError))
            }
        }
    }
    
    // -------------------------------------
    private func handleBatchedResponses(_ batch: [Response])
    {
        /*
         There's nothing special about batched responses. Just dispatch each
         one to its completion handler through the normal mechanism.
         */
        _ = async {
            for response in batch { self.handleResponse(response) }
        }
    }

    // -------------------------------------
    private func handleNotification(_ notification: Notification) {
        _ = async { self.delegate?.handle(notification, for: self) }
    }
    
    // -------------------------------------
    private func handleRequest(_ request: Request)
    {
        _ = async
        {
            self.send(self.delegate?.respond(to: request, for: self)
                ?? Response(for: request, error: .methodNotFound)
            )
        }
    }
    
    // -------------------------------------
    private func dispatch(request: Request) -> Response
    {
        return delegate?.respond(to: request, for: self)
            ?? Response(for: request, error: .methodNotFound)
    }
    
    // -------------------------------------
    private func handleResponse(_ response: Response)
    {
        let result: Result<AnyJSONData, Error>
        if let error = response.error {
            result = .failure(error)
        }
        else if let value = response.result {
            result = .success(value)
        }
        else { unreachable() }
        
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
            _ = async { handler?(result) }
        }
        else
        {
            completionHandlersMutex.withLock
            {
                for handler in completionHandlers.values {
                    _ = async { handler(result) }
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
    
    // MARK:- Sending Batched Requests
    // -------------------------------------
    public final func batch() -> Batch {  return Batch(self) }
    
    // -------------------------------------
    public final func send(_ batch: Batch)
    {
        // JSON-RPC V2.0 spec says not to send empty batch.
        guard batch.requests.count > 0 else
        {
            handleResponse(.init(error: .invalidRequest))
            return
        }
        
        var requests: [GeneralRequest] = []
        requests.reserveCapacity(batch.requests.count)
        
        /*
         Put requests and notifications in the requests batch, and register
         request completion handlers.
         */
        for (request, completion) in batch.requests
        {
            assert(
                (request.id == nil) == (completion == nil),
                "Requests must have both an id and completion handler, and "
                + "notificatons may not have either."
            )
            
            if let requestID = request.id {
                completionHandlers[requestID] = completion
            }
            
            requests.append(request)
        }

        // Encode and send the whole batch
        if let jsonData = try? JSONEncoder().encode(requests)
        {
            _ = async
            {
                do { try self.write(jsonData) }
                catch
                {
                    self.log(
                        .error,
                        "Unable to send batched requests: "
                        + "\(error.localizedDescription)"
                    )
                    self.handleResponse(.init(error: .internalError))
                }
            }
        }
        else
        {
            self.log(.error, "Unable to encode batched requests: \(requests)")
            self.handleResponse(.init(error: .internalError))
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
