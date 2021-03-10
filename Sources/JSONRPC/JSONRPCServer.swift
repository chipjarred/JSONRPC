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
import NIX
import HostOS

// -------------------------------------
public class JSONRPCServer: JSONRPCLogger
{
    private let socket: SocketIODescriptor
    private let address: SocketAddress
    
    private var peersMutex = NIX.SpinLock()
    private var peers: [SocketIODescriptor] = []
    
    private var quittingMutex = NIX.SpinLock()
    private var _quitting = false
    private var quitting: Bool
    {
        get { quittingMutex.withLock { _quitting } }
        set { quittingMutex.withLock { _quitting = newValue } }
    }
    
    private static let dispatchQueue =
        DispatchQueue(label: "JSONRPCServer-\(UUID())", attributes: .concurrent)
    
    // -------------------------------------
    public init?(boundTo address: SocketAddress, maximumConnections: Int)
    {
        let domain: NIX.SocketDomain
        switch address.family
        {
            case .inet4: domain = .inet4
            case .inet6: domain = .inet6
            case .unix: domain = .local
        }
        
        self.address = address

        switch NIX.socket(domain, .stream, .tcp)
        {
            case .success(let s): self.socket = s
            case .failure(let error):
                Self.log(
                    .error,
                    "Unable to create server listener socket: \(error)"
                )
                return nil
        }
        
        if let error = NIX.bind(self.socket, address)
        {
            Self.log(.error, "Unable to bind server listener socket: \(error)")
            cleanUp()
            return nil
        }
        
        if let error = NIX.listen(self.socket, maximumConnections)
        {
            Self.log(.error, "Unable to listen on socket: \(error)")
            cleanUp()
            return nil
        }
    }
    
    // -------------------------------------
    deinit { cleanUp() }
    
    // -------------------------------------
    private func cleanUp(closePeerSockets: Bool = true)
    {
        _ = NIX.close(socket)
        if let unixPath = address.asUnix?.path.rawValue
        {
            if let error = NIX.unlink(unixPath), error.errno != HostOS.ENOENT
            {
                Self.log(
                    .error,
                    "Unable to remove Unix domain socket path, \"unixPath\": "
                    + "\(error)"
                )
            }
        }
        
        if closePeerSockets
        {
            peersMutex.withLock
            {
                for peer in peers { _ = NIX.close(peer) }
                peers.removeAll()
            }
        }
    }
    
    // -------------------------------------
    public final func start()
    {
        log(.info, "Server started. Listening to \(address)")
        
        Self.dispatchQueue.async
        { [self] in
            while !quitting
            {
                var peerAddress = SocketAddress()
                switch NIX.accept(socket, &peerAddress)
                {
                    case .success(let peerSocket):
                        Self.dispatchQueue.async
                        {
                            do { try clientLoop(peerSocket, peerAddress) }
                            catch
                            {
                                log(
                                    .warn,
                                    "client loop threw exception: "
                                    + "\(error.localizedDescription)"
                                )
                            }
                        }
                        
                    case .failure(let error):
                        log(.error, "Unable to accept connection: \(error)")
                }
            }
        }
    }
    
    // -------------------------------------
    public enum TerminationSchedule
    {
        case immediately
        case afterCurrentSessionsFinish
    }
    
    // -------------------------------------
    public final func terminate(_ when: TerminationSchedule)
    {
        quitting = true
        switch when
        {
            case .immediately:
                cleanUp()
                
            case .afterCurrentSessionsFinish:
                cleanUp(closePeerSockets: false)
                let sleepSemaphore = DispatchSemaphore(value: 0)
                defer { sleepSemaphore.signal() }
                while peersMutex.withLock( { peers.count > 0 } )
                {
                    _ = sleepSemaphore.wait(
                        timeout: .now() + .milliseconds(100)
                    )
                }
        }
    }
    
    // -------------------------------------
    internal final func clientLoop(
        _ peerSocket: SocketIODescriptor,
        _ peerAddress: SocketAddress) throws
    {
        peers.append(peerSocket)
        self.log(.info, "Started session with \(peerAddress).")
        
        defer
        {
            removePeer(peerSocket)
            
            if let error = NIX.close(peerSocket)
            {
                log(
                    .warn,
                    "\(Self.self): Failed to close peer socket: \(error)"
                )
            }
            
            self.log(.info, "Ended session with \(peerAddress).")
        }
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        var lineReader = SocketLineReader(logger: self)
        
        while true
        {
            guard let line = lineReader.readLine(from: peerSocket)
            else { break }
            
            log(.info, "\(Self.self): Received request: \"\(line)\"")
            
            guard let response = try self.response(for: line, encoder, decoder)
            else { continue }
            
            let bytesWritten: Int
            switch NIX.write(peerSocket, response)
            {
                case .success(let b): bytesWritten = b
                case .failure(let error):
                    log(
                        .error,
                        "\(Self.self): Unable to write response to peer socket:"
                        + " \(error)"
                    )
                    return
            }
            
            if bytesWritten != response.count
            {
                log(
                    .error,
                    "\(Self.self): Failed to write all bytes of response to "
                    + "peer socket: \(bytesWritten) of \(response.count) bytes "
                    + "written"
                )
                return
            }
            
            log(.info, "\(Self.self): Sent response: \"\(response)\"")
        }
    }
    
    // -------------------------------------
    private func response(
        for data: Data,
        _ encoder: JSONEncoder,
        _ decoder: JSONDecoder) throws -> Data?
    {
        if let request = try? decoder.decode(GeneralRequest.self, from: data)
        {
            if request.id == nil
            {
                processNotification(Notification(from: request))
                return nil
            }
            else
            {
                let response = processRequest(Request(from: request))
                guard let responseData = try? encoder.encode(response) else
                {
                    log(
                        .warn,
                        "Unable to encode response for request: \(response)"
                    )
                    return nil
                }
                return responseData
            }
        }
        else if let response = try? decoder.decode(Response.self, from: data)
        {
            log(.warn, "Got response from client: \(response)")
            return nil
        }
        else
        {
            // TODO: Search data for an id, so that a parse error can be sent.
            throw ErrorCode.parseError
        }
    }
    
    // -------------------------------------
    private func processNotification(_ notificiation: Notification)
    {
    }
    
    // -------------------------------------
    private func processRequest(_ request: Request) -> Response
    {
        return Response(for: request, error: .internalError)
    }

    // -------------------------------------
    private func removePeer(_ peerSocket: SocketIODescriptor)
    {
        peersMutex.withLock
        {
            if let i = peers.firstIndex(
                where: { $0.descriptor == peerSocket.descriptor })
            {
                peers.remove(at: i)
            }
        }
    }
}
