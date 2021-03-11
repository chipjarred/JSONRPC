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

class BatchExampleClientDelegate: JSONRPCSessionDelegate
{
    required public init() { }
    
    public func respond(
        to request: Request,
        for session: JSONRPCSession) -> Response?
    {
        if request.method == "make_tea"
        {
            return response(
                for: request,
                result:["something that is almost, but not entirely unlike tea"]
            )
        }
        
        return nil
    }
}

func batchRequestExample()
{
    // Assuming a server is already running on the local machine
    guard let session = JSONRPCSession(
        serverAddress: .init(ip4Address: .loopback, port: 2020),
        delegate: ExampleClientDelegate())
    else { fatalError("Unable to create JSRONRPCSession") }
    
    // Create a batch of requests
    var batch = session.batch()
    batch.request(
        method: "ask",
        parameters: ["Ford, what's the fish doing in my ear?"])
    {
        switch $0
        {
            case .success(let result):
                switch result
                {
                    case .string(let answer):
                        print("Response is \"\(answer)\"")
                    case .integer(let answer):
                        if answer == 42
                        {
                            print("Response is \"\(answer)\"")
                            break
                        }
                        fallthrough
                    default:
                        print("DON'T PANIC! Unexpected type of response: \(result)")
                }
                
            case .failure(let error):
                print("Response is an error: \(error.code): \(error.message)")
        }
    }
    batch.request(
        method: "ask",
        parameters: ["Where are we?"])
    {
        switch $0
        {
            case .success(let result):
                switch result
                {
                    case .string(let answer):
                        if answer == "safe" {
                            session.notify(
                                method: "say",
                                parameters: ["Oh, good."]
                            )
                        }
                    case .integer(let answer):
                        if answer == 42
                        {
                            print("Response is \"\(answer)\"")
                            break
                        }
                        fallthrough
                    default:
                        print("DON'T PANIC! Unexpected type of response: \(result)")
                }
                
            case .failure(let error):
                print("Response is an error: \(error.code): \(error.message)")
        }
    }
    batch.notify(method: "set", parameters: ["feelings": "confused"])
    
    session.send(batch)
}
