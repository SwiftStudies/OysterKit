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
public protocol BehaviouralRule : Rule, RuleProducer, CustomStringConvertible{
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
    
    /// An abrieviated description of the rule that should reflect behaviour, but not annotations
    /// and should not expand references
    var shortDescription : String {get}
}

/**
 A matching closure should perform the test using the lexer, create any nodes it wishes
 in the IR. The wrapping function has the responsbility to cleaning up on failure.
 */
public typealias Test = (LexicalAnalyzer, IntermediateRepresentation) throws -> Void

fileprivate struct NestedRule : Rule {
    func instance(with token: Token?, andAnnotations annotations: RuleAnnotations?) -> Rule {
        fatalError()
    }
    
    func match(with lexer: LexicalAnalyzer, for ir: IntermediateRepresentation) throws -> MatchResult {
        fatalError()
    }
    
    var produces: Token
    
    var annotations: RuleAnnotations
}


/**
 These extensions both satisfy the core requirements of `Rule` meaning that implementers
 of the protocol do not need to provide them. When `Rule` is replaced with this new
 structure some of these will be modified to ensure OysterKit users do not need to
 modify their code.
 */
public extension BehaviouralRule {

    /// The default behaviour for an existing rule is its current values
    var defaultBehaviour : Behaviour {
        return behaviour
    }
    
    /// The default annotations for an existing rule are its current annotations
    var defaultAnnotations : RuleAnnotations {
        return annotations
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
    
    /// `true` if the rule creates ndoes, false otherwise
    public var skipping : Bool {
        if case .skipping = behaviour.kind {
            return true
        }
        return false
    }

    
    /**
     Create a new instance of the rule with the supplied annotations and token but otherwise exactly the same
     
     - Parameter token: The new ``Token`` or ``nil`` if the token should remain the same
     - Parameter annotations: The new ``Annotations`` or ``nil`` if the annotations are unchanged
     - Returns: A new instance of the ``Rule``. Callers should be aware that this may be a "deep" copy if the implementation is a value type
     */
    #warning("We should no longer need this when legacy rules are removed")
    public func instance(with token: Token?, andAnnotations annotations: RuleAnnotations?) -> Rule {
        let currentToken : Token?
        switch behaviour.kind {
        case .skipping: currentToken = nil
        case .scanning: currentToken = TransientToken.anonymous
        case .structural(let token): currentToken = token
        }
        
        guard let token = token ?? currentToken else {
            if (annotations ?? self.annotations)[.void] == .set {
                
                return rule(with: Behaviour(.skipping, cardinality: behaviour.cardinality, negated: behaviour.negate, lookahead: behaviour.lookahead), annotations: annotations ?? self.annotations)
            } else {
                
                return rule(with: Behaviour(.scanning, cardinality: behaviour.cardinality, negated: behaviour.negate, lookahead: behaviour.lookahead), annotations: annotations ?? self.annotations)
            }
        }
        
        return rule(with: Behaviour(.structural(token: token), cardinality: behaviour.cardinality, negated: behaviour.negate, lookahead: behaviour.lookahead), annotations: annotations ?? self.annotations)
    }

    
    /**
     Standard implementation that uses the evaluate function to apply the behaviour of the rule.
     
     - Parameter lexer: The lexer controlling the scanning head
     - Parameter ir: The intermediate representation to use
     - Returns: The match result
    */
    public func match(with lexer: LexicalAnalyzer, for ir: IntermediateRepresentation) throws -> MatchResult {
        // Log entrance
//        let log = true //behaviour.token != nil
//        if log { print(String(repeating: "  ", count: lexer.depth)+shortDescription+" evaluating at \(lexer.position) '\(lexer.endOfInput ? "🏁" : lexer.current.debugDescription.dropFirst().dropLast())'") }
        do {
            let result = try evaluate(test,using: lexer, and: ir)
            //Log result
//            if log { print(String(repeating: "  ", count: lexer.depth)+shortDescription+" "+result.description) }
            return result
        } catch {
            // Log failure
//            if log { print(String(repeating: "  ", count: lexer.depth)+shortDescription+" \(error)") }
            throw error
        }
    }
    
    /**
     Standard implementation that applies the behaviour of the rule.
     
     - Parameter matcher: The test to use, wrap, in the specified behaviour. 
     - Parameter lexer: The lexer controlling the scanning head
     - Parameter ir: The intermediate representation to use
     - Returns: The match result
     */
    public func evaluate(_ matcher:@escaping Test, using lexer:LexicalAnalyzer, and ir:IntermediateRepresentation) throws -> MatchResult {
        func nestedEvaluate(_ rule:Rule, using lexer:LexicalAnalyzer, and ir:IntermediateRepresentation, with originalMatcher:Test) throws {
            if let cachedResult = ir.willEvaluate(rule: rule, at: lexer.index){
                ir.didEvaluate(rule: rule, matchResult: cachedResult)
                switch cachedResult{
                case .success(let lexicalContext):
                    lexer.index = lexicalContext.range.upperBound
                case .failure:
                    throw GrammarError.matchFailed(token: self.produces)
                default: break
                }
                return
            }
            
            lexer.mark()
            do {
                try originalMatcher(lexer,ir)
                ir.didEvaluate(rule: rule, matchResult: MatchResult.success(context: lexer.proceed()))
            } catch {
                ir.didEvaluate(rule: rule, matchResult: MatchResult.failure(atIndex: lexer.index))
                #warning("AbstractSyntaxTreeConstructor was trying to manage errors on failure itself, and it no longer needs to do that so at this point flushing IR errors because the IR should no longer manage them. This should be removed and error handling pulled out of the IR once the whole stack is replaced")
                if let astConstructor = ir as? AbstractSyntaxTreeConstructor {
                    astConstructor._errors = []
                }
                lexer.rewind()
                throw error
            }
        }
        
        let behaviour : Behaviour
        let annotations : RuleAnnotations
        let structureTest : (originalMatcher:Test, ruleFacade: NestedRule)?
        
        if structural && !self.behaviour.negate{
            behaviour = Behaviour(.skipping, cardinality: self.behaviour.cardinality, negated: self.behaviour.negate, lookahead: self.behaviour.lookahead)
            annotations = [ : ]
            structureTest = (matcher,NestedRule(produces: produces, annotations: self.annotations))
        } else {
            annotations = self.annotations
            behaviour = self.behaviour
            structureTest = nil
        }
        
        //Prepare for any lookahead by putting a fake IR in place if is lookahead
        //as well as taking an additional mark to ensure position will always be
        //where it was
        let ir = behaviour.lookahead ? LookAheadIR() : ir
        if behaviour.lookahead {
            lexer.mark(skipping:true)
        }
        defer {
            if behaviour.lookahead {
                lexer.rewind()
            }
        }
        
        lexer.mark(skipping:skipping)
        
        let skippable = behaviour.cardinality.minimumMatches == 0
        let unlimited = behaviour.cardinality.maximumMatches == nil
        
        var matches = 0
        do {
            while unlimited || matches < behaviour.cardinality.maximumMatches! {
                do {
                    //If the match is negated success means we need to rewind afterwards
                    if behaviour.negate {
                        lexer.mark(skipping:skipping)
                        try matcher(lexer, ir)
                        lexer.rewind()
                    } else {
                        if let structureTest = structureTest {
                            try nestedEvaluate(structureTest.ruleFacade, using: lexer, and: ir, with: structureTest.originalMatcher)
                        } else {
                            try matcher(lexer, ir)
                        }
                    }
                } catch {
                    if behaviour.negate {
                        //We had taken an extra mark due to negation earlier, now we have to take it out
                        lexer.rewind()
                        matches += 1
                        try lexer.scanNext()
                        continue
                    } else {
                        throw error
                    }
                }
                
                if behaviour.negate {
                    throw TestError(with: behaviour, and: annotations, whenUsing: lexer, causes: nil)
                }
                matches += 1
            }
        } catch {
            if matches == 0 && skippable {
                lexer.rewind()
                return MatchResult.ignoreFailure(atIndex: lexer.index)
            }
            if matches < behaviour.cardinality.minimumMatches {
                lexer.rewind()
                if let specificError = self.error {
                    throw LanguageError.scanningError(at: lexer.index..<lexer.index, message: specificError)
                } else {
                    throw error
                }
            }
        }

        let result : MatchResult

        switch behaviour.kind {
        case .structural(let token):
            if behaviour.negate {
                let context = lexer.proceed()
                ir.willEvaluate(token: token, at: context.range.lowerBound)
                result = MatchResult.success(context: lexer.proceed())
                ir.didEvaluate(token: token, annotations: annotations, matchResult: result)
            } else {
                fatalError("Unless negated structural nodes should not need to return an independant result")
            }
        case .scanning:
            result = MatchResult.success(context: lexer.proceed())
        case .skipping:
            if structureTest != nil {
                result = MatchResult.success(context: lexer.proceed())
            } else {
                result = MatchResult.consume(context: lexer.proceed())
            }
        }
        
        return result
    }
    
    
}
