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

import NIX
import JSONRPC

class ExampleServerDelegate: JSONRPCSessionDelegate
{
    required public init() { }
    
    public func respond(
        to request: Request,
        for session: JSONRPCSession) -> Response?
    {
        if request.method == "ask" {
            return response(for: request, result: "Translating.")
        }
        
        return nil
    }
    
    public func handle(
        _ notification: Notification,
        for session: JSONRPCSession)
    {
        if notification.method == "set"
        {
            switch notification.params
            {
                case .named(let params):
                    if params["feelings"] as? String == "confused" {
                        print("awww... Arthur is confused")
                    }
                default: return
            }
            
            session.request(method: "make_tea")
            { response in
                switch response
                {
                    case .success(let result):
                        switch result
                        {
                            case .array(let result):
                                if let cupContents = result.first as? String {
                                    print("Nutri-matic made us \(cupContents)")
                                }
                                else { fallthrough }
                                
                            default:
                                print("Nutri-matic has gone haywire again.")
                        }
                    case .failure(_):
                        print("OK, Panic! Arthur could not make tea.")
                }
            }
        }
    }
}

func makeAndStartExampleServer() -> JSONRPCServer
{
    guard let server = JSONRPCServer(
            boundTo: SocketAddress(ip4Address: .any, port: 2020),
            maximumConnections: 42,
            typeOfDelegate: ExampleServerDelegate.self)
    else { fatalError("Unable to create server") }
    
    server.start()
    return server
}
