//    Copyright (c) 2018, RED When Excited
//    All rights reserved.
//
//    Redistribution and use in source and binary forms, with or without
//    modification, are permitted provided that the following conditions are met:
//
//    * Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
//    * Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
//    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
//    FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//    SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import Foundation

/**
 An error type that captures not just a current error, but the hierarchy of
 errors that caused it.
 */
public protocol TestErrorType : Error, CustomStringConvertible, CustomDebugStringConvertible{
    /// Any errors which can be rolled up into this error
    var causedBy : [Error]? {get}
    /// The range of the error in the source `String`
    var range    : ClosedRange<String.Index>? {get}
    /// The message associated with the error
    var message  : String {get}
}

/**
 Adds some core standard functionality for automatically assembling error messages
 */
public extension TestErrorType {
    /// A textural description of the error
    var description : String {
        return message
    }
    /// A more detailed description of the error including the hierarchy of errors that built to this error
    var debugDescription : String {
        func dumpCauses(_ indent:Int = 1, causes:[Error])->String{
            if let causedBy = causedBy {
                var result = ""
                for cause in causedBy {
                    if let cause = cause as? TestErrorType {
                        result += "\(String(repeating:"\t",count:indent))- \(cause.description)\n\(dumpCauses(indent+1,causes: cause.causedBy ?? []))"
                    } else {
                        result += "\(String(repeating:"\t",count:indent))- \(cause.localizedDescription)\n"
                    }
                }
                return result
            } else {
                return "\(String(repeating:"\t",count:indent))- Unknown"
            }
        }
        if let causes = causedBy, !causes.isEmpty {
            return "\(message). Caused by:\n\(dumpCauses(causes: causes))"
        } else {
            return description
        }
    }
}

/**
 A useful standard implementation of `TestErrorType` that enables the reporting of most kinds of issues
 */
public enum TestError : TestErrorType {
    /// An internal error (perhaps an exception thrown compiling a regular expression) that can be wrapped
    /// to provide a `TestError`
    case internalError(cause:Error)
    /// An error where no specific error message has been defined
    case undefinedError(at: String.Index, causes:[Error])
    /// An error during scanning, with a defined message
    case scanningError(message:String,position:String.Index,causes:[Error])
    /// An error during parsing, with a defined message
    case parsingError(message:String,range:ClosedRange<String.Index>,causes:[Error])
    /// An error during interpretation of parsed results, with a defined message
    case interpretationError(message:String,causes:[Error])
    
    /// The errors that caused this error, or nil if this is the root error
    public var causedBy: [Error]?{
        switch self {
        case .internalError(let cause):
            return [cause]
        case .scanningError(_, _,let causes):
            return causes
        case .parsingError(_, _, let causes):
            return causes
        case .interpretationError(_, let causes):
            return causes
        case .undefinedError(_, let causes):
            return causes
        }
    }
    
    /// The range in the source string that caused this error, or nil (for example an internal error)
    public var range: ClosedRange<String.Index>?{
        switch self {
        case .internalError, .interpretationError:
            return nil
        case .scanningError(_, let position, _), .undefinedError(let position, _):
            return position...position
        case .parsingError(_, let range, _):
            return range
        }
    }
    
    /// A human readable version of the error message. It does not include any causes
    /// except for internal error (where the cause really is the error being reported)
    public var message : String {
        switch self {
        case .internalError(let cause):
            if let cause = cause as? LocalizedError {
                return "Internal Error: \(cause.localizedDescription)"
            }
            return "Internal Error"
        case .undefinedError(let position, _):
            return "Undefined error at \(position.encodedOffset)"
        case .scanningError(let message, let position, _):
            return "Scanning Error: \(message) at \(position.encodedOffset)"
        case .parsingError(let message, let range, _):
            if range.lowerBound == range.upperBound {
                return "Parsing Error: \(message) at \(range.lowerBound.encodedOffset)"
            }
            return "Parsing Error: \(message) between \(range.lowerBound.encodedOffset) and \(range.upperBound.encodedOffset)"
        case .interpretationError(let message, _):
            return "Interpretation Error: \(message)"
        }
    }
}
