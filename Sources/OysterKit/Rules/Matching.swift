//
//  Matching.swift
//  OysterKit
//
//  Created on 08/09/2017.
//  Copyright © 2017 RED When Excited. All rights reserved.
//

import Foundation

/// Embodies a matching strategy that will advance the lexer until it either
/// fails or succeeds
public protocol Matcher {
    func match(from lexer:LexicalAnalyzer)->Bool
}

/// Used to provide context so that when a context and a matcher are combined
/// a valid rule is formed.
internal struct Context{
    let token       : Token?            //Move to nil meaning transient
    
    let quantifier  : STLRIntermediateRepresentation.Modifier
    
    let annotations : RuleAnnotations
}

/// A composition of context and matching strategy that represents a instance
/// of a rule
internal struct RuleInstance : Rule{
    var context : Context
    let matcher : Matcher
    
    func match(with lexer: LexicalAnalyzer, for ir: IntermediateRepresentation) throws -> MatchResult {
        func complete(_ result:MatchResult, _ error:Error? = nil) throws ->MatchResult{
            ir.didEvaluate(rule: self, matchResult: result)
            
            if let error = error {
                throw error
            }
            
            return result
        }
        
        // Have we already evaluated this rule?
        if let knownResult = ir.willEvaluate(rule: self, at: lexer.index){
            let _ = try complete(knownResult)
            
            switch knownResult{
            case .failure:
                return try complete(.failure(atIndex: lexer.index), GrammarError.matchFailed(token: self.produces))
            case .success(let lexicalContext):
                lexer.index = lexicalContext.range.upperBound
                fallthrough
            default:
                return try complete(knownResult)
            }
            
        }
        
        // Mark the current lexer position
        lexer.mark()

        let minimum     = context.quantifier.minimumMatches
        let unlimited   = context.quantifier.unlimited
        let limit       = context.quantifier.maximumMatches ?? Int.max
        
        var matches     = 0
        
        repeat {
            if matcher.match(from: lexer){
                // We have a match, but should consume it
                if context.quantifier.consume {
                    return try complete(MatchResult.consume(context: lexer.proceed()))
                }
                
                //Increment the number of matches
                matches += 1
            } else {
                if matches < minimum {          //We didn't meet our minimum number of matches, failure
                    lexer.rewind()
                    return try complete(MatchResult.failure(atIndex: lexer.index))
                } else if matches == 0 {        //Our minimum was zero, and we matched nothing, this is an ignorable failure
                    let _ = lexer.proceed()
                    return try complete(.ignoreFailure(atIndex:lexer.index))
                } else {                        //
                    
                }
            }
        } while unlimited || matches < limit
        
        if matches > limit {
            lexer.rewind()
            return try complete(MatchResult.failure(atIndex: lexer.index))
        }
        
        return try complete(MatchResult.success(context: lexer.proceed()))
    }
    
    var produces: Token {
        struct TransientToken : Token {
            let rawValue = transientTokenValue
        }
        return context.token ?? TransientToken()
    }
    
    var annotations : RuleAnnotations {
        get {
            return context.annotations
        }
        
        set {
            context = Context(token: context.token, quantifier: context.quantifier, annotations: newValue)
        }
    }
    
    
}
