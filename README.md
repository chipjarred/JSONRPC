# JSONRPC

`JSONRPC` is a small Swift package for easily implementing both TCP and Unix domain socket-based JSON-RPC clients and servers.  I'm implementing it for my own use, but putting in the public domain for others to use as well.  It is a work in progress, and at the moment it has some limitations (which I plan to eliminate)

- It only supports JSON-RCP Version 2.0.  Some support for Version 1.0 is in place, but not yet available for use, and there is no code to handle Version 1.1.
- It lacks support for batch requests at the moment.
- For TCP connections you have to specify the address as an IPv4 or IPv6 address.  I've yet to implement DNS look-up to resolve host names.

## How to use it

### Sending requests and notifications

For the simplest use, for which you only need to make requests to a server, and receive reponses to those requests, you simply create a `JSONRPCSession` object, which connects to the server. `JSONRPC` uses the [`NIX` package](https://github.com/chipjarred/NIX) to specify IP addresses.

Once you have a `JSONRPCSession` instance, you can send a request to the server by calling its `request` method, providing a completion handler to receive the server's response to the request.   Similarly, you can send a notification by calling its `notify` method.

For example:

```swift
import NIX
import JSONRPC

func simpleClientExample()
{
    // Assuming a server is already running on the local machine
    guard let session = JSONRPCSession(
        serverAddress: .init(ip4Address: .loopback, port: 2020))
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

### Handling incoming requests and notifications

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
    guard let session = JSONRPCSession(
        serverAddress: .init(ip4Address: .loopback, port: 2020),
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
### Making a server

`JSONRPC` servers have three parts, two of which you've already met:
- `JSONRPCSession`:  

    This represents a connection from a single client.  The only difference between a server-side session and a client-side session is that server creates a session automatically  in response to receiving a connection from a client, whereas the client explicitly creates one to connect to a server.  Other than that, they are identical.  Once connected, either may send requests and notifications to the other whenever it likes.
- `JSONRPCSessionDelegate`: 

    Whereas clients might not need a session delegate, server-side `JSONRCPSession` instances would be pretty useless without a delgate; however, they work exactly like client-side delegates.  It is in the delegate that you put your custom code for whatever requests and notifications you want your server to handle.
- `JSONRCPServer`:

    This is the thing that passively waits for incoming connections.  As soon as it receives one, it creates a `JSONRPCSession` to handle it, and resumes waiting for more connections.
    
As with the client-side delegate, you create a delegate to handle the requests and notifications your server needs to handle.  However instead of creating a `JSONRPCSession` instance, you create a `JSONRPCServer` instead, passing the delegate's *type* to it.   The `JSONRPCSessionDelegate` `protocol` requires a default initializer (that is, one that does not take any parameters), and this is why.  When the server accepts a connection it creates a separate delegate instance for each `JSONRPCSession` to handle the session for that connection.

Unlike `JSONRPCSession` instances, which connect immediately, `JSONRPCServer`s must be started after creation.  This is to allow the host program to set up anything else it may need before accepting connections.   To start accepting connections, just call the `start()` method.

Let's create  server that handles the requests the client from our previous example sends.  Since our client can respond to `"make_tea"` requests as well, we'll send that request whenever we receive a `"set"` notification indicating that the sender is confused:

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
