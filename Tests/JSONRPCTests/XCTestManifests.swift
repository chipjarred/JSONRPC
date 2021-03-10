import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry]
{
    return [
        testCase(V1_Response_UnitTests.allTests),
        testCase(V1_Request_UnitTests.allTests),
        testCase(V2_Request_UnitTests.allTests),
        testCase(V2_Response_UnitTests.allTests),
        testCase(SocketLineReader_UnitTests.allTests),
    ]
}
#endif
