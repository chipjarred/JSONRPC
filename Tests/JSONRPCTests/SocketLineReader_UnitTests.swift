import Foundation
import XCTest
@testable import JSONRPC
import NIX

// -------------------------------------
class SocketLineReader_UnitTests: XCTestCase
{
    static var allTests =
    [
        ("test_line_reader_reads_lines", test_line_reader_reads_lines),
    ]
    
    // -------------------------------------
    func test_line_reader_reads_lines()
    {
        let input =
        """
        When in disgrace with fortune and men's eyes,
        I alone beweep my outcast state,
        And trouble deaf Heaven with my bootless cries,
        And look upon myself, and curse my fate.
        Wishing myself like unto one more rich in hope.
        Like him.  Like him with friends possessed,
        Desiring this man's art, and that man's scope,
        With what I desire most contented least.
        Yet in this thoughts, myself almost despising,
        I look on thee and them my state,
        Like unto the lark at break of day arising
        Sings hymns from sullen earth at Heaven's gate.
            For thy sweet love remembered such wealth brings,
            That I then scorn to change my state with kings.

        """
        let lines = input.split(separator: "\n")
        
        let (sender, receiver): (SocketIODescriptor, SocketIODescriptor)
        switch NIX.socketpair(.local, .stream, .ip)
        {
            case .success(let s): (sender, receiver) = s
            case .failure(let error):
                XCTFail("Unable to create socket pair: \(error)")
                return
        }
        defer
        {
            _ = NIX.close(sender)
            _ = NIX.close(receiver)
        }
        
        switch NIX.write(sender, input.data(using: .utf8)!)
        {
            case .success(let bytesWritten):
                XCTAssertEqual(bytesWritten, input.count)
                
            case .failure(let error):
                XCTFail("Unable to write data: \(error)")
        }
        
        var lineReader = SocketLineReader()
        
        for expected in lines
        {
            guard let data = lineReader.readLine(from: receiver) else
            {
                XCTFail("Could not read all data!")
                return
            }
            
            let actual = String(data: data, encoding: .utf8)!
            XCTAssertEqual(actual, String(expected))
        }
    }
}
