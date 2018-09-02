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
public protocol CausalErrorType : Error, CustomStringConvertible, CustomDebugStringConvertible{
    /// Any errors which can be rolled up into this error
    var causedBy : [Error]? {get}
    
    /// The range of the error in the source `String`
    var range    : ClosedRange<String.Index>? {get}
    
    /// The message associated with the error
    var message  : String {get}
    
    /// The error should stop subsequent processing
    var isFatal : Bool {get}
}

/**
 Adds some core standard functionality for automatically assembling error messages
 */
public extension CausalErrorType {
    /// A textural description of the error
    var description : String {
        return message
    }
    /// A more detailed description of the error including the hierarchy of errors that built to this error
    var debugDescription : String {
        func dumpCauses(_ indent:Int = 1, causes:[Error])->String{
            var result = ""
            for cause in causes {
                if let cause = cause as? CausalErrorType {
                    result += "\(String(repeating:"\t",count:indent))- \(cause.description)\n\(dumpCauses(indent+1,causes: cause.causedBy ?? []))"
                } else {
                    result += "\(String(repeating:"\t",count:indent))- \(cause.localizedDescription)\n"
                }
            }
            return result
        }
        if let causes = causedBy, !causes.isEmpty {
            return "\(message). Caused by:\n\(dumpCauses(causes: causes))"
        } else {
            return description
        }
    }
}

/// Represents the type of processing error.
public struct ProcessingErrorType : OptionSet {
    public let rawValue: Int
    
    /**
     Creates a new instance with the specified rawValue. Supported types are all captured with static constants and you should not need this
     
     - Parameter rawValue: The raw value
    **/
    public init(rawValue:Int){
        self.rawValue = rawValue
    }
    
    /**
     Creates a new instance classifying the supplied error
     
     - Parameter error: The error to classify
    **/
    public init(from error:Error){
        if let error = error as? ProcessingError {
            switch error {
            case .internal(_):
                rawValue = ProcessingErrorType.internal.rawValue
            case .undefined(_,_,_):
                rawValue = ProcessingErrorType.undefined.rawValue
            case .scanning(_,_,_):
                rawValue = ProcessingErrorType.scanning.rawValue
            case .parsing(_,_,_):
                rawValue = ProcessingErrorType.parsing.rawValue
            case .interpretation(_,_):
                rawValue = ProcessingErrorType.interpretation.rawValue
            case .fatal(_,_):
                rawValue = ProcessingErrorType.fatal.rawValue
            }
        } else {
            rawValue = ProcessingErrorType.foreign.rawValue
        }
    }
    
    /// A non OysterKit error
    public static let foreign           = ProcessingErrorType(rawValue:1 << 0)
    
    /// An internal `ProcessingError`
    public static let `internal`        = ProcessingErrorType(rawValue:1 << 1)
    
    /// An undefined `ProcessingError`
    public static let undefined         = ProcessingErrorType(rawValue:1 << 2)
    
    /// A scanning `ProcessingError`
    public static let scanning          = ProcessingErrorType(rawValue:1 << 3)
    
    /// A parsing `ProcessingError`
    public static let parsing           = ProcessingErrorType(rawValue:1 << 4)
    
    /// An interpretation `ProcessingError`
    public static let interpretation    = ProcessingErrorType(rawValue:1 << 5)
    
    /// A fatal `ProcessingError`
    public static let fatal             = ProcessingErrorType(rawValue:1 << 6)
}

/**
 A useful standard implementation of `TestErrorType` that enables the reporting of most kinds of issues
 */
public enum ProcessingError : CausalErrorType {
    /// An internal error (perhaps an exception thrown compiling a regular expression) that can be wrapped
    /// to provide a `TestError`
    case `internal`(cause:Error)
    /// An error where no specific error message has been defined
    case undefined(message:String, at: String.Index, causes:[Error])
    /// An error during scanning, with a defined message
    case scanning(message:String,position:String.Index,causes:[Error])
    /// An error during parsing, with a defined message
    case parsing(message:String,range:ClosedRange<String.Index>,causes:[Error])
    /// An error during interpretation of parsed results, with a defined message
    case interpretation(message:String,causes:[Error])
    /// A fatal error that should stop parsing and cause exit to the top
    case fatal(message:String, causes:[Error])
    
    /// `true` if `ProcessingError.fatal`
    public var isFatal: Bool{
        if case ProcessingError.fatal = self {
            return true
        }
        return false
    }
    
    /**
     Constructs a scanning or parsing error (depending on wether or not a `TokenType` is supplied) from the supplied data.
     
     - Parameter behaviour: The behaviour of the rule that encountered the error
     - Parameter annotations: Annotations on the rule that encountered the error
     - Parameter lexer: The lexical analyzer being used for scanning
     - Parameter errors: That were generated by any contained tests
    */
    public init(with behaviour:Behaviour, and annotations:RuleAnnotations, whenUsing lexer:LexicalAnalyzer, causes errors:[Error]?){
        if let error = annotations.error{
            switch behaviour.kind {
            case .skipping, .scanning:
                self = .scanning(message: error , position: lexer.index, causes: errors ?? [])
            case .structural:
                self = .parsing(message: error, range: lexer.index...lexer.index, causes: errors ?? [])
            }
        } else {
            self = .undefined(message: "Undefined error", at: lexer.index, causes: errors ?? [])
        }
    }
    
    /// The errors that caused this error, or nil if this is the root error
    public var causedBy: [Error]?{
        switch self {
        case .fatal(_, let causes):
            return causes
        case .`internal`(let cause):
            return [cause]
        case .scanning(_, _,let causes):
            return causes
        case .parsing(_, _, let causes):
            return causes
        case .interpretation(_, let causes):
            return causes
        case .undefined(_,_, let causes):
            return causes
        }
    }
    
    internal var causeRange : ClosedRange<String.Index>?{
        return causedBy?.range
    }
    
    /// The range in the source string that caused this error, or nil (for example an internal error)
    public var range: ClosedRange<String.Index>?{
        switch self {
        case .`internal`, .interpretation:
            return nil
        case .fatal:
            return causeRange
        case .scanning(_, let position, _), .undefined(_, let position, _):
            return position...position
        case .parsing(_, let range, _):
            return range
        }
    }
    
    /// A human readable version of the error message. It does not include any causes
    /// except for internal error (where the cause really is the error being reported)
    public var message : String {
        switch self {
        case .`internal`(let cause):
            if let cause = cause as? LocalizedError {
                return "Internal Error: \(cause.localizedDescription)"
            }
            return "Internal Error"
        case .undefined(let message, let position, _):
            return "Undefined Error: \(message) at \(position.encodedOffset)"
        case .scanning(let message, let position, _):
            return "Scanning Error: \(message) at \(position.encodedOffset)"
        case .parsing(let message, let range, _):
            if range.lowerBound == range.upperBound {
                return "Parsing Error: \(message) at \(range.lowerBound.encodedOffset)"
            }
            return "Parsing Error: \(message) between \(range.lowerBound.encodedOffset) and \(range.upperBound.encodedOffset)"
        case .fatal(let message, _):
            return "Fatal Error: \(message)"
        case .interpretation(let message, _):
            return "Interpretation Error: \(message)"
        }
    }
    
    /// A textual description of the error and its causes
    public var description: String {
        return message
    }
    
    /**
     Filters the error and its caueses by the using the supplied block. Note that internal errors with no
     matching cause will also be filtered out.
     
     - Parameter include: A closure that should return true if the supplied error should be included in the filtered result
     - Returns: A filtered version of the error or `nil` if the error itself does not match the filter
    **/
    public func filtered(include:(Error)->Bool)->ProcessingError?{
        
        let filteredCauses = causedBy?.compactMap({ (error) -> Error? in
            if let error = error as? ProcessingError {
                return error.filtered(include: include)
            }
            return include(error) ? error : nil
        }) ?? []

        if !include(self) && filteredCauses.isEmpty{
            return nil
        }
        
        switch self {
        case .internal(_):
            if filteredCauses.isEmpty {
                return nil
            }
            return self
        case .undefined(let message, let at, _):
            return ProcessingError.undefined(message: message, at: at, causes: filteredCauses)
        case .scanning(let message, let position, _):
            return ProcessingError.scanning(message: message, position: position, causes: filteredCauses)
        case .parsing(let message, let range, _):
            return ProcessingError.parsing(message: message, range: range, causes: filteredCauses)
        case .interpretation(let message, _):
            return ProcessingError.interpretation(message: message, causes: filteredCauses)
        case .fatal(let message, _):
            return ProcessingError.fatal(message: message, causes: filteredCauses)
        }
    }
    
    /**
     Filters this error and all of its causes including only those that are of the types provided
     
     - Parameter includedTypes: The types that should be included after filtering
    **/
    public func filtered(including includedTypes:ProcessingErrorType)->ProcessingError?{
        return filtered(include: { (error) -> Bool in
            return includedTypes.contains(ProcessingErrorType(from: error))
        })
    }
    
    /**
     Filters this error and all of its causes including only those that have messages matching the
     supplied regular expression pattern.
     
     - Parameter pattern: A regular expression to use to check messages from teh errors
     - Returns: `nil` if no errors match, or a new error with just matching children and their parents
    **/
    public func filtered(includingMessagesMatching pattern:String)->ProcessingError?{
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])

            
            return filtered(include: { (error) -> Bool in
                let message : String
                if let processingError = error as? ProcessingError {
                    message = processingError.message
                } else {
                    message = error.localizedDescription
                }
                
                return regex.firstMatch(in: message, options: [], range: NSRange(location: 0, length: message.count)) != nil
                
            })
            
        } catch {
            return nil
        }
    }
    
    /// The type of the error
    public var processingErrorType : ProcessingErrorType {
        return ProcessingErrorType(from: self)
    }
}

public extension CausalErrorType {
    /**
     Returns true if the supplied error includes the supplied description in its description
    
     - Parameter description: The text being searched for
     - Returns: True if it contains the message, false if not
    */
    public func hasCause(description:String)->Bool{
        if message.contains(description){
            return true
        }
        for cause in causedBy ?? [] {
            if let cause = cause as? CausalErrorType, cause.hasCause(description: description){
                return true
            } else if "\(cause)".contains(description){
                return true
            }
        }
        return false
    }
}

public extension Array where Element == Error {
    /// Extracts any causal errors from the array and builds a range from them
    var range    : ClosedRange<String.Index>? {
        var lowerBound : String.Index?
        var upperBound : String.Index?
        
        for cause in compactMap({$0 as? CausalErrorType}){
            if let existingLower = lowerBound, let causeLower = cause.range?.lowerBound {
                lowerBound = Swift.min(existingLower, causeLower)
            } else {
                lowerBound = cause.range?.lowerBound
            }
            if let existingUpper = upperBound, let causeUpper = cause.range?.upperBound {
                upperBound = Swift.max(existingUpper, causeUpper)
            }
        }
        
        switch (lowerBound, upperBound) {
        case (let lower, nil) where lower != nil:
            return lower!...lower!
        case (nil, let upper) where upper != nil:
            return upper!...upper!
        case (let lower,let upper) where upper != nil && lower != nil:
            return lower!...upper!
        default:
            return nil
        }
    }
}
