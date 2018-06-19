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


enum ConsumedToken : Int, Token{
    case skip
}

private struct EmptyLexicalContext : LexicalContext {
    let source   : String
    let position : String.UnicodeScalarView.Index
    
    fileprivate var range: Range<String.UnicodeScalarView.Index>{
        return position..<position
    }
    
    fileprivate var matchedString: String{
        return ""
    }
}

/**
 A closure that captures all the required behaviour for rule evaluation (but not the parser logic surrounding it. If the rule
 is not satisfied an `Error` should be thrown. The return value simply indicates wether or not a token should be created.
 
 - Parameter lexer: The `LexcicalAnalyzer` to user for scanning
 - Returns: Wether or not a token should be created, so`true` if the rule was satisfied and a token should be created, `false` if it was satisfied but a token should not be created
 */
public typealias CustomRuleClosure = (_ lexer:LexicalAnalyzer) throws -> Bool

/**
 A standard set of `Rule`s for parsing, including a `.custom` case where a `CustomRuleClosure` can be supplied and you only need to provide
 the logic for the actual matching (and any error messages).
 */
public indirect enum ParserRule : Rule, CustomStringConvertible{
    
    /// `true` if a failure to match this rule can be ignored
    public var failureIgnorable : Bool {
        switch self {
        case .optional:
            return true
        case .repeated(_, _, let min, _,_):
            return min ?? 0 == 0
        default:
            return false
        }
    }
    
    /// Returns `true` if this rule is a negation rule
    public var isNot : Bool {
        if case .not = self {
            return true
        } else {
            return false
        }
    }
    
    /**
     Performs the actual match check during parsing based on the specific case of `ParserRule` that this instance is.
    
     - Parameter with: The `LexicalAnalyzer` providing the scanning functions
     - Parameter for: The `IntermediateRepresentation` that wil be building any data structures required for subsequent interpretation of the parsing results
     - Returns: The match result (see `Rule` for full documentation on the behviour of a `Rule`)
    */
    public func match(with lexer : LexicalAnalyzer, `for` ir:IntermediateRepresentation) throws -> MatchResult {
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

        if let knownResult = ir.willEvaluate(rule: self, at: lexer.index){
            
            ir.didEvaluate(rule: self, matchResult: knownResult)
            
            switch knownResult{
            case .success(let lexicalContext):
                lexer.index = lexicalContext.range.upperBound
            case .failure:
                throw GrammarError.matchFailed(token: self.produces)
            default: break
            }
            
            return knownResult
        }
        
        // Mark the current lexer position
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
        
        func success() ->MatchResult{
            matchResult = MatchResult.success(context: lexer.proceed())
            return matchResult
        }
        
        func consume()->MatchResult{
            matchResult = MatchResult.consume(context: lexer.proceed())
            
            return matchResult
        }
        
        func ignoreFailure()->MatchResult{
            matchResult = MatchResult.ignoreFailure(atIndex: lexer.index)
            let _ = lexer.proceed()
            
            return matchResult
        }
        
   

        
        switch self {
        case .terminalUntilOneOf(_, let terminatorCharacter,_):
            if endOfInput {
                throw GrammarError.matchFailed(token: self.produces)
            }
            do {
                try lexer.scanUpTo(oneOf: terminatorCharacter)
                
                return success()
            } catch {
                throw GrammarError.matchFailed(token: self.produces)
            }
        case .terminalUntil(_, let terminator,_):
            if endOfInput {
                throw GrammarError.matchFailed(token: self.produces)
            }
            do {
                try lexer.scanUpTo(terminal: terminator)
                return success()
            } catch {
                throw GrammarError.matchFailed(token: self.produces)
            }
        case .terminal(_, let terminalString,_):
            if endOfInput {
                throw GrammarError.matchFailed(token: self.produces)
            }
            do {
                try lexer.scan(terminal: terminalString)
                return success()
            } catch {
                throw GrammarError.matchFailed(token: self.produces)
            }
        case .terminalFrom(_, let characterSet,_):
            if endOfInput {
                throw GrammarError.matchFailed(token: self.produces)
            }
            do {
                try lexer.scan(oneOf: characterSet)
                return success()
            } catch {
                throw GrammarError.matchFailed(token: self.produces)
            }
        case .sequence(_, let sequence,_):
            for rule in sequence{
                do {
                    let _ = try rule.match(with: lexer, for: ir)
                } catch (let error){

                    if let specificErrorMessage = rule.error {
                        throw LanguageError.scanningError(at: lexer.index..<lexer.index, message: specificErrorMessage)
                    }

                    throw error
                }
            }
            return success()
        case .oneOf(_, let choices,_):
            for rule in choices{
                do {
                    let _ = try rule.match(with: lexer, for: ir)
                    return success()
                } catch (let error) {
                    if let _ = error as? LanguageError {
                        throw error
                    }
                }
            }
            // We expected a match of one of them 
            throw GrammarError.matchFailed(token: self.produces)
        case .repeated(_, let rule, let min, let limit,_):
            let minimum = min ?? 0
            let skippable = minimum == 0
            var matches = 0
            
            do {
                let unlimited = limit == nil
                while unlimited || matches < limit! {
                    switch try rule.match(with: lexer, for: ir){
                    // both of these actively matched
                    case .success, .consume:
                        matches += 1
                    //A repeated no matching, should treat this as a hard failure
                    case .ignoreFailure, .failure:
                        throw GrammarError.noTokenCreatedFromMatch
                    }
                }
            } catch (let error){
                //Should we just consume?
                if matches == 0 && skippable {
                    return ignoreFailure()
                }
                if matches < minimum {
                    if let specificErrorMessage = self.error {
                        throw LanguageError.scanningError(at: lexer.index..<lexer.index, message: specificErrorMessage)
                    }
                    throw error
                }
            }
            return success()
        case .optional(_, let rule,_):
            //If it throws on non match, we don't care... if it returns nil... we don't care
            let optionalMatch = try ParserRule.repeated(produces:transientTokenValue.token, rule,min: nil,limit: 1, [:]).match(with: lexer, for: ir)
            
            switch optionalMatch {
            case .success, .consume:
                matchResult = optionalMatch
                //We still must advance the lexer
                let _ = lexer.proceed()
                return optionalMatch
            case .ignoreFailure:
                //Optionals should be optional themselves, ignoring the failure is not an option
                //Perhaps should consider adding a new GrammarError to provide more accurate feedback
//                throw GrammarError.noTokenCreatedFromMatch
                return ignoreFailure()
            case .failure:
                //Not sure exactly what to do in this case
                throw GrammarError.notImplemented
            }
            
        case .consume(let rule,_):
            let _ = try rule.match(with: lexer, for: ir)

            return consume()
        case .lookahead(let rule,_):
            let _ = lexer.mark()
            do {
                let _ = try rule.match(with: lexer, for: LookAheadIR())
            } catch (let error) {
                lexer.rewind()
                throw error
            }
            lexer.rewind()
            return consume()
        case .not(_, let rule,_):
            do {
                let _ = try rule.match(with: lexer, for: ir)
            } catch {
                if !endOfInput {
                    try lexer.scanNext()                    
                } else {
                    //If I am looking ahead, being at the end in a not rule
                    //is success
                    if let _ = ir as? LookAheadIR{
                        return success()
                    } else {
                        //Fail, it's not not the token, and I'm not looking ahead
                        throw GrammarError.matchFailed(token: self.produces)
                    }
                }
                return success()
            }
            
            throw GrammarError.matchFailed(token: self.produces)
        case .custom(_, let rule, _, _):
            return try rule(lexer) ? success() : consume()
        }
        
    }
    
    public var produces: Token{
        switch self{
        case .terminal(let spec):
            return spec.0
        case .terminalFrom(let spec):
            return spec.0
        case .sequence(let spec):
            return spec.0
        case .oneOf(let spec):
            return spec.0
        case .repeated(let spec):
            return spec.0
        case .optional(let spec):
            return spec.0
        case .terminalUntil(let spec):
            return spec.0
        case .terminalUntilOneOf(let spec):
            return spec.0
        case .consume, .lookahead:
            return ConsumedToken.skip
        case .not(let spec):
            return spec.0
        case .custom(let spec):
            return spec.0
        }
    }
    
    public func instance(with token: Token?, andAnnotations annotations: RuleAnnotations?) -> Rule {
        switch self{
        case .terminal(let oldToken,let string, let oldAnnotations):
            return ParserRule.terminal(produces: token ?? oldToken,string, annotations ?? oldAnnotations)
        case .terminalFrom(let oldToken, let characterSet, let oldAnnotations):
            return ParserRule.terminalFrom(produces: token ?? oldToken, characterSet, annotations ?? oldAnnotations)
        case .terminalUntil(let oldToken,let string, let oldAnnotations):
            return ParserRule.terminalUntil(produces: token ?? oldToken,string ,annotations ?? oldAnnotations)
        case .terminalUntilOneOf(let oldToken, let characterSet, let oldAnnotations):
            return ParserRule.terminalUntilOneOf(produces: token ?? oldToken, characterSet, annotations ?? oldAnnotations)
        case .consume(let rule, let oldAnnotations):
            return ParserRule.consume(rule, annotations ?? oldAnnotations)
        case .repeated(let oldToken, let rule, let min, let limit, let oldAnnotations):
            return ParserRule.repeated(produces: token ?? oldToken, rule, min: min, limit: limit, annotations ?? oldAnnotations)
        case .optional(let oldToken, let rule, let oldAnnotations):
            return ParserRule.optional(produces: token ?? oldToken, rule, annotations ?? oldAnnotations)
        case .sequence(let oldToken, let rules, let oldAnnotations):
            return ParserRule.sequence(produces: token ?? oldToken, rules, annotations ?? oldAnnotations)
        case .oneOf(let oldToken, let rules, let oldAnnotations):
            return ParserRule.oneOf(produces: token ?? oldToken, rules, annotations ?? oldAnnotations)
        case .custom(let oldToken, let closure, let description, let oldAnnotations):
            return ParserRule.custom(produces: oldToken, closure, description, annotations ?? oldAnnotations)
        case .lookahead(let rule, let oldAnnotations):
            return ParserRule.lookahead(rule, annotations ?? oldAnnotations)
        case .not(let oldToken, let rule, let oldAnnotations):
            return ParserRule.not(produces: token ?? oldToken, rule, annotations ?? oldAnnotations)
        }

    }
    
    /// The annotations associated with the `Rule`
    public var annotations: RuleAnnotations{
        let definedAnnotations : RuleAnnotations?
        switch self {
        case .terminal(_, _, let annotations), .terminalFrom(_, _, let annotations), .terminalUntil(_, _, let annotations), .terminalUntilOneOf(_, _, let annotations), .consume(_, let annotations), .repeated(_, _, _, _, let annotations), .optional(_, _, let annotations), .sequence(_, _, let annotations), .oneOf(_, _, let annotations), .custom(_, _, _, let annotations), .lookahead(_, let annotations), .not(_, _, let annotations):
            definedAnnotations = annotations
        }
        
        return definedAnnotations ?? [:]
    }
    
    /// A human readable description of the `Rule` almost in STLR
    public var description: String{
        let ruleType : String

        switch self{
        case .terminal(_, let string,_):
            ruleType = "\"\(string)\""
        case .terminalFrom:
            ruleType = ".characterSet"
        case .sequence(_, let sequence,_):
            ruleType = "("+sequence.map({"\($0)"}).joined(separator: " ")+")"
        case .oneOf(_, let choices,_):
            ruleType = "("+choices.map({"\($0)"}).joined(separator: "|")+")"
        case .repeated(_, let rule, let min, let limit,_):
            if min ?? 0 == 0 {
                ruleType = "\(rule)*"
            } else if limit == nil{
                ruleType = "\(rule)+"
            } else {
                ruleType = "\(rule)\(min ?? 0)...\(limit ?? 1)"
            }
        case .optional(_, let rule,_):
            ruleType = "\(rule)?"
        case .terminalUntil(_, let string,_):
            ruleType = "(\"\(string)\"!)*"
        case .terminalUntilOneOf:
            ruleType = "(\".characterSet\"!)*"
        case .consume(let rule):
            ruleType = "\(rule)-"
        case .lookahead(let rule):
            ruleType = ">>(\(rule))"
        case .not(let rule):
            ruleType = "\(rule)-"
        case .custom(_, _, let description, _):
            ruleType = description
        }
        
        if !produces.transient {
            return "\(produces) = \(annotations.stlrDescription) \(ruleType)"
        }
        
        return "\(annotations.stlrDescription) \(ruleType)"
    }
    
    /// Matches a terminal input sequence
    case terminal(produces: Token, String, RuleAnnotations?)

    /// Captures terminals until it hits the supplied string
    case terminalUntil(produces: Token, String, RuleAnnotations?)

    /// Captures terminals  until it hits a character of the supplied set
    case terminalUntilOneOf(produces: Token, CharacterSet, RuleAnnotations?)
    
    /// Matches one of a character set
    case terminalFrom(produces:Token, CharacterSet, RuleAnnotations?)
 
    /// Matches a sequence of rules
    case sequence(produces:Token, [Rule] , RuleAnnotations?)
    
    /// Matches one of a series of alternatives
    case oneOf(produces:Token, [Rule], RuleAnnotations?)
    
    /// Matches another rule with the specified bounds
    case repeated(produces:Token, Rule,min:Int?,limit:Int?, RuleAnnotations?)
    
    /// Matches 0 or 1 of the given rule
    case optional(produces:Token, Rule, RuleAnnotations?)
    
    /// Requires that the rule is matched, but the generated token will be consumed 
    /// and not passed to the IntermediateRepresentation
    case consume(Rule, RuleAnnotations?)
    
    /// Determines if the rule would match, but produces no tokens
    case lookahead(Rule, RuleAnnotations?)
    
    /// Matches if the associated `Rule` does NOT match
    case not(produces: Token, Rule, RuleAnnotations?)
    
    /// Matches using the supplied `CustomRuleClosure`. This is the recommended way of implementing custom rules as it means you do not need
    /// to manage the lexer and ir
    case custom(produces: Token, CustomRuleClosure,String, RuleAnnotations?)
}

/**
 A dummy `IntermediateRepresentation` used for lookahead evaluation instead of the standard IR so that the lookahead as no impact on the IR
 */
final private class LookAheadIR : IntermediateRepresentation{
    
    /// Does nothing
    /// Returns: `nil`
    final fileprivate func willEvaluate(rule: Rule, at position: String.UnicodeScalarView.Index) -> MatchResult? {
        return nil
    }
    
    /// Does nothing
    final fileprivate func didEvaluate(rule: Rule, matchResult: MatchResult) {
    }
    
    /// Does nothing
    final fileprivate func willBuildFrom(source: String, with: Language) {
    }
    
    /// Does nothing
    final fileprivate func didBuild() {
    }
    
    /// Does nothing
    func resetState() {
    }
}
