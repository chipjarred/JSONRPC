import Foundation
@testable import JSONRPC
import XCTest

class AnyJSONData_Decoding_UnitTests: XCTestCase
{
    // -------------------------------------
    static var allTests =
    [
        ("test_can_decode_boolean", test_can_decode_boolean),
        ("test_can_decode_integer", test_can_decode_integer),
        ("test_can_decode_double", test_can_decode_double),
        ("test_can_decode_string", test_can_decode_string),
        ("test_can_decode_array", test_can_decode_array),
        ("test_can_decode_array_nested_in_array", test_can_decode_array_nested_in_array),
        ("test_can_decode_dictionary_nested_in_array", test_can_decode_dictionary_nested_in_array),
        ("test_can_decode_dictionary", test_can_decode_dictionary),
        ("test_can_decode_dictionary_nested_in_dictionary", test_can_decode_dictionary_nested_in_dictionary),
    ]
    
    // -------------------------------------
    func test_can_decode_boolean()
    {
        let testCases: [Bool] = [true, false]
        
        for expected in testCases
        {
            let data = try! JSONEncoder().encode(expected)
            guard let anyData = try? JSONDecoder()
                    .decode(AnyJSONData.self, from: data)
            else
            {
                XCTFail("Got nil decoding AnyJSONData: expected \(expected)")
                continue
            }
            switch anyData
            {
                case .boolean(let b): XCTAssertEqual(b, expected)
                default: XCTFail("Got wrong type: \(anyData)")
            }
        }
    }
    
    // -------------------------------------
    func test_can_decode_integer()
    {
        let testCases: [Int] = [0, 1, -1, 1000, -1000]
        
        for expected in testCases
        {
            let data = try! JSONEncoder().encode(expected)
            guard let anyData = try? JSONDecoder()
                    .decode(AnyJSONData.self, from: data)
            else
            {
                XCTFail("Got nil decoding AnyJSONData: expected \(expected)")
                continue
            }
            switch anyData
            {
                case .integer(let i): XCTAssertEqual(i, expected)
                default: XCTFail("Got wrong type: \(anyData)")
            }
        }
    }
    
    // -------------------------------------
    func test_can_decode_double()
    {
        let testCases: [Double] = [0.1, -0.1, 1.1, -1.1, 1000.1, -1000.1]
        
        for expected in testCases
        {
            let data = try! JSONEncoder().encode(expected)
            guard let anyData = try? JSONDecoder()
                    .decode(AnyJSONData.self, from: data)
            else
            {
                XCTFail("Got nil decoding AnyJSONData: expected \(expected)")
                continue
            }
            switch anyData
            {
                case .double(let d): XCTAssertEqual(d, expected)
                default: XCTFail("Got wrong type: \(anyData)")
            }
        }
    }
    
    // -------------------------------------
    func test_can_decode_string()
    {
        let testCases: [String] =
        [
            "",
            "Here I am, a brain the size of a planet, and you want to know "
            + "if I can pick up a piece of paper",
        ]
        
        for expected in testCases
        {
            let data = try! JSONEncoder().encode(expected)
            guard let anyData = try? JSONDecoder()
                    .decode(AnyJSONData.self, from: data)
            else
            {
                XCTFail("Got nil decoding AnyJSONData: expected \(expected)")
                continue
            }
            switch anyData
            {
                case .string(let s): XCTAssertEqual(s, expected)
                default: XCTFail("Got wrong type: \(anyData)")
            }
        }
    }
    
    // -------------------------------------
    func test_can_decode_array()
    {
        let testCases: [[Any?]] =
        [
            [],
            [0, 42, -42],
        ]
        
        for expected in testCases
        {
            let data = try! JSONEncoder().encode(AnyJSONData.array(expected))
            guard let anyData = try? JSONDecoder()
                    .decode(AnyJSONData.self, from: data)
            else
            {
                XCTFail("Got nil decoding AnyJSONData: expected \(expected)")
                continue
            }
            switch anyData
            {
                case .array(let a):
                    XCTAssertEqual(a.count, expected.count)
                    for (actualElement, expectedElement) in zip(a, expected)
                    {
                        XCTAssertEqual(
                            actualElement as? Int,
                            expectedElement as? Int
                        )
                    }
                    
                default: XCTFail("Got wrong type: \(anyData)")
            }
        }
    }
    
    // -------------------------------------
    func test_can_decode_array_nested_in_array()
    {
        let testCases: [[[Any?]]] =
        [
            [[0, 42, -42], [-1, 0, 1]],
        ]
        
        for expected in testCases
        {
            let data = try! JSONEncoder().encode(AnyJSONData.array(expected))
            guard let anyData = try? JSONDecoder()
                    .decode(AnyJSONData.self, from: data)
            else
            {
                XCTFail("Got nil decoding AnyJSONData: expected \(expected)")
                continue
            }
            switch anyData
            {
                case .array(let a):
                    XCTAssertEqual(a.count, expected.count)
                    for (actualElement, expectedElement) in zip(a, expected)
                    {
                        guard let actualNested = actualElement as? [Int]
                        else
                        {
                            XCTFail(
                                "actual nested array is not [Int] = "
                                    + "\(String(describing: actualElement))"
                            )
                            continue
                        }
                        guard let expectedNested = expectedElement as? [Int]
                        else
                        {
                            XCTFail(
                                "expected nested array is not [Int] = "
                                    + "\(String(describing: expectedElement))"
                            )
                            continue
                        }

                        XCTAssertEqual(actualNested, expectedNested)
                    }
                    
                default: XCTFail("Got wrong type: \(anyData)")
            }
        }
    }
    
    // -------------------------------------
    func test_can_decode_dictionary_nested_in_array()
    {
        let testCases: [[[String: String]]] =
        [
            [
                ["Arthur": "Dent", "Ford": "Prefect"],
                ["Zaphod": "Beeblebrox", "Trisha": "McMillan"]
            ],
        ]
        
        for expected in testCases
        {
            let data = try! JSONEncoder().encode(AnyJSONData.array(expected))
            guard let anyData = try? JSONDecoder()
                    .decode(AnyJSONData.self, from: data)
            else
            {
                XCTFail("Got nil decoding AnyJSONData: expected \(expected)")
                continue
            }
            switch anyData
            {
                case .array(let a):
                    XCTAssertEqual(a.count, expected.count)
                    for (actualElement, expectedElement) in zip(a, expected)
                    {
                        guard let actualNested =
                            actualElement as? [String: String]
                        else
                        {
                            XCTFail(
                                "actual nested array is not [String: String] = "
                                    + "\(String(describing: actualElement))"
                            )
                            continue
                        }

                        XCTAssertEqual(actualNested, expectedElement)
                    }
                    
                default: XCTFail("Got wrong type: \(anyData)")
            }
        }
    }
    
    // -------------------------------------
    func test_can_decode_dictionary()
    {
        let testCases: [[String: Any]] =
        [
            [:],
            [
                "Bool": true,
                "Int": 42,
                "Double": 42.1,
                "String": "Zarniwoop",
            ]
        ]
        
        for expected in testCases
        {
            let data = try! JSONEncoder().encode(AnyJSONData.object(expected))
            guard let anyData = try? JSONDecoder()
                    .decode(AnyJSONData.self, from: data)
            else
            {
                XCTFail("Got nil decoding AnyJSONData: expected \(expected)")
                continue
            }
            switch anyData
            {
                case .object(let o):
                    XCTAssertEqual(o.count, expected.count)
                    for key in expected.keys
                    {
                        if let expectedValue = expected[key] as? Bool
                        {
                            guard let actualValue = o[key] as? Bool else
                            {
                                XCTFail(
                                    "actual value is not "
                                    + "\(type(of: expectedValue)): "
                                    + "\(String(describing: o[key]))"
                                )
                                continue
                            }
                            XCTAssertEqual(actualValue, expectedValue)
                        }
                        else if let expectedValue = expected[key] as? Int
                        {
                            guard let actualValue = o[key] as? Int else
                            {
                                XCTFail(
                                    "actual value is not "
                                    + "\(type(of: expectedValue)): "
                                    + "\(String(describing: o[key]))"
                                )
                                continue
                            }
                            XCTAssertEqual(actualValue, expectedValue)
                        }
                        else if let expectedValue = expected[key] as? Double
                        {
                            guard let actualValue = o[key] as? Double else
                            {
                                XCTFail(
                                    "actual value is not "
                                    + "\(type(of: expectedValue)): "
                                    + "\(String(describing: o[key]))"
                                )
                                continue
                            }
                            XCTAssertEqual(actualValue, expectedValue)
                        }
                        else if let expectedValue = expected[key] as? String
                        {
                            guard let actualValue = o[key] as? String else
                            {
                                XCTFail(
                                    "actual value is not "
                                    + "\(type(of: expectedValue)): "
                                    + "\(String(describing: o[key]))"
                                )
                                continue
                            }
                            XCTAssertEqual(actualValue, expectedValue)
                        }
                    }
                    
                default: XCTFail("Got wrong type: \(anyData)")
            }
        }
    }
    
    // -------------------------------------
    func test_can_decode_array_nested_in_dictionary()
    {
        let testCases: [[String: Any]] =
        [
            [:],
            [
                "Empty": [],
                "Bool": [true, false],
                "Int": [42, -42],
                "Double": [42.1, -42.1],
                "String": ["Zaphod", "Zarniwoop"],
            ]
        ]
        
        for expected in testCases
        {
            let data = try! JSONEncoder().encode(AnyJSONData.object(expected))
            guard let anyData = try? JSONDecoder()
                    .decode(AnyJSONData.self, from: data)
            else
            {
                XCTFail("Got nil decoding AnyJSONData: expected \(expected)")
                continue
            }
            switch anyData
            {
                case .object(let o):
                    XCTAssertEqual(o.count, expected.count)
                    for key in expected.keys
                    {
                        guard (expected[key] as! [Any?]).count > 0 else {
                            continue
                        }
                        
                        if let expectedValue = expected[key] as? [Bool]
                        {
                            guard let actualValue = o[key] as? [Bool] else
                            {
                                XCTFail(
                                    "actual value is not "
                                    + "\(type(of: expectedValue)): "
                                    + "\(String(describing: o[key]))"
                                )
                                continue
                            }
                            XCTAssertEqual(actualValue, expectedValue)
                        }
                        else if let expectedValue = expected[key] as? [Int]
                        {
                            guard let actualValue = o[key] as? [Int] else
                            {
                                XCTFail(
                                    "actual value is not "
                                    + "\(type(of: expectedValue)): "
                                    + "\(String(describing: o[key]))"
                                )
                                continue
                            }
                            XCTAssertEqual(actualValue, expectedValue)
                        }
                        else if let expectedValue = expected[key] as? [Double]
                        {
                            guard let actualValue = o[key] as? [Double] else
                            {
                                XCTFail(
                                    "actual value is not "
                                    + "\(type(of: expectedValue)): "
                                    + "\(String(describing: o[key]))"
                                )
                                continue
                            }
                            XCTAssertEqual(actualValue, expectedValue)
                        }
                        else if let expectedValue = expected[key] as? [String]
                        {
                            guard let actualValue = o[key] as? [String] else
                            {
                                XCTFail(
                                    "actual value is not "
                                    + "\(type(of: expectedValue)): "
                                    + "\(String(describing: o[key]))"
                                )
                                continue
                            }
                            XCTAssertEqual(actualValue, expectedValue)
                        }
                    }
                    
                default: XCTFail("Got wrong type: \(anyData)")
            }
        }
    }
    
    // -------------------------------------
    func test_can_decode_dictionary_nested_in_dictionary()
    {
        let testCases: [[String: Any]] =
        [
            [:],
            [
                "Empty": [:],
                "Bool": ["true": true, "false": false],
                "Int": ["answer": 42, "not_answer": -42],
                "Double": ["almost_answer": 42.1, "way_off": -42.1],
                "String": ["President": "Zaphod", "Executive": "Zarniwoop"],
            ]
        ]
        
        for expected in testCases
        {
            let data = try! JSONEncoder().encode(AnyJSONData.object(expected))
            guard let anyData = try? JSONDecoder()
                    .decode(AnyJSONData.self, from: data)
            else
            {
                XCTFail("Got nil decoding AnyJSONData: expected \(expected)")
                continue
            }
            switch anyData
            {
                case .object(let o):
                    XCTAssertEqual(o.count, expected.count)
                    for key in expected.keys
                    {
                        guard (expected[key] as! [String: Any]).count > 0 else {
                            continue
                        }
                        
                        if let expectedValue = expected[key] as? [String: Bool]
                        {
                            guard let actualValue = o[key] as? [String: Bool]
                            else
                            {
                                XCTFail(
                                    "actual value is not "
                                    + "\(type(of: expectedValue)): "
                                    + "\(String(describing: o[key]))"
                                )
                                continue
                            }
                            XCTAssertEqual(actualValue, expectedValue)
                        }
                        else if let expectedValue =
                            expected[key] as? [String: Int]
                        {
                            guard let actualValue = o[key] as? [String: Int]
                            else
                            {
                                XCTFail(
                                    "actual value is not "
                                    + "\(type(of: expectedValue)): "
                                    + "\(String(describing: o[key]))"
                                )
                                continue
                            }
                            XCTAssertEqual(actualValue, expectedValue)
                        }
                        else if let expectedValue =
                            expected[key] as? [String: Double]
                        {
                            guard let actualValue = o[key] as? [String: Double] else
                            {
                                XCTFail(
                                    "actual value is not "
                                    + "\(type(of: expectedValue)): "
                                    + "\(String(describing: o[key]))"
                                )
                                continue
                            }
                            XCTAssertEqual(actualValue, expectedValue)
                        }
                        else if let expectedValue =
                            expected[key] as? [String: String]
                        {
                            guard let actualValue = o[key] as? [String: String] else
                            {
                                XCTFail(
                                    "actual value is not "
                                    + "\(type(of: expectedValue)): "
                                    + "\(String(describing: o[key]))"
                                )
                                continue
                            }
                            XCTAssertEqual(actualValue, expectedValue)
                        }
                    }
                    
                default: XCTFail("Got wrong type: \(anyData)")
            }
        }
    }
}
