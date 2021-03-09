import Foundation
import XCTest
@testable import JSONRPC

// -------------------------------------
class V1_Request_UnitTests: XCTestCase
{
    static var allTests =
    [
        ("test_can_decode_request_with_empty_parameters", test_can_decode_request_with_empty_parameters),
        ("test_can_decode_request_with_one_parameter", test_can_decode_request_with_one_parameter),
        ("test_can_decode_request_with_two_parameters", test_can_decode_request_with_two_parameters),
        ("test_can_encode_request_with_no_parameters", test_can_encode_request_with_no_parameters),
        ("test_can_encode_request_with_empty_parameters", test_can_encode_request_with_empty_parameters),
        ("test_can_encode_request_with_one_parameter", test_can_encode_request_with_one_parameter),
        ("test_can_encode_request_with_two_parameters", test_can_encode_request_with_two_parameters),
    ]
    // MARK:- Decoding
    // -------------------------------------
    func test_can_decode_request_with_empty_parameters()
    {
        let json =
            #"{ "method": "echo", "params": [], "id": 1}"#

        let request: Request
        do
        {
            request = try JSONDecoder()
                .decode(Request.self, from: json.data(using: .utf8)!)
        }
        catch
        {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
            return
        }
        
        XCTAssertEqual(request.jsonrpc, nil)
        XCTAssertEqual(request.id, 1)
        XCTAssertEqual(request.method, "echo")
        switch request.params
        {
            case .named(_):
                XCTFail("JSONRCP v1 message has named parameters")
            case .positional(let p):
                XCTAssertEqual(p.count, 0)
            case .none:
                XCTFail("Parameters are missing")
        }
    }

    // -------------------------------------
    func test_can_decode_request_with_one_parameter()
    {
        let json =
            #"{ "method": "echo", "params": ["Hello JSON-RPC"], "id": 1}"#

        let request: Request
        do
        {
            request = try JSONDecoder()
                .decode(Request.self, from: json.data(using: .utf8)!)
        }
        catch
        {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
            return
        }
        
        XCTAssertEqual(request.jsonrpc, nil)
        XCTAssertEqual(request.id, 1)
        XCTAssertEqual(request.method, "echo")
        switch request.params
        {
            case .named(_):
                XCTFail("JSONRCP v1 message has named parameters")
            case .positional(let p):
                XCTAssertEqual(p.count, 1)
                guard let param = p.first as? String else
                {
                    XCTFail("Parameter is not a string")
                    break
                }
                XCTAssertEqual(param, "Hello JSON-RPC")
            case .none:
                XCTFail("Parameters are missing")
        }
    }

    // -------------------------------------
    func test_can_decode_request_with_two_parameters()
    {
        let json =
            #"{ "method": "echo", "params": ["Hello JSON-RPC", 5], "id": 1}"#

        let request: Request
        do
        {
            request = try JSONDecoder()
                .decode(Request.self, from: json.data(using: .utf8)!)
        }
        catch
        {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
            return
        }
        
        XCTAssertEqual(request.jsonrpc, nil)
        XCTAssertEqual(request.id, 1)
        XCTAssertEqual(request.method, "echo")
        switch request.params
        {
            case .named(_):
                XCTFail("JSONRCP v1 message has named parameters")
            case .positional(let p):
                XCTAssertEqual(p.count, 2)
                guard let param1 = p[0] as? String else
                {
                    XCTFail("Parameter is not a string")
                    break
                }
                XCTAssertEqual(param1, "Hello JSON-RPC")
                guard let param2 = p[1] as? Int else
                {
                    XCTFail("Parameter is not an Int")
                    break
                }
                XCTAssertEqual(param2, 5)
            case .none:
                XCTFail("Parameters are missing")
        }
    }

    // MARK:- Encoding
    // -------------------------------------
    func test_can_encode_request_with_no_parameters()
    {
        let expected =
            #"{"id":1,"method":"echo","params":[]}"#
        
        let request = Request(version: .v1, id: 1, method: "echo")
        
        let jsonData: Data
        do { jsonData = try JSONEncoder().encode(request) }
        catch
        {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
            return
        }
        
        let json = String(data: jsonData, encoding: .utf8)
        XCTAssertNotNil(json)
        XCTAssertEqual(json!, expected)
    }

    // -------------------------------------
    func test_can_encode_request_with_empty_parameters()
    {
        let expected =
            #"{"id":1,"method":"echo","params":[]}"#
        
        let request = Request(version: .v1, id: 1, method: "echo", params: [])
        
        let jsonData: Data
        do { jsonData = try JSONEncoder().encode(request) }
        catch
        {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
            return
        }
        
        let json = String(data: jsonData, encoding: .utf8)
        XCTAssertNotNil(json)
        XCTAssertEqual(json!, expected)
    }

    // -------------------------------------
    func test_can_encode_request_with_one_parameter()
    {
        let expected =
            #"{"id":1,"method":"echo","params":["Hello JSON-RPC"]}"#
        
        let request = Request(
            version: .v1,
            id: 1,
            method: "echo",
            params: ["Hello JSON-RPC"]
        )
        
        let jsonData: Data
        do { jsonData = try JSONEncoder().encode(request) }
        catch
        {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
            return
        }
        
        let json = String(data: jsonData, encoding: .utf8)
        XCTAssertNotNil(json)
        XCTAssertEqual(json!, expected)
    }

    // -------------------------------------
    func test_can_encode_request_with_two_parameters()
    {
        let expected =
            #"{"id":1,"method":"echo","params":["Hello JSON-RPC",5]}"#
        
        let request = Request(
            version: .v1, 
            id: 1,
            method: "echo",
            params: ["Hello JSON-RPC", 5]
        )
        
        let jsonData: Data
        do { jsonData = try JSONEncoder().encode(request) }
        catch
        {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
            return
        }
        
        let json = String(data: jsonData, encoding: .utf8)
        XCTAssertNotNil(json)
        XCTAssertEqual(json!, expected)
    }
}
