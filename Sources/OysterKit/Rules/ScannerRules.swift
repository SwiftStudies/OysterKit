//    Copyright (c) 2016, RED When Excited
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

/// An `Error` for the different types of error states for the scanner (such as end of file)
private enum ScannerError : Error {
    /// The scan-head was moved beyond the end of the file
    case unexpectedEndOfFile
    /// The scan failed
    case nothingMatched
}

/// A set of low level rules that operate only on terminals. These are much faster than `ParserRules`
public enum ScannerRule : Rule, CustomStringConvertible{
    
    /// Produces the specified token when one of the `String`s in the array is found
    case   oneOf(token: Token,  [String], RuleAnnotations)
    
    /// Produces the specified token when the supplied regular expression is matched
    case   regularExpression(token:Token, pattern:NSRegularExpression, RuleAnnotations)
    
    
    /**
     Performs the actual match check during parsing based on the specific case of `ParserRule` that this instance is.
     
     - Parameter with: The `LexicalAnalyzer` providing the scanning functions
     - Parameter for: The `IntermediateRepresentation` that wil be building any data structures required for subsequent interpretation of the parsing results
     - Returns: The match result (see `Rule` for full documentation on the behviour of a `Rule`)
     */
    public func match(with lexer: LexicalAnalyzer, for ir: IntermediateRepresentation) throws -> MatchResult {
        var matchResult = MatchResult.failure(atIndex: lexer.index)
        
        #if canImport(NaturalLanguage)
        if #available(OSX 10.14, *){
            Log.beginRule(rule: self)
            defer {
                Log.endRule(rule: self, result: matchResult)
            }
        }
        #endif
        
        let endOfInput = lexer.endOfInput
        
        if endOfInput {
            throw ScannerError.unexpectedEndOfFile
        }
        
        // Mark the current lexer position
        if let knownResult = ir.willEvaluate(rule: self, at: lexer.index){
            switch knownResult{
            case .success(let context):
                lexer.index = context.range.upperBound
            case .failure:
                throw ScannerError.nothingMatched
            default: break
            }
            return knownResult
        }

        lexer.mark()
        
        // When the function returns and was not successful make sure that the current
        // mark is discarded
        defer{
            switch matchResult {
            case .failure:
                lexer.rewind()
            default: break
            }
            
            ir.didEvaluate(rule: self, matchResult: matchResult)
        }
        
        switch self {
        case .oneOf(_, let choices, _):
            for choice in choices {
                do {
                    try lexer.scan(terminal: choice)
                    matchResult = .success(context: lexer.proceed())
                    return matchResult
                } catch { }
            }
            throw ScannerError.nothingMatched
        case .regularExpression(_, let regex, _):
            do {
                try lexer.scan(regularExpression: regex)
                matchResult = .success(context: lexer.proceed())
                return matchResult
            } catch {
                throw ScannerError.nothingMatched
            }
        }
        

        
    }
    
    /// The `Token` produced when the rule is matched
    public var produces: Token{
        switch self {
        case .oneOf(let token, _, _):
            return token
        case  .regularExpression(let token, _, _):
            return token
        }
    }

    /// A human readable description of the rule
    public var description: String{
        var body : String
        switch self {
        case .oneOf(_, let choices, let annotations):
            let quotedString = choices.map({
                return "\""+$0+"\""
            })
            body = "\(annotations.stlrDescription)("+quotedString.joined(separator: " | ")+")"
        case .regularExpression(_, let regex, let annotations):
            let pattern = regex.pattern.hasPrefix("^") ? String(regex.pattern[regex.pattern.index(after: regex.pattern.startIndex)...]) : regex.pattern
            body = "\(annotations.stlrDescription)\(annotations.isEmpty ? "" : " ")/\(pattern)/"
        }
        if !produces.transient {
            return "\(produces) = \(body)"
        } else {
            return body
        }
    }

    /// Scanner rules cannot have annotations. All scanner rules can be modelled with
    /// full rules if annotations are needed
    public var annotations: RuleAnnotations{
        switch self {
        case .oneOf(_,_, let annotations):
            return annotations
        case .regularExpression(_, _, let annotations):
            return annotations
        }
    }
    
    /** Creates a new instance of the rule producing different tokens or with different annotations
     
      - Parameter token: A new token, if `nil` the previously produced token will be created
      - Parameter annotations: Different annotations, or if `nil` the previous annotations on the rule
      - Returns: A new instance with the appropriate different token or annotations
    */
    public func instance(with token: Token?, andAnnotations annotations: RuleAnnotations?) -> Rule {
        switch self {
        case .regularExpression(let oldToken, let regex, let oldAnnotations):
            return ScannerRule.regularExpression(token: token ?? oldToken, pattern: regex, annotations ?? oldAnnotations)
        case .oneOf(let oldToken, let strings, let oldAnnotations):
            return ScannerRule.oneOf(token: token ?? oldToken, strings, annotations ?? oldAnnotations)
        }
    }
}
