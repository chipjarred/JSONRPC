import Foundation
import XCTest
@testable import JSONRPC
import NIX
import HostOS

// -------------------------------------
class Client_Server_UnitTests: XCTestCase
{
    static var allTests =
    [
        ("test_client_can_connect_to_inet4_server", test_client_can_connect_to_inet4_server),
    ]
    
    // -------------------------------------
    func test_client_can_connect_to_inet4_server()
    {
        let serverAddress = SocketAddress(
            ip4Address: .loopback,
            port: 2000 + #line
        )
        
        // -------------------------------------
        final class ServerSessionDelegate: JSONRPCSessionDelegate
        {
            func respond(
                to request: Request,
                for _ :JSONRPCSession) -> Response?
            {
                if request.method == "foo" {
                    return response(for: request, result: "bar")
                }
                return nil
            }
        }
        
        guard let server = JSONRPCServer(
            boundTo: serverAddress,
            maximumConnections: 1,
            typeOfDelegate: ServerSessionDelegate.self)
        else
        {
            XCTFail("Unable to create server")
            return
        }
        defer { server.terminate(.immediately) }
        
        server.start()
        
        guard let client = JSONRPCSession(serverAddress: serverAddress) else
        {
            XCTFail("Unable to create client-side session")
            return
        }
        
        let sem = DispatchSemaphore(value: 0)
        
        client.request(method: "foo")
        {
            switch $0
            {
                case.success(let result):
                    switch result
                    {
                        case .string(let s): XCTAssertEqual(s, "bar")
                        default: XCTFail("Result is wrong type: \(result)")
                    }
                case .failure(let error):
                    XCTFail("Got Error response: \(error)")

            }
            sem.signal()
        }
        
        sem.wait(); sem.signal()
    }
    
    // -------------------------------------
    func test_client_can_connect_to_inet6_server()
    {
        let serverAddress = SocketAddress(
            ip6Address: .loopback,
            port: 2000 + #line
        )
        
        // -------------------------------------
        final class ServerSessionDelegate: JSONRPCSessionDelegate
        {
            func respond(
                to request: Request,
                for _ :JSONRPCSession) -> Response?
            {
                if request.method == "foo" {
                    return response(for: request, result: "bar")
                }
                return nil
            }
        }
        
        guard let server = JSONRPCServer(
            boundTo: serverAddress,
            maximumConnections: 1,
            typeOfDelegate: ServerSessionDelegate.self)
        else
        {
            XCTFail("Unable to create server")
            return
        }
        defer { server.terminate(.immediately) }
        
        server.start()
        
        guard let client = JSONRPCSession(serverAddress: serverAddress) else
        {
            XCTFail("Unable to create client-side session")
            return
        }
        
        let sem = DispatchSemaphore(value: 0)
        
        client.request(method: "foo")
        {
            switch $0
            {
                case.success(let result):
                    switch result
                    {
                        case .string(let s): XCTAssertEqual(s, "bar")
                        default: XCTFail("Result is wrong type: \(result)")
                    }
                case .failure(let error):
                    XCTFail("Got Error response: \(error)")

            }
            sem.signal()
        }
        
        sem.wait(); sem.signal()
    }
    
    // -------------------------------------
    func test_client_can_connect_to_Unix_domain_server()
    {
        let serverAddress = SocketAddress(
            unixPath: UnixSocketPath("\(#function)-server")!
        )
        
        // -------------------------------------
        final class ServerSessionDelegate: JSONRPCSessionDelegate
        {
            func respond(
                to request: Request,
                for _ :JSONRPCSession) -> Response?
            {
                if request.method == "foo" {
                    return response(for: request, result: "bar")
                }
                return nil
            }
        }
        
        guard let server = JSONRPCServer(
            boundTo: serverAddress,
            maximumConnections: 1,
            typeOfDelegate: ServerSessionDelegate.self)
        else
        {
            XCTFail("Unable to create server")
            return
        }
        defer { server.terminate(.immediately) }
        
        server.start()
        
        guard let client = JSONRPCSession(serverAddress: serverAddress) else
        {
            XCTFail("Unable to create client-side session")
            return
        }
        
        let sem = DispatchSemaphore(value: 0)
        
        client.request(method: "foo")
        {
            switch $0
            {
                case.success(let result):
                    switch result
                    {
                        case .string(let s): XCTAssertEqual(s, "bar")
                        default: XCTFail("Result is wrong type: \(result)")
                    }
                case .failure(let error):
                    XCTFail("Got Error response: \(error)")

            }
            sem.signal()
        }
        
        sem.wait(); sem.signal()
    }
}
