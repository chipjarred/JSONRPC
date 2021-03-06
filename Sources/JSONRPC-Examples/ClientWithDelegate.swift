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

import JSONRPC

class ExampleClientDelegate: JSONRPCSessionDelegate
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

func clientWithDelegateExample()
{
    // Assuming a server is already running on the local machine
    guard let session = JSONRPCSession.connect(
            to: "localhost",
            port: 2020,
            delegate: ExampleClientDelegate())
    else { fatalError("Unable to create JSRONRPCSession") }
    
    // Send a request to the server
    session.request(
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
    
    // Send a notification to the server
    session.notify(method: "set", parameters: ["feelings": "confused"])
}
