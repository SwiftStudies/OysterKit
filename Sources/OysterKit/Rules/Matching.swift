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

/// Embodies a matching strategy that will advance the lexer until it either
/// fails or succeeds
public protocol Matcher {
    /**
     Should determine if, using the `lexer`, the rule embodied by this `Matcher` is satisfied.
     
     - Parameter from: The `LexicalAnalyzer` to use
     - Returns: `true` if the rule is satisfied, `false` otherwise.
    */
    func match(from lexer:LexicalAnalyzer)->Bool
}

/// Used to provide context so that when a context and a matcher are combined
/// a valid rule is formed.
internal struct Context{
    /// The token that should be created
    let token       : Token?            //Move to nil meaning transient
    
    
    /// Any quantifier associated with the rule
    let quantifier  : STLRIntermediateRepresentation.Modifier
    
    
    /// Any annotations associated with this instance of the token
    let annotations : RuleAnnotations
}

/// A composition of context and matching strategy that represents a instance
/// of a rule. It provides the framework for managing lexer context, intermediate representation interactions
/// including consumption of cached results.
internal struct RuleInstance : Rule{
    /// The associated token, quantifier and annotations of this rule instance
    var context : Context
    
    /// The matcher to be used to evaluate in the context
    let matcher : Matcher
    
    /**
     Performs the match using the following methodology
     
        1. Calls `willEvaluate()` on the IR. If the IR returns a cached result that cached result is used (calling `didEvaluate()` on the IR)
        2. Marks the lexer position
        3. Apply the match rule for as long as it matches as constrained by the supplied quantifier. It should be noted that `didEvaluate()` is not
            called until the quantifier has been applied (where the quantifier may impact the overall match result if for example, the required number
            of matches were not found).

    */
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
    
    /// The token that should be created when this `Rule` is satisfied (including quantifier)
    var produces: Token {
        struct TransientToken : Token {
            let rawValue = transientTokenValue
        }
        return context.token ?? TransientToken()
    }
    
    /// The annotations on this instance of the `Rule`
    var annotations : RuleAnnotations {
        get {
            return context.annotations
        }
        
        set {
            context = Context(token: context.token, quantifier: context.quantifier, annotations: newValue)
        }
    }
    
    
}
