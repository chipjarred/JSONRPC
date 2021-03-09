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
public struct CodingKey: Swift.CodingKey, ExpressibleByStringLiteral
{
    public typealias StringLiteralType = String
    public let stringValue: String
    public let intValue: Int?
    
    // -------------------------------------
    public init?(intValue: Int) {
        self.init(stringValue: "\(intValue)", intValue: intValue)
    }
    
    // -------------------------------------
    public init?(stringValue: String) {
        self.init(stringValue: stringValue, intValue: Int(stringValue))
    }
    
    // -------------------------------------
    public init(stringLiteral: String) {
        self.init(stringValue: stringLiteral, intValue: nil)
    }
    
    // -------------------------------------
    private init(stringValue: String, intValue: Int?)
    {
        self.stringValue = stringValue
        self.intValue = intValue
    }
}

// -------------------------------------
public enum Version
{
    public typealias RawValue = String?
    static let version2String = "2.0"
    
    case v1
    case v2
    
    @inlinable public static var `default`: Self { return .v2 }
    
    // -------------------------------------
    @usableFromInline
    internal init?(rawValue: RawValue)
    {
        switch rawValue
        {
            case .none              : self = .v1
            case Self.version2String: self = .v2
                
            default: return nil
        }
    }
    
    // -------------------------------------
    @usableFromInline
    internal var rawValue: String?
    {
        switch self
        {
            case .v1: return nil
            case .v2: return Self.version2String
        }
    }
}

// -------------------------------------
public func isVersionValid(_ version: String?) -> Bool
{
    guard let version = version else {
        return true // version 1
    }
    
    return version == "2.0"
}

// -------------------------------------
internal func throwInvalidVersion(
    for version: String,
    decoder: Decoder) throws -> Never
{
    throw DecodingError.typeMismatch(
        Version.self, DecodingError.Context(
            codingPath: decoder.codingPath,
            debugDescription: "Invalid JSONRPC version: \"\(version)\""
        )
    )
}
