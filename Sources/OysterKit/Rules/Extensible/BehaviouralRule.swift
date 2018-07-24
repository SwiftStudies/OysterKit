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

/**
 Behavioural rule is both an extension to and ultimately a replacement for current
 `Rule`. It bakes in the logic for repeating, negation, lookahead, as well as
 transient and void rules both flattening the evaluation hierarchy and making it
 easier to extend (previously implementations would have to add any of this logic
 themselves, and it's easy to get wrong.
 */
public protocol BehaviouralRule : Rule {
    /// The behaviour for the rule controlling things like cardinality and lookahead
    var  behaviour   : Behaviour {get}
    /// The annotations on the rule
    var  annotations : RuleAnnotations {get}
    
    /**
     This function implements the actual test. It is responsible soley for performing
     the test. The scanner head will be managed correctly based on success (it will be
     left in the position at the end of the test), or returned to its pre-test position
     on failure.
     
     - Parameter lexer: The lexer controlling the scanner
     - Parameter ir: The intermediate representation
    */
    func test(with lexer : LexicalAnalyzer, `for` ir:IntermediateRepresentation) throws
    
    /**
     This function should create a new instance of this rule, replacing the behaviour and
     any annotations with those specified in the parameters if not nil, or maintaining the
     current ones if nil.
     
     - Parameter behaviour: The behaviour for the new instance, if nil the new copy should
     use the same behaviour as this instance.
     - Parameter annotations: The annotations for the new instance, if nil the new copy
     should use the same behaviour as this instance.
     - Returns: A new instance with the specified behaviour and annotations.
    */
    func instanceWith(behaviour:Behaviour?, annotations:RuleAnnotations?)->Self    
}

/**
 A matching closure should perform the test using the lexer, create any nodes it wishes
 in the IR. The wrapping function has the responsbility to cleaning up on failure.
 */
public typealias Test = (LexicalAnalyzer, IntermediateRepresentation) throws -> Void

/**
 These extensions both satisfy the core requirements of `Rule` meaning that implementers
 of the protocol do not need to provide them. When `Rule` is replaced with this new
 structure some of these will be modified to ensure OysterKit users do not need to
 modify their code.
 */
public extension BehaviouralRule {
    /// The specific error specified in the definition of this rule in the @error
    /// annotation.
    public  func error(lexer:LexicalAnalyzer, causes:[Error]?)->Error {
        if let error = annotations.error{
            switch behaviour.kind {
            case .skipping, .scanning:
                return TestError.scanningError(message: error , position: lexer.index, causes: causes ?? [])
            case .structural:
                return TestError.parsingError(message: error, range: lexer.index...lexer.index, causes: causes ?? [])
            }
        } else {
            return TestError.undefinedError(at: lexer.index, causes: causes ?? [])
        }
    }
    

    /// The token that the rule produces if structural. For backwards compatibility
    /// `Transient` tokens are created for skipping and scanning
    public var produces: Token {
        switch behaviour.kind {
        case .skipping:
            return TransientToken.labelled("skipping")
        case .scanning:
            return TransientToken.anonymous
        case .structural(let token):
            return token
        }
    }
    
    /// `true` if the rule creates ndoes, false otherwise
    public var structural : Bool {
        if case .structural(_) = behaviour.kind {
            return true
        }
        return false
    }
    
    /**
     Creates a new instance of the rule with the specified behaviour but
     all other attributes maintained.
     
     - Parameter behaviour: The new behaviour
    */
    public func instanceWith(with behaviour:Behaviour)->Self{
        return instanceWith(behaviour: behaviour, annotations: annotations)
    }
    
    /**
     Creates a new instance of the rule with the specified annotations but
     all other attributes maintained.
     
     - Parameter annotations: The new annotations
     */
    public func instanceWith(annotations:RuleAnnotations)->Self{
        return instanceWith(behaviour: behaviour, annotations: annotations)
    }
    
    /**
     Create a new instance of the rule with the supplied annotations and token but otherwise exactly the same
     
     - Parameter token: The new ``Token`` or ``nil`` if the token should remain the same
     - Parameter annotations: The new ``Annotations`` or ``nil`` if the annotations are unchanged
     - Returns: A new instance of the ``Rule``. Callers should be aware that this may be a "deep" copy if the implementation is a value type
     */
    public func instance(with token: Token?, andAnnotations annotations: RuleAnnotations?) -> Rule {
        let currentToken : Token?
        switch behaviour.kind {
        case .skipping: currentToken = nil
        case .scanning: currentToken = TransientToken.anonymous
        case .structural(let token): currentToken = token
        }
        
        guard let token = token ?? currentToken else {
            if (annotations ?? self.annotations)[.void] == .set {
                
                return instanceWith(behaviour: Behaviour(.skipping, cardinality: behaviour.cardinality, negated: behaviour.negate, lookahead: behaviour.lookahead), annotations: annotations ?? self.annotations)
            } else {
                
                return instanceWith(behaviour: Behaviour(.scanning, cardinality: behaviour.cardinality, negated: behaviour.negate, lookahead: behaviour.lookahead), annotations: annotations ?? self.annotations)
            }
        }
        
        return instanceWith(behaviour: Behaviour(.structural(token: token), cardinality: behaviour.cardinality, negated: behaviour.negate, lookahead: behaviour.lookahead), annotations: annotations ?? self.annotations)
    }
    
    /**
     Creates a new instance of the rule with the specified behavioural attributes
     all other attributes maintained. If any of the supplied parameters are nil
     the current values will be used. All parameters default to nil.
     
     - Parameter kind: The kind of behaviour
     - Parameter negated: `true` if the results of `test()` should be negated
     - Parameter lookahead: Is lookahead behaviour required
     */
    public func newBehaviour(_ kind:Behaviour.Kind?=nil, negated:Bool? = nil, lookahead:Bool? = nil)->Self{
        return instanceWith(behaviour: Behaviour(kind ?? behaviour.kind, cardinality: behaviour.cardinality, negated: negated ?? behaviour.negate, lookahead: lookahead ?? behaviour.lookahead), annotations: annotations)
    }
    
    /**
     Creates a new instance of the rule with the specified behavioural attributes
     all other attributes maintained. If any of the supplied parameters are nil
     the current values will be used. All parameters default to nil.
     
     - Parameter kind: The kind of behaviour
     - Parameter cardinality: A closed range specifying the range of matches required
     - Parameter negated: `true` if the results of `test()` should be negated
     - Parameter lookahead: Is lookahead behaviour required
     */
    public func newBehaviour(_ kind:Behaviour.Kind?=nil, cardinality: ClosedRange<Int>, negated:Bool? = nil, lookahead:Bool? = nil)->Self{
        return instanceWith(behaviour: behaviour.instanceWith(kind, cardinality: cardinality, negated: negated, lookahead: lookahead), annotations: annotations)
    }
    
    /**
     Creates a new instance of the rule with the specified behavioural attributes
     all other attributes maintained. If any of the supplied parameters are nil
     the current values will be used. All parameters default to nil.
     
     - Parameter kind: The kind of behaviour
     - Parameter cardinality: A partial range specifying the range of matches required with no maxium
     - Parameter negated: `true` if the results of `test()` should be negated
     - Parameter lookahead: Is lookahead behaviour required
     */
    public func newBehaviour(_ kind:Behaviour.Kind?=nil, cardinality: PartialRangeFrom<Int>, negated:Bool? = nil, lookahead:Bool? = nil)->Self{
        return instanceWith(behaviour: behaviour.instanceWith(kind, cardinality: cardinality, negated: negated, lookahead: lookahead), annotations: annotations)
    }
    
    /**
     Standard implementation that uses the evaluate function to apply the behaviour of the rule.
     
     - Parameter lexer: The lexer controlling the scanning head
     - Parameter ir: The intermediate representation to use
     - Returns: The match result
    */
    public func match(with lexer: LexicalAnalyzer, for ir: IntermediateRepresentation) throws -> MatchResult {
        return try evaluate(test,using: lexer, and: ir)
    }
    
    /**
     Standard implementation that applies the behaviour of the rule.
     
     - Parameter matcher: The test to use, wrap, in the specified behaviour. 
     - Parameter lexer: The lexer controlling the scanning head
     - Parameter ir: The intermediate representation to use
     - Returns: The match result
     */
    public func evaluate(_ matcher:Test, using lexer:LexicalAnalyzer, and ir:IntermediateRepresentation) throws -> MatchResult {
        //Prepare for any lookahead by putting a fake IR in place if is lookahead
        //as well as taking an additional mark to ensure position will always be
        //where it was
        let ir = behaviour.lookahead ? LookAheadIR() : ir
        if behaviour.lookahead {
            lexer.mark()
        }
        defer {
            if behaviour.lookahead {
                lexer.rewind()
            }
        }
        
        
        let endOfInput = lexer.endOfInput
        lexer.mark()
        let startPosition = lexer.index
        
        if structural {
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
        }
        
        let skippable = behaviour.cardinality.minimumMatches == 0
        let unlimited = behaviour.cardinality.maximumMatches == nil
        
        var matches = 0
        do {
            while unlimited || matches < behaviour.cardinality.maximumMatches! {
                try matcher(lexer, ir)
                matches += 1
            }
        } catch {
            if matches == 0 && skippable {
                let lexerContext = lexer.proceed()
                if structural {
                    let result = MatchResult.ignoreFailure(atIndex: lexerContext.range.lowerBound)
                    ir.didEvaluate(token: produces, annotations: annotations, matchResult: result)
                    let _ = lexer.proceed()
                    return result
                }
                return MatchResult.ignoreFailure(atIndex: lexerContext.range.lowerBound)
            }
            if matches < behaviour.cardinality.minimumMatches {
                lexer.rewind()
                if behaviour.negate {
                    lexer.mark()
                    if !endOfInput {
                        try lexer.scanNext()
                    }
                    let result = MatchResult.success(context: lexer.proceed())
                    switch behaviour.kind {
                    case .structural(let produces):
                        ir.didEvaluate(token: produces,annotations: annotations,  matchResult: result)
                        return result
                    case .scanning:
                        _ = ir.willEvaluate(token: TransientToken.anonymous, at: startPosition)
                        ir.didEvaluate(token: TransientToken.anonymous, annotations: [:], matchResult: result)
                    case .skipping: break
                    }

                    return result
                }
                if let specificError = self.error {
                    if structural {
                        throw LanguageError.parsingError(at: lexer.index..<lexer.index, message: specificError)
                    } else {
                        throw LanguageError.scanningError(at: lexer.index..<lexer.index, message: specificError)
                    }
                } else {
                    throw error
                }
            }
        }
        if behaviour.negate {
            let successPosotion = lexer.index
            let errorMessage = error ?? "Failed to match"
            lexer.rewind()
            if structural {
                ir.didEvaluate(token: produces, annotations: annotations, matchResult: MatchResult.failure(atIndex: lexer.index))
                throw LanguageError.parsingError(at: lexer.index..<successPosotion, message: errorMessage)
            }
            throw LanguageError.scanningError(at: lexer.index..<successPosotion, message: errorMessage)
        }
        
        let result = MatchResult.success(context: lexer.proceed())
        switch behaviour.kind {
        case .structural(let produces):
            ir.didEvaluate(token: produces,annotations: annotations,  matchResult: result)
            return result
        case .scanning:
            _ = ir.willEvaluate(token: TransientToken.anonymous, at: startPosition)
            ir.didEvaluate(token: TransientToken.anonymous, annotations: [:], matchResult: result)
        case .skipping: break
        }
        
        return result
    }
    
    
}