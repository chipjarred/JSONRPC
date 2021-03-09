import Foundation
import XCTest
@testable import JSONRPC

// -------------------------------------
class V1_Response_UnitTests: XCTestCase
{
    static var allTests =
    [
        ("test_can_decode_response_with_boolean_result", test_can_decode_response_with_boolean_result),
        ("test_can_decode_response_with_integer_result", test_can_decode_response_with_integer_result),
        ("test_can_decode_response_with_double_result", test_can_decode_response_with_double_result),
        ("test_can_decode_response_with_string_result", test_can_decode_response_with_string_result),
        ("test_can_decode_response_with_empty_array_result", test_can_decode_response_with_empty_array_result),
        ("test_can_decode_response_with_one_element_array_result", test_can_decode_response_with_one_element_array_result),
        ("test_can_decode_response_with_two_element_array_result", test_can_decode_response_with_two_element_array_result),
        ("test_can_decode_response_with_empty_object_result", test_can_decode_response_with_empty_object_result),
        ("test_can_decode_response_with_one_property_object_result", test_can_decode_response_with_one_property_object_result),
        ("test_can_decode_response_with_two_property_object_result", test_can_decode_response_with_two_property_object_result),
        ("test_can_decode_response_with_error", test_can_decode_response_with_error),
        ("test_can_encode_response_with_boolean_result", test_can_encode_response_with_boolean_result),
        ("test_can_encode_response_with_integer_result", test_can_encode_response_with_integer_result),
        ("test_can_encode_response_with_double_result", test_can_encode_response_with_double_result),
        ("test_can_encode_response_with_String_result", test_can_encode_response_with_String_result),
        ("test_can_encode_response_with_empty_array_result", test_can_encode_response_with_empty_array_result),
        ("test_can_encode_response_with_one_element_array_result", test_can_encode_response_with_one_element_array_result),
        ("test_can_encode_response_with_two_element_array_result", test_can_encode_response_with_two_element_array_result),
        ("test_can_encode_response_with_empty_object_result", test_can_encode_response_with_empty_object_result),
        ("test_can_encode_response_with_one_member_object_result", test_can_encode_response_with_one_member_object_result),
        ("test_can_encode_response_with_two_member_object_result", test_can_encode_response_with_two_member_object_result),
        ("test_can_encode_response_with_error", test_can_encode_response_with_error),
    ]
    
    // MARK:- Decode
    // -------------------------------------
    func test_can_decode_response_with_boolean_result()
    {
        let json = #"{ "result": true, "error": null, "id": 1}"#
        
        let jsonData = json.data(using: .utf8)!
                
        let response: Response
        do
        {
            response = try JSONDecoder()
                .decode(Response.self, from: jsonData)
        }
        catch
        {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
            return
        }
        
        XCTAssertNil(response.jsonrpc)
        
        switch response.result
        {
            case .boolean(let s):
                XCTAssertEqual(s, true)
            case .none:
                XCTFail("Result is nil!")
            default:
                XCTFail(
                    "Result is the wrong type.  Expected a Bool, but got "
                    + "\(response.result!)"
                )
        }
        
        XCTAssertNil(response.error)
        XCTAssertEqual(response.id, 1)
    }
    
    // -------------------------------------
    func test_can_decode_response_with_integer_result()
    {
        let json = #"{ "result": 42, "error": null, "id": 1}"#
        
        let jsonData = json.data(using: .utf8)!
        
        let response: Response
        do
        {
            response = try JSONDecoder()
                .decode(Response.self, from: jsonData)
        }
        catch
        {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
            return
        }
        
        XCTAssertNil(response.jsonrpc)
        
        switch response.result
        {
            case .integer(let s):
                XCTAssertEqual(s, 42)
            case .none:
                XCTFail("Result is nil!")
            default:
                XCTFail(
                    "Result is the wrong type.  Expected a Int, but got "
                    + "\(response.result!)"
                )
        }
        
        XCTAssertNil(response.error)
        XCTAssertEqual(response.id, 1)
    }
    
    // -------------------------------------
    func test_can_decode_response_with_double_result()
    {
        let json = #"{ "result": 42.1, "error": null, "id": 1}"#
        
        let jsonData = json.data(using: .utf8)!
        
        let response: Response
        do
        {
            response = try JSONDecoder()
                .decode(Response.self, from: jsonData)
        }
        catch
        {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
            return
        }
        
        XCTAssertNil(response.jsonrpc)
        
        switch response.result
        {
            case .double(let s):
                XCTAssertEqual(s, 42.1)
            case .none:
                XCTFail("Result is nil!")
            default:
                XCTFail(
                    "Result is the wrong type.  Expected a Int, but got "
                    + "\(response.result!)"
                )
        }
        
        XCTAssertNil(response.error)
        XCTAssertEqual(response.id, 1)
    }

    // -------------------------------------
    func test_can_decode_response_with_string_result()
    {
        let json = #"{ "result": "Hello JSON-RPC", "error": null, "id": 1}"#
        
        let jsonData = json.data(using: .utf8)!
        
        let response: Response
        do
        {
            response = try JSONDecoder()
                .decode(Response.self, from: jsonData)
        }
        catch
        {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
            return
        }
        
        XCTAssertNil(response.jsonrpc)
        
        switch response.result
        {
            case .string(let s):
                XCTAssertEqual(s, "Hello JSON-RPC")
            case .none:
                XCTFail("Result is nil!")
            default:
                XCTFail(
                    "Result is the wrong type.  Expected a String, but got "
                    + "\(response.result!)"
                )
        }
        
        XCTAssertNil(response.error)
        XCTAssertEqual(response.id, 1)
    }

    // -------------------------------------
    func test_can_decode_response_with_empty_array_result()
    {
        let json =
            #"{ "result": [], "error": null, "id": 1}"#
        
        let jsonData = json.data(using: .utf8)!
        
        let response: Response
        do
        {
            response = try JSONDecoder()
                .decode(Response.self, from: jsonData)
        }
        catch
        {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
            return
        }
        
        XCTAssertNil(response.jsonrpc)
        
        switch response.result
        {
            case .array(let a):
                XCTAssertEqual(a.count, 0)
            case .none:
                XCTFail("Result is nil!")
            default:
                XCTFail(
                    "Result is the wrong type.  Expected a array, but got "
                    + "\(response.result!)"
                )
        }
        
        XCTAssertNil(response.error)
        XCTAssertEqual(response.id, 1)
    }

    // -------------------------------------
    func test_can_decode_response_with_one_element_array_result()
    {
        let json =
            #"{ "result": ["Hello JSON-RPC"], "error": null, "id": 1}"#
        
        let jsonData = json.data(using: .utf8)!
        
        let response: Response
        do
        {
            response = try JSONDecoder()
                .decode(Response.self, from: jsonData)
        }
        catch
        {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
            return
        }
        
        XCTAssertNil(response.jsonrpc)
        
        switch response.result
        {
            case .array(let a):
                XCTAssertEqual(a.count, 1)
                XCTAssertEqual(a[0] as? String, "Hello JSON-RPC")
            case .none:
                XCTFail("Result is nil!")
            default:
                XCTFail(
                    "Result is the wrong type.  Expected a array, but got "
                    + "\(response.result!)"
                )
        }
        
        XCTAssertNil(response.error)
        XCTAssertEqual(response.id, 1)
    }

    // -------------------------------------
    func test_can_decode_response_with_two_element_array_result()
    {
        let json =
            #"{ "result": ["Hello JSON-RPC", 42], "error": null, "id": 1}"#
        
        let jsonData = json.data(using: .utf8)!
        
        let response: Response
        do
        {
            response = try JSONDecoder()
                .decode(Response.self, from: jsonData)
        }
        catch
        {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
            return
        }
        
        XCTAssertNil(response.jsonrpc)
        
        switch response.result
        {
            case .array(let a):
                XCTAssertEqual(a.count, 2)
                XCTAssertEqual(a[0] as? String, "Hello JSON-RPC")
                XCTAssertEqual(a[1] as? Int, 42)
            case .none:
                XCTFail("Result is nil!")
            default:
                XCTFail(
                    "Result is the wrong type.  Expected a array, but got "
                    + "\(response.result!)"
                )
        }
        
        XCTAssertNil(response.error)
        XCTAssertEqual(response.id, 1)
    }

    // -------------------------------------
    func test_can_decode_response_with_empty_object_result()
    {
        let json =
            #"{ "result": {}, "error": null, "id": 1}"#
        
        let jsonData = json.data(using: .utf8)!
        
        let response: Response
        do
        {
            response = try JSONDecoder()
                .decode(Response.self, from: jsonData)
        }
        catch
        {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
            return
        }
        
        XCTAssertNil(response.jsonrpc)
        
        switch response.result
        {
            case .object(let o):
                XCTAssertEqual(o.count, 0)
            case .none:
                XCTFail("Result is nil!")
            default:
                XCTFail(
                    "Result is the wrong type.  Expected a object, but got "
                    + "\(response.result!)"
                )
        }
        
        XCTAssertNil(response.error)
        XCTAssertEqual(response.id, 1)
    }

    // -------------------------------------
    func test_can_decode_response_with_one_property_object_result()
    {
        let json =
            #"{ "result": {"message":"Hello JSON-RPC"}, "error": null, "id": 1}"#
        
        let jsonData = json.data(using: .utf8)!
        
        let response: Response
        do
        {
            response = try JSONDecoder()
                .decode(Response.self, from: jsonData)
        }
        catch
        {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
            return
        }
        
        XCTAssertNil(response.jsonrpc)
        
        switch response.result
        {
            case .object(let o):
                XCTAssertEqual(o.count, 1)
                XCTAssertEqual(o["message"] as? String, "Hello JSON-RPC")
            case .none:
                XCTFail("Result is nil!")
            default:
                XCTFail(
                    "Result is the wrong type.  Expected a object, but got "
                    + "\(response.result!)"
                )
        }
        
        XCTAssertNil(response.error)
        XCTAssertEqual(response.id, 1)
    }

    // -------------------------------------
    func test_can_decode_response_with_two_property_object_result()
    {
        let json =
            #"{ "result": {"message":"Hello JSON-RPC", "count": 42}, "#
            + #""error": null, "id": 1}"#
        
        let jsonData = json.data(using: .utf8)!
        
        let response: Response
        do
        {
            response = try JSONDecoder()
                .decode(Response.self, from: jsonData)
        }
        catch
        {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
            return
        }
        
        XCTAssertNil(response.jsonrpc)
        
        switch response.result
        {
            case .object(let o):
                XCTAssertEqual(o.count, 2)
                XCTAssertEqual(o["message"] as? String, "Hello JSON-RPC")
                XCTAssertEqual(o["count"] as? Int, 42)
            case .none:
                XCTFail("Result is nil!")
            default:
                XCTFail(
                    "Result is the wrong type.  Expected a object, but got "
                    + "\(response.result!)"
                )
        }
        
        XCTAssertNil(response.error)
        XCTAssertEqual(response.id, 1)
    }

    // -------------------------------------
    func test_can_decode_response_with_error()
    {
        let json =
            #"{"result": null, "#
            + #""error": {"code":42, "message":"Oh no, not again!"}, "#
            + #""id": 1}"#

        let jsonData = json.data(using: .utf8)!
        
        let response: Response
        do
        {
            response = try JSONDecoder()
                .decode(Response.self, from: jsonData)
        }
        catch
        {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
            return
        }
        
        XCTAssertNil(response.jsonrpc)
        XCTAssertNil(response.result)
        
        switch response.error
        {
            case .none:
                XCTFail("Expected error")
            case .some(let error):
                XCTAssertEqual(error.code, 42)
                XCTAssertEqual(error.message, "Oh no, not again!")
                XCTAssertNil(error.data)
        }
        
        XCTAssertEqual(response.id, 1)
    }

    // MARK:- Encode
    // -------------------------------------
    func test_can_encode_response_with_boolean_result()
    {
        let expected =
            #"{"id":1,"result":true,"error":null}"#

        let request = GeneralRequest(version: .v1, id: 1, method: "echo")
        let response = Response(for: request, result: true)

        let jsonData: Data
        do { jsonData = try JSONEncoder().encode(response) }
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
    func test_can_encode_response_with_integer_result()
    {
        let expected =
            #"{"id":1,"result":42,"error":null}"#

        let request = GeneralRequest(version: .v1, id: 1, method: "echo")
        let response = Response(for: request, result: 42)

        let jsonData: Data
        do { jsonData = try JSONEncoder().encode(response) }
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
    func test_can_encode_response_with_double_result()
    {
        let expected =
            #"{"id":1,"result":42.5,"error":null}"#

        let request = GeneralRequest(version: .v1, id: 1, method: "echo")
        let response = Response(for: request, result: 42.5)

        let jsonData: Data
        do { jsonData = try JSONEncoder().encode(response) }
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
    func test_can_encode_response_with_String_result()
    {
        let expected =
            #"{"id":1,"result":"Belgium, man. Belgium!","error":null}"#

        let request = GeneralRequest(version: .v1, id: 1, method: "echo")
        let response = Response(
            for: request,
            result: "Belgium, man. Belgium!"
        )

        let jsonData: Data
        do { jsonData = try JSONEncoder().encode(response) }
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
    func test_can_encode_response_with_empty_array_result()
    {
        let expected =
            #"{"id":1,"result":[],"error":null}"#

        let request = GeneralRequest(version: .v1, id: 1, method: "echo")
        let response = Response(for: request, result: [])

        let jsonData: Data
        do { jsonData = try JSONEncoder().encode(response) }
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
    func test_can_encode_response_with_one_element_array_result()
    {
        let expected =
            #"{"id":1,"result":[42],"error":null}"#

        let request = GeneralRequest(version: .v1, id: 1, method: "echo")
        let response = Response(for: request, result: [42])

        let jsonData: Data
        do { jsonData = try JSONEncoder().encode(response) }
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
    func test_can_encode_response_with_two_element_array_result()
    {
        let expected =
            #"{"id":1,"result":[42,"Ford, what's this fish doing in my ear?"]"#
            + #","error":null}"#

        let request = GeneralRequest(version: .v1, id: 1, method: "echo")
        let response = Response(
            for: request,
            result: [42, "Ford, what's this fish doing in my ear?"]
        )

        let jsonData: Data
        do { jsonData = try JSONEncoder().encode(response) }
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
    func test_can_encode_response_with_empty_object_result()
    {
        let expected =
            #"{"id":1,"result":{},"error":null}"#

        let request = GeneralRequest(version: .v1, id: 1, method: "echo")
        let response = Response(for: request, result: [:])

        let jsonData: Data
        do { jsonData = try JSONEncoder().encode(response) }
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
    func test_can_encode_response_with_one_member_object_result()
    {
        let expected =
            #"{"id":1,"result":{"answer":42},"error":null}"#

        let request = GeneralRequest(version: .v1, id: 1, method: "echo")
        let response = Response(for: request, result: ["answer": 42])

        let jsonData: Data
        do { jsonData = try JSONEncoder().encode(response) }
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
    func test_can_encode_response_with_two_member_object_result()
    {
        let expected =
            #"{"id":1,"result":{"answer":42,"question":"#
            + #""What do you get when you multiply 6 by 9?"},"error":null}"#

        let request = GeneralRequest(version: .v1, id: 1, method: "echo")
        let response = Response(
            for: request,
            result:
            [
                "answer": 42,
                "question": "What do you get when you multiply 6 by 9?"
            ]
        )

        let jsonData: Data
        do { jsonData = try JSONEncoder().encode(response) }
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
    func test_can_encode_response_with_error()
    {
        let expected =
            #"{"id":1,"result":null,"error":{"#
            + #""message":"I always knew there was something fundamentally "#
            + #"wrong with the universe.","#
            + #""data":"","#
            + #""code":42"#
            + #"}}"#

        let request = GeneralRequest(version: .v1, id: 1, method: "echo")
        let response = Response(
            for: request,
            error: JSONRPC.Error(
                code: 42,
                message:
                    "I always knew there was something fundamentally wrong with"
                    + " the universe.",
                data: nil
            )
        )

        let jsonData: Data
        do { jsonData = try JSONEncoder().encode(response) }
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
