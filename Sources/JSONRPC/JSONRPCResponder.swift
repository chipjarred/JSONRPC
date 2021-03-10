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
public protocol JSONRPCResponder: JSONRPCLogger
{
    var encoder: JSONEncoder { get }
    var decoder: JSONDecoder { get }
    
    func handleNotification(_ notification: Notification)
    func handleRequest(_ request: Request) throws -> Response
    func handleResponse(_ response: Response)
}

// -------------------------------------
public extension JSONRPCResponder
{
    // -------------------------------------
    func translateAndDispatch(jsonData data: Data) throws -> Data?
    {
        if let genRequest = try? decoder.decode(GeneralRequest.self, from: data)
        {
            if genRequest.id == nil
            {
                handleNotification(Notification(from: genRequest))
                return nil
            }
            
            return try _handleRequest(Request(from: genRequest))
        }
        
        if let response = try? decoder.decode(Response.self, from: data) {
            handleResponse(response)
        }
        
        return try invalidJSONData()
    }
    
    // -------------------------------------
    private func _handleRequest(_ request: Request) throws -> Data?
    {
        let response: Response
        do { response = try handleRequest(request) }
        catch let error as JSONRPC.ErrorCode {
            response = Response(for: request, error: Error(code: error))
        }
        catch let error as JSONRPC.Error {
            response = Response(for: request, error: error)
        }
        catch
        {
            let rpcError = Error(
                code: .internalError,
                data: .string("\(error.localizedDescription)")
            )
            response = Response(for: request, error: rpcError)
        }
        
        return try encoder.encode(response)
    }
    
    // -------------------------------------
    private func invalidJSONData() throws -> Data
    {
        let response = Response(error: .parseError)
        return try encoder.encode(response)
    }
}
