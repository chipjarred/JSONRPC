import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry]
{
    return [
        testCase(AnyJSONData_Decoding_UnitTests.allTests),
        testCase(V1_Response_UnitTests.allTests),
        testCase(V1_Request_UnitTests.allTests),
        testCase(V2_Request_UnitTests.allTests),
        testCase(V2_Response_UnitTests.allTests),
        testCase(SocketLineReader_UnitTests.allTests),
        testCase(Client_Server_UnitTests.allTests),
    ]
}
#endif
