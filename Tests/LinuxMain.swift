import XCTest

import JSONRPCTests

var tests = [XCTestCaseEntry]()
tests += JSONRPCTests.allTests()
XCTMain(tests)
