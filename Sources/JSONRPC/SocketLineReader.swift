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
import NIX

// -------------------------------------
internal struct SocketLineReader
{
    var buffer = Data(capacity: 4096)
    
    // -------------------------------------
    /*
     From the socket to form a complete line (that is, a sequence of characters
     terminated by a newline.)
     
     - Parameters:
        - socket: the socket to read from
     
     - Returns:
        - On successfully reading a line, it is returned as a `Data` instance,
            and `buffer` will contain any bytes read after the newline.
        - If an error occurred, the error will already have been logged, and
            `nil` is returned..
     */
    public mutating func readLine(from socket: SocketIODescriptor) -> Data?
    {
        let localBufferSize = 4096
        
        if let line = readLine(from: &buffer) { return line }
        
        var localBuffer = Data(repeating: 0, count: localBufferSize)
        var bytesRead: Int = localBufferSize
        while bytesRead == localBufferSize
        {
            switch NIX.read(socket, &localBuffer)
            {
                case .success(let readCount): bytesRead = readCount
                case .failure(let error):
                    log(
                        .error,
                        "\(Self.self): Unable to read from peer socket: "
                        + "\(error)"
                    )
                    return nil
            }
            
            if bytesRead == 0
            {
                log(
                    .info,
                    "\(Self.self): Peer closed connection"
                )
                return nil
            }
            
            buffer.append(localBuffer[..<bytesRead])
            if let line = readLine(from: &buffer) { return line }
        }
        
        unreachable()
    }
    
    // -------------------------------------
    /**
     Obtain a line of data (that is up to a newline) from `data`.
     
     - Parameter data: On entry, the `Data` instance to read the line from.
        On exit, if a valid line is being returned, the bytes that comprise
        that line will have been removed from `data` as well as the newline.
     
     - Returns: If there is a newline in `data`, the bytes up to, but not
        including the newline is returned as a `Data`instance.  If there is no
        newline, `nil` is return (indicating more bytes need to be read).
     */
    private func readLine(from data: inout Data) -> Data?
    {
        let newLine: UInt8 = 0x0a
        
        guard data.count > 0 else { return nil }
        
        // If there is a newline in data, return the portion up to the newline
        // and remove it and the newline from data.
        if let lineEnd = data.firstIndex(of: newLine)
        {
            defer { data.removeSubrange(...lineEnd) }
            return data[..<lineEnd]
        }

        return nil
    }
}
