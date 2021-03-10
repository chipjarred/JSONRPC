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

// -------------------------------------
public class JSONRPCSession: JSONRPCResponder, JSONRPCLogger
{
    public unowned var server: JSONRPCServer
    private let peerAddress: SocketAddress
    private let peerSocket: SocketIODescriptor
    
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
    public func write(_ data: Data) throws
    {
        let bytesWritten: Int
        switch NIX.write(peerSocket, data)
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
    public func handleNotification(_ notification: Notification) {
        unimplemented()
    }
    
    // -------------------------------------
    public func handleRequest(_ request: Request) throws -> Response {
        unimplemented()
    }
    
    // -------------------------------------
    public func handleResponse(_ response: Response) {
        unimplemented()
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
