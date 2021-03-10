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
    
    private var sessionsMutex = NIX.SpinLock()
    private var currentSessions = Set<JSONRPCSession>()
    
    private var quittingMutex = NIX.SpinLock()
    private var _quitting = false
    private var quitting: Bool
    {
        get { quittingMutex.withLock { _quitting } }
        set { quittingMutex.withLock { _quitting = newValue } }
    }
    
    private static let dispatchQueue =
        DispatchQueue(label: "JSONRPCServer-\(UUID())", attributes: .concurrent)
    
    private let delegateType: JSONRPCSessionDelegate.Type
    
    // -------------------------------------
    public init?<Delegate: JSONRPCSessionDelegate>(
        boundTo address: SocketAddress,
        maximumConnections: Int,
        typeOfDelegate: Delegate.Type)
    {
        self.delegateType = typeOfDelegate
        let domain: NIX.SocketDomain
        let protocolFamily: NIX.ProtocolFamily
        switch address.family
        {
            case .inet4: (domain, protocolFamily) = (.inet4, .tcp)
            case .inet6: (domain, protocolFamily) = (.inet6, .tcp)
            case .unix : (domain, protocolFamily) = (.local, .ip)
        }
        
        self.address = address

        switch NIX.socket(domain, .stream, protocolFamily)
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
    private func cleanUp(terminateSessions: Bool = true)
    {
        
        _ = NIX.close(socket)
        log(.info, "Server stopped accepting new connections.")

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
        
        if terminateSessions
        {
            log(.info, "Server terminating all connections.")
            sessionsMutex.withLock { currentSessions.removeAll() }
        }
    }
    
    // -------------------------------------
    public final func start() {
        Self.dispatchQueue.async { self.acceptLoop() }
    }
    
    // -------------------------------------
    private func acceptLoop()
    {
        log(.info, "Server started. Listening to \(address)")
        
        while !quitting
        {
            var peerAddress = SocketAddress()
            switch NIX.accept(socket, &peerAddress)
            {
                case .success(let peerSocket):
                    let clientSession = JSONRPCSession(
                        from: self,
                        forPeerSocket: peerSocket,
                        at: peerAddress,
                        delegate: delegateType.init()
                    )
                    addSession(clientSession)
                    Self.dispatchQueue.async { clientSession.start() }
                    
                case .failure(let error):
                    log(.error, "Unable to accept connection: \(error)")
            }
        }
    }
    
    // -------------------------------------
    public enum SessionTerminationTime
    {
        case immediately
        case afterCurrentSessionsFinish
    }
    
    // -------------------------------------
    public final func terminate(_ when: SessionTerminationTime)
    {
        log(.info, "Server termination requested.")
        
        quitting = true
        switch when
        {
            case .immediately:
                log(.info, "Server shutting down immediately.")
                cleanUp()
                
            case .afterCurrentSessionsFinish:
                cleanUp(terminateSessions: false)
                
                log(.info, "Waiting for current sessions to finish.")
                let sleepSemaphore = DispatchSemaphore(value: 0)
                defer { sleepSemaphore.signal() }
                while sessionCount > 0
                {
                    _ = sleepSemaphore.wait(
                        timeout: .now() + .milliseconds(100)
                    )
                }
        }
    }
    
    // -------------------------------------
    internal func sessionEnded(for peerSession: JSONRPCSession) {
        removeSession(peerSession)
    }
    
    // -------------------------------------
    private func addSession(_ session: JSONRPCSession) {
        _ = sessionsMutex.withLock { currentSessions.insert(session) }
    }
    
    // -------------------------------------
    private func removeSession(_ session: JSONRPCSession) {
        _ = sessionsMutex.withLock { currentSessions.remove(session) }
    }
    
    // -------------------------------------
    private var sessionCount: Int {
        sessionsMutex.withLock { currentSessions.count }
    }
}
