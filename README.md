# JSONRPC

`JSONRPC` is a small Swift package for easily implementing both TCP and Unix domain socket-based JSON-RPC clients and servers.  I'm implementing it for my own use, but putting it in the public domain for others to use as well.  It is a work in progress, and at the moment it has some limitations (which I plan to eliminate):

- It only supports JSON-RCP Version 2.0.  There is code to support Version 1.0 in the various Request/Response types, but not yet available for use to actually use in sessions, and there is no code to handle Version 1.1 specifically.
- For TCP connections you have to specify the address as an IPv4 or IPv6 address and port.  I've yet to implement DNS look-up to resolve host names.
- It doesn't currently support any encryption layer.  Until it does, don't use it to send any confidential information.

In addition there is an edge case I am not sure how to handle from reading the JSON-RPC Version 2.0  specification.  There is a possibility of a response containing a `null` `id`.  For example, if a server receives invalid batch request,  it is supposed to reply with one "invalid request" error for the whole batch and that response has a `null`, `id`.   The same thing can happen even on a single request that is invalid JSON, which causes a parse error.  Making the response is the easy part.  The difficult part is what to do as the original requester receiving such a response.  This would not be a problem if the the protocol were supposed to be used synchronously.  The sender would just block until it got a respnose, and since no more requests had been sent, it would know that the error applied to the most recent request (or batch of requests).   But who wants their code to block?   Multiple requests, and even multiple batches may have been sent before the error arrives, and without an `id` there's no way of knowing which request(s) it applies to.  The way I currently handle this situation is to broadcast responses with a `null`  `id` to all handlers for requests that are still waiting on responses, but I don't remove them as having been serviced to allow pending handlers for valid requests to subsequently receive their correct responses.  I'm not sure that's the right approach, but neither is directing the response to the handler for the most recently sent request, nor just ignoring the response.  Giving up and abruptly closing the connection doesn't seem approprate either.  I'd like to handle it in an appropriate way.   If anyone reading knows the correct way to handle this situation, please let me know.

## How to Use `JSONRPC`

### Sending Requests and Notifications

For the simplest use, for which you only need to make requests to a server, and receive reponses to those requests, you simply create a `JSONRPCSession` object, which connects to the server. `JSONRPC` uses the [`NIX` package](https://github.com/chipjarred/NIX) to specify IP addresses.

Once you have a `JSONRPCSession` instance, you can send a request to the server by calling its `request` method, providing a completion handler to receive the server's response to the request.   Similarly, you can send a notification by calling its `notify` method.

For example:

```swift
import NIX
import JSONRPC

func simpleClientExample()
{
    // Assuming a server is already running on the local machine
    guard let session = JSONRPCSession.connect(to: "localhost", port: 2020)
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
```

### Handling Incoming Requests and Notifications

Of course, the simple example above doesn't make use of the fact that with the JSON-RPC protocol the server can send requests and notifications to the client too.  By default,  `JSONRPCSession` instances ignore incoming notifications, and respond to requests with a "method not found" error.

In order to respond to server requests and notifications, we create a delegate for our session.  The delegate must conform to the `JSONRPCSessionDelegate` `protocol`, which provides for a number of methods that can be called for various events by the `JSONRPCSession` to which it is attached.  All of these have default implementations, so you only need to implement the ones you need.

The most important of  the delegate methods to implement are
- `respond(to: Request, for: JSONRPCSession) -> Response?`:

    This method is called whenever the delegate's `JSONRPCSession` receives a request.  Your implementation should inspect the request for its `method` and `parameters` properties, and handle them in whatever way is appropriate for your application; however, JSON-RPC requires that all requests be responded to.  
    
    - For any request you  handle, construct a response by calling one the delegate's `response(for:result:) -> Response` or `response(for: error:) -> Response` methods and return it.   
    - For requests you don't handle, simply return `nil`.  This tells `JSONRPCSession`  to respond with a "method not found" error. 
            
- `handle(_ notification: Notification, for: JSONRPCSession)`:

    This method is called whenever the delegate's `JSONRPCSession` receives a notification.  You handle it much the same way as for requests; however, you do *not* return a `Response`.  Unhandled notifications are simply ignored.

We now modify the previous example to handle incoming requests:

```swift
import NIX
import JSONRPC

import NIX
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
```
### Batch Requests

The JSON-RPC protocol allows sending batched requests.  To do this, the requester calls its session's `batch()` method to obtain a `Batch`.  It then makes calls to various request and notification methds on that `Batch` instead directly to the session.  The `Batch` accumulates them, but does not the send them.  When you're ready to send the batch, you call the session's `send(_:Batch)` method.  The server (or client, if the server sent the batch), responds with a batch of responses, but that is handled within `JSONRPCSession`.   Your code specifies completion handlers as normal when it calls methods on the request batch, and then the session dispatches the batched responses to your handlers. 

Let's modify our last client example to send a batch.  It will batch two requests and one notification:

```swift
import NIX
import JSONRPC

func batchRequestExample()
{
    // Assuming a server is already running on the local machine
    guard let session = JSONRPCSession.connect(
            to: "localhost",
            port: 2020,
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
```
### Making a Server

`JSONRPC` servers have three parts, two of which you've already met:
- `JSONRPCSession`:  

    This represents a connection from a single client.  The only difference between a server-side session and a client-side session is that server creates a session automatically  in response to receiving a connection from a client, whereas the client explicitly creates one to connect to a server.  Other than that, they are identical.  Once connected, either may send requests and notifications to the other whenever it likes.
- `JSONRPCSessionDelegate`: 

    Whereas clients might not need a session delegate, server-side `JSONRCPSession` instances would be pretty useless without a delgate; however, they work exactly like client-side delegates.  It is in the delegate that you put your custom code for whatever requests and notifications you want your server to handle.
- `JSONRCPServer`:

    This is the thing that passively waits for incoming connections.  As soon as it receives one, it creates a `JSONRPCSession` to handle it, and resumes waiting for more connections.
    
As with the client-side delegate, you create a delegate to handle the requests and notifications your server needs to handle.  However instead of creating a `JSONRPCSession` instance, you create a `JSONRPCServer` instead, passing the delegate's *type* to it.   The `JSONRPCSessionDelegate` `protocol` requires a default initializer (that is, one that does not take any parameters), and this is why.  When the server accepts a connection it creates a separate delegate instance for each `JSONRPCSession` to handle the session for that connection.

Unlike `JSONRPCSession` instances, which connect immediately, `JSONRPCServer`s must be started after creation.  This is to allow the host program to set up anything else it may need before accepting connections.   To start accepting connections, just call the `start()` method.

Let's create a server that handles the requests the client from our previous example sends.  Since our client can respond to `"make_tea"` requests as well, we'll send that request whenever we receive a `"set"` notification indicating that the sender is confused:

```swift
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
```
