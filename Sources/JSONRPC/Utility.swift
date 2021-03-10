// Copyright 2021 Chip Jarred
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

// -------------------------------------
internal let runningUnitTests: Bool =
{
    let pInfo = ProcessInfo.processInfo
    return pInfo.environment["XCTestConfigurationFilePath"] != nil
}()


// -------------------------------------
public enum LogLevel: String
{
    case info = "info"
    case warn = "warning"
    case error = "error"
    case critical = "critical"
    case debug = "debug"
}

// -------------------------------------
internal func log(
    _ level: LogLevel = .info,
    _ items: Any...,
    separator: String = " ",
    terminator: String = "\n",
    function: StaticString = #function,
    file: StaticString = #file,
    line: UInt = #line)
{
    var message = "\(level.rawValue): JSONRPC: "
    message += String(describing: items.first)
    
    for item in items.dropFirst() {
        message += separator + String(describing: item)
    }
    
    message += terminator
    
    #if DEBUG
    message += ":\(file):\(line):\(function)"
    #endif
    
    print(message, terminator: "")
    
    #if DEBUG
    if !runningUnitTests
    {
        switch level
        {
            case .error, .critical:
                assertionFailure(message)
            default: break
        }
    }
    #endif
}

// -------------------------------------
func trace(
    _ s: @autoclosure () -> String,
    function: StaticString = #function,
    file: StaticString = #file,
    line: UInt = #line)
{
    #if DEBUG
    print(":\(function):\(line):\(file): \(s())")
    #endif
}

// -------------------------------------
func unreachable(
    function: StaticString = #function,
    file: StaticString = #file,
    line: UInt = #line) -> Never
{
    fatalError(
        "\(function): Unreachable line reached anyway",
        file: file,
        line: line
    )
}

// -------------------------------------
func unimplemented(
    function: StaticString = #function,
    file: StaticString = #file,
    line: UInt = #line) -> Never
{
    fatalError(
        "\(function): Implemente me!",
        file: file,
        line: line
    )
}
