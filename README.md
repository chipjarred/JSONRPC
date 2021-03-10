# JSONRPC

JSONRPC is a small Swift package for easily implementing both TCP and Unix domain socket-based JSON-RPC clients and servers.  I'm implementing it for my own use, but putting in the public domain for others to use as well.  It is a work in progress, and at the moment it has some limitations (which I plan to eliminate)

- It only supports JSON-RCP Version 2.0.  Some support for Version 1.0 is in place, but not yet available for use, and there is no code to handle Version 1.1.
- It lacks support for batch requests at the moment.
- For TCP connections you have to specify the address as an IPv4 or IPv6 address.  I've yet to implement DNS look-up to resolve host names.

## How to use it

### Sending requests and notifications

For the simplest use, for which you only need to make requests to a server, and receive reponses to those requests, you simply create a `JSONRPCSession` object, which connects to the server. JSONRPC uses the [NIX package](https://github.com/chipjarred/NIX) to specify IP addresses.

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
    { response in
        if let error = response.error {
            print("Response is an error: \(error.code): \(error.message)")
        }
        else if let result = response.result
        {
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
        }
        else {
            fatalError("Response must always have either result or error")
        }
    }
    
    // Send a notification to the server
    session.notify(method: "set", parameters: ["feelings": "confused"])
}
```

### Handling incoming requests and notifications

Of course, the simple example above doesn't make use of the fact that with JSON-RPC the server can send requests and notifications to the client too.  By default,  `JSONRPCSession` instances ignore incoming notifications, and respond to requests with a "method not found" error.

In order to respond to server requests and notifications, we create a delegate for our session.  The delegate must conform to the `JSONRPCSessionDelegate` protocol, which provides for a number of methods that can be called for various events by the `JSONRPCSession` to which it is attached.  All of these have default implementations, so you only need to implement the ones you need.

The most important of  the delegate methods to implement are
- `respond(to: Request) -> Response?`:
    This method is called whenever the delegate's `JSONRPCSession` receives a request.  Your implementation should inspect the request for its `method` and `parameters` properties, and handle them in whatever way is appropriate for your application; however, JSON-RPC requires that all requests be responded to.  
        - For any request you  handle, construct a response by calling one the delegate's `response(for:result:) -> Response` or `response(for: error:) -> Response` methods and return it.   
        - For requests you don't handle, simply return `nil`.  This tells `JSONRPCSession`  to respond with a "method not found" error. 
- `handle(_ notification: Notification)`:
    This method is called whenever the delegate's `JSONRPCSession` receives a notification.  You handle it much the same way as for requests; however, you do *not* return a `Response`.  Unhandled notifications are simply ignored.

We now modify the previous example to handle incoming requests:

```swift
import NIX
import JSONRPC

class ExampleDelegate: JSONRPCSessionDelegate
{
    required public init() { }
    
    public func respond(to request: Request) -> Response?
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
        delegate: ExampleDelegate())
    else { fatalError("Unable to create JSRONRPCSession") }
    
    // Send a request to the server
    session.request(
        method: "ask",
        parameters: ["Ford, what's the fish doing in my ear?"])
    { response in
        if let error = response.error {
            print("Response is an error: \(error.code): \(error.message)")
        }
        else if let result = response.result
        {
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
        }
        else {
            fatalError("Response must always have either result or error")
        }
    }
    
    // Send a notification to the server
    session.notify(method: "set", parameters: ["feelings": "confused"])
}
```
### Making a server

*Coming soon*
