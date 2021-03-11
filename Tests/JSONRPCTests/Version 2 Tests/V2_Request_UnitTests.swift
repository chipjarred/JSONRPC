import Foundation
import XCTest
@testable import JSONRPC

// -------------------------------------
class V2_Request_UnitTests: XCTestCase
{
    static var allTests =
    [
        ("test_can_decode_request_with_no_parameters", test_can_decode_request_with_no_parameters),
        ("test_can_decode_request_with_empty_positional_parameters", test_can_decode_request_with_empty_positional_parameters),
        ("test_can_decode_request_with_one_positional_parameter", test_can_decode_request_with_one_positional_parameter),
        ("test_can_decode_request_with_two_positional_parameters", test_can_decode_request_with_two_positional_parameters),
        ("test_can_decode_request_with_empty_named_parameters", test_can_decode_request_with_empty_named_parameters),
        ("test_can_decode_request_with_one_named_parameter", test_can_decode_request_with_one_named_parameter),
        ("test_can_decode_request_with_two_named_parameters", test_can_decode_request_with_two_named_parameters),
        ("test_can_encode_request_with_no_parameters", test_can_encode_request_with_no_parameters),
        ("test_can_encode_request_with_empty_positional_parameters", test_can_encode_request_with_empty_positional_parameters),
        ("test_can_encode_request_with_one_positional_parameter", test_can_encode_request_with_one_positional_parameter),
        ("test_can_encode_request_with_two_positional_parameters", test_can_encode_request_with_two_positional_parameters),
        ("test_can_encode_request_with_empty_named_parameters", test_can_encode_request_with_empty_named_parameters),
        ("test_can_encode_request_with_one_named_parameter", test_can_encode_request_with_one_named_parameter),
        ("test_can_encode_request_with_two_named_parameters", test_can_encode_request_with_two_named_parameters),
        ("test_can_decode_batch_requests", test_can_decode_batch_requests),
    ]
    
    // MARK:- Version 2 Decoding
    // -------------------------------------
    func test_can_decode_request_with_no_parameters()
    {
        let json =
            #"{"jsonrpc":"2.0", "method": "echo", "id": 1}"#

        let request: GeneralRequest
        do
        {
            request = try JSONDecoder()
                .decode(GeneralRequest.self, from: json.data(using: .utf8)!)
        }
        catch
        {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
            return
        }
        
        XCTAssertEqual(request.jsonrpc, "2.0")
        XCTAssertEqual(request.id, 1)
        XCTAssertEqual(request.method, "echo")
        switch request.params
        {
            case .none:
                break
            default:
                XCTFail(
                    "Got parameters when expecting none: "
                    + "\(String(describing: request.params))"
                )
        }
    }
    
    // -------------------------------------
    func test_can_decode_request_with_empty_positional_parameters()
    {
        let json =
            #"{"jsonrpc":"2.0", "method": "echo", "#
            + #""params": [], "id": 1}"#

        let request: GeneralRequest
        do
        {
            request = try JSONDecoder()
                .decode(GeneralRequest.self, from: json.data(using: .utf8)!)
        }
        catch
        {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
            return
        }
        
        XCTAssertEqual(request.jsonrpc, "2.0")
        XCTAssertEqual(request.id, 1)
        XCTAssertEqual(request.method, "echo")
        switch request.params
        {
            case .named(_):
                XCTFail(
                    "JSONRCP message has named parameters.  Should be "
                    + "positional"
                )
            case .positional(let p):
                XCTAssertEqual(p.count, 0)
            case .none:
                XCTFail("Parameters are missing")
        }
    }

    // -------------------------------------
    func test_can_decode_request_with_one_positional_parameter()
    {
        let json =
            #"{"jsonrpc":"2.0", "method": "echo", "#
            + #""params": ["Hello JSON-RPC"], "id": 1}"#

        let request: GeneralRequest
        do
        {
            request = try JSONDecoder()
                .decode(GeneralRequest.self, from: json.data(using: .utf8)!)
        }
        catch
        {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
            return
        }
        
        XCTAssertEqual(request.jsonrpc, "2.0")
        XCTAssertEqual(request.id, 1)
        XCTAssertEqual(request.method, "echo")
        switch request.params
        {
            case .named(_):
                XCTFail(
                    "JSONRCP message has named parameters.  Should be "
                    + "positional"
                )
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
    func test_can_decode_request_with_two_positional_parameters()
    {
        let json =
            #"{"jsonrpc":"2.0", "method": "echo", "#
            + #""params": ["Hello JSON-RPC", 5], "id": 1}"#

        let request: GeneralRequest
        do
        {
            request = try JSONDecoder()
                .decode(GeneralRequest.self, from: json.data(using: .utf8)!)
        }
        catch
        {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
            return
        }
        
        XCTAssertEqual(request.jsonrpc, "2.0")
        XCTAssertEqual(request.id, 1)
        XCTAssertEqual(request.method, "echo")
        switch request.params
        {
            case .named(_):
                XCTFail(
                    "JSONRCP message has named parameters.  Should be "
                    + "positional"
                )
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
    
    // -------------------------------------
    func test_can_decode_request_with_empty_named_parameters()
    {
        let json =
            #"{"jsonrpc":"2.0", "method": "echo", "#
            + #""params": {}, "id": 1}"#

        let request: GeneralRequest
        do
        {
            request = try JSONDecoder()
                .decode(GeneralRequest.self, from: json.data(using: .utf8)!)
        }
        catch
        {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
            return
        }
        
        XCTAssertEqual(request.jsonrpc, "2.0")
        XCTAssertEqual(request.id, 1)
        XCTAssertEqual(request.method, "echo")
        switch request.params
        {
            case .named(let p):
                XCTAssertEqual(p.count, 0)
            case .positional(_):
                XCTFail(
                    "JSONRCP message has positional parameters.  Should be "
                    + "named"
                )
            case .none:
                XCTFail("Parameters are missing")
        }
    }
    
    // -------------------------------------
    func test_can_decode_request_with_one_named_parameter()
    {
        let json =
            #"{"jsonrpc":"2.0", "method": "echo", "#
            + #""params": {"message":"Hello JSON-RPC"}, "id": 1}"#

        let request: GeneralRequest
        do
        {
            request = try JSONDecoder()
                .decode(GeneralRequest.self, from: json.data(using: .utf8)!)
        }
        catch
        {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
            return
        }
        
        XCTAssertEqual(request.jsonrpc, "2.0")
        XCTAssertEqual(request.id, 1)
        XCTAssertEqual(request.method, "echo")
        switch request.params
        {
            case .named(let p):
                XCTAssertEqual(p.count, 1)
                let message = p["message"] as? String
                XCTAssertNotNil(message)
                XCTAssertEqual(message!, "Hello JSON-RPC")
            case .positional(_):
                XCTFail(
                    "JSONRCP message has positional parameters.  Should be "
                    + "named"
                )
            case .none:
                XCTFail("Parameters are missing")
        }
    }
    
    // -------------------------------------
    func test_can_decode_request_with_two_named_parameters()
    {
        let json =
            #"{"jsonrpc":"2.0", "method": "echo", "#
            + #""params": {"message":"Hello JSON-RPC", "count": 5}, "id": 1}"#

        let request: GeneralRequest
        do
        {
            request = try JSONDecoder()
                .decode(GeneralRequest.self, from: json.data(using: .utf8)!)
        }
        catch
        {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
            return
        }
        
        XCTAssertEqual(request.jsonrpc, "2.0")
        XCTAssertEqual(request.id, 1)
        XCTAssertEqual(request.method, "echo")
        switch request.params
        {
            case .named(let p):
                XCTAssertEqual(p.count, 2)
                let message = p["message"] as? String
                XCTAssertNotNil(message)
                XCTAssertEqual(message!, "Hello JSON-RPC")
                let count = p["count"] as? Int
                XCTAssertNotNil(count)
                XCTAssertEqual(count!, 5)
            case .positional(_):
                XCTFail(
                    "JSONRCP message has positional parameters.  Should be "
                    + "named"
                )
            case .none:
                XCTFail("Parameters are missing")
        }
    }
    
    // MARK:- Version 2 Encoding
    // -------------------------------------
    func test_can_encode_request_with_no_parameters()
    {
        let expected =
            #"{"jsonrpc":"2.0","id":1,"method":"echo"}"#
        
        let request = GeneralRequest(version: .v2, id: 1, method: "echo")
        
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
    func test_can_encode_request_with_empty_positional_parameters()
    {
        let expected =
            #"{"jsonrpc":"2.0","id":1,"method":"echo"}"#
        
        let request = GeneralRequest(
            version: .v2,
            id: 1,
            method: "echo",
            params: []
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
    func test_can_encode_request_with_one_positional_parameter()
    {
        let expected =
            #"{"jsonrpc":"2.0","id":1,"method":"echo","#
            + #""params":["Hello JSON-RPC"]}"#
        
        let request = GeneralRequest(
            version: .v2,
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
    func test_can_encode_request_with_two_positional_parameters()
    {
        let expected =
            #"{"jsonrpc":"2.0","id":1,"method":"echo","#
            + #""params":["Hello JSON-RPC",5]}"#
        
        let request = GeneralRequest(
            version: .v2,
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
    
    // -------------------------------------
    func test_can_encode_request_with_empty_named_parameters()
    {
        let expected =
            #"{"jsonrpc":"2.0","id":1,"method":"echo"}"#
        
        let request = GeneralRequest(
            version: .v2,
            id: 1,
            method: "echo",
            params: [:]
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
    func test_can_encode_request_with_one_named_parameter()
    {
        let expected =
            #"{"jsonrpc":"2.0","id":1,"method":"echo","#
            + #""params":{"message":"Hello JSON-RPC"}}"#

        let request = GeneralRequest(
            version: .v2,
            id: 1,
            method: "echo",
            params: ["message": "Hello JSON-RPC"]
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
    func test_can_encode_request_with_two_named_parameters()
    {
        let expected =
            #"{"jsonrpc":"2.0","id":1,"method":"echo","#
            + #""params":{"count":5,"message":"Hello JSON-RPC"}}"#

        let request = GeneralRequest(
            version: .v2,
            id: 1,
            method: "echo",
            params: ["message": "Hello JSON-RPC", "count": 5]
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
    
    // MARK:- Batch Requests
    // -------------------------------------
    func test_can_decode_batch_requests()
    {
        let json = #"[{"jsonrpc":"2.0","id":1,"method":"foo"},"#
            + #"{"jsonrpc":"2.0","id":2,"method":"food"},"#
            + #"{"jsonrpc":"2.0","id":null,"method":"drink"}]"#
        
        let jsonData = json.data(using: .ascii)!
        guard let array =
                try? JSONDecoder().decode([GeneralRequest].self, from: jsonData)
        else
        {
            XCTFail("Unable to decode JSON")
            return
        }
        
        XCTAssertEqual(array.count, 3)
        
        XCTAssertEqual(array[0].version, .v2)
        XCTAssertEqual(array[1].version, .v2)
        XCTAssertEqual(array[2].version, .v2)
        
        XCTAssertEqual(array[0].id, 1)
        XCTAssertEqual(array[1].id, 2)
        XCTAssertNil(array[2].id)
        
        XCTAssertEqual(array[0].method, "foo")
        XCTAssertEqual(array[1].method, "food")
        XCTAssertEqual(array[2].method, "drink")
    }
}
