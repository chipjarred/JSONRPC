import Foundation
import NIX
@testable import JSONRPC
import XCTest

// -------------------------------------
class Utility_UnitTests: XCTestCase
{
    static var allTests =
    [
        ("test_dnsLookup_resolves_domain_name", test_dnsLookup_resolves_domain_name),
    ]
    
    // -------------------------------------
    func test_dnsLookup_resolves_domain_name()
    {
        let host = "www.google.com"
        guard let addresses = dnsLookup(host: host) else
        {
            XCTFail("Failed to get addresses for \(host)")
            return
        }
        
        XCTAssertTrue(
            addresses.contains { $0.family == .inet4 || $0.family == .inet6 }
        )
    }
}
