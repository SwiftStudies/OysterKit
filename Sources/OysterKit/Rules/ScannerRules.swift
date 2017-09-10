//
//  ScannerRules.swift
//  OysterKit
//
//
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

private enum ScannerError : Error {
    case unexpectedEndOfFile
    case nothingMatched
}

public enum ScannerRule : Rule, CustomStringConvertible{
    
    case   oneOf(token: Token,  [String], RuleAnnotations)
    
    public func match(with lexer: LexicalAnalyzer, for ir: IntermediateRepresentation) throws -> MatchResult {
        var matchResult = MatchResult.failure(atIndex: lexer.index)
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
        }
        

        
    }
    
    public var produces: Token{
        switch self {
        case .oneOf(let token, _, _):
            return token
        }
    }

    
    public var description: String{
        switch self {
        case .oneOf(_, let choices, let annotations):
            let quotedString = choices.map({
                return "\""+$0+"\""
            })
            return "\(annotations.stlrDescription)("+quotedString.joined(separator: " | ")+")"
        }
    }

    // Scanner rules cannot have annotations. All scanner rules can be modelled with
    // full rules if annotations are needed
    public var annotations: RuleAnnotations{
        get {
            switch self {
            case .oneOf(_,_, let annotations):
                return annotations
            }
        }
        
        set {
            switch self {
            case .oneOf(let token, let strings, _):
                self = .oneOf(token: token, strings, newValue)
            }
        }
    }
}
