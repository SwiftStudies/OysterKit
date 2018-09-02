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

@available(*, deprecated, message: "Replace with Rule")
typealias BehaviouralRule = Rule

var okDebugEvaluation = false

/**
 Behavioural rule is both an extension to and ultimately a replacement for current
 `Rule`. It bakes in the logic for repeating, negation, lookahead, as well as
 transient and void rules both flattening the evaluation hierarchy and making it
 easier to extend (previously implementations would have to add any of this logic
 themselves, and it's easy to get wrong.
 */
public protocol Rule : CustomStringConvertible{
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
     Creates a rule with the specified behaviour and annotations.
     
     - Parameter behaviour: The behaviour for the new instance, if nil the rule should
     use the default behaviour for the producer.
     - Parameter annotations: The annotations for the new rule, if nil the rule
     should use the default behaviour for the producer.
     - Returns: A new instance with the specified behaviour and annotations.
     */
    func rule(with behaviour:Behaviour?, annotations:RuleAnnotations?)->Rule
    
    /// An abrieviated description of the rule that should reflect behaviour, but not annotations
    /// and should not expand references
    var shortDescription : String {get}
    
    /**
     Should perform the actual check and manage the communicaion with the supplied `IntermedidateRepresentation`. If the match fails, and that failure cannot
     be ignored an `Error` should be thrown. It is the responsiblity of the implementer to ensure the following basic pattern is followed
     
     1. `ir.willEvaluate()` is called to inform the `ir` that evaluation is beginning. If the `ir` returns an existing match result that should be used (proceed to step XXX)
     2. `lexer.mark()` should be called so that an accurate `LexicalContext` can be generated.
     3. Perform apply your rule using `lexer`.
     4. Depending on the outcome, and the to-be-generated token:
     - If the rule was satisfied, return a `MatchResult.success` together with a generated `lexer.proceed()` generated context
     - If the rule was satisfied, but the result should be consumed (no node/token created, but scanning should proceed after the match) return `MatchResult.consume` with a generated `lexer.proceed()` context
     - If the rule was _not_ satisfied but the failure can be ignored return `MatchResult.ignoreFailure`. Depending on your grammar you *may* want to leave the scanner in the same position in which case issue a `lexer.proceed()` but discard the result. Otherwise issue a `lexer.rewind()`.
     - If the rule was _not_ satisfied but the failure should not be ignored. Call `lexer.rewind()` and return a `MatchResult.failure`
     - If the rule was _not_ satisifed and parsing of this branch of the grammar should stop immediately throw an `Error`
     
     For standard implementations of rules that should satisfy almost every grammar see `ParserRule` and `ScannerRule`. `ParserRule` has a custom case which
     provides all of the logic above with the exception of actual matching which is a lot simpler, and it is recommended that you use that if you wish to provide your own rules.
     
     - Parameter with: The `LexicalAnalyzer` providing the scanning functions
     - Parameter for: The `IntermediateRepresentation` that wil be building any data structures required for subsequent interpretation of the parsing results
     */
    func match(with lexer : LexicalAnalyzer, `for` ir:IntermediateRepresentation) throws
}

/// A set of standard properties and functions for all `Rule`s
public extension Rule{
    /// The user specified (in an annotation) error associated with the rule
    public var error : String? {
        guard let value = self[RuleAnnotation.error] else {
            return nil
        }
        
        if case let .string(stringValue) = value {
            return stringValue
        } else {
            return "Unexpected annotation value: \(value)"
        }
    }
    
    /// Returns the value of the specific `RuleAnnotationValue` identified by `annotation` if present
    public subscript(annotation:RuleAnnotation)->RuleAnnotationValue?{
        return annotations[annotation]
    }
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
public extension Rule {
    
    /// `true` if the rule creates ndoes, false otherwise
    public var structural : Bool {
        return behaviour.token != nil
    }
    
    /// `true` if the rule creates ndoes, false otherwise
    public var skipping : Bool {
        if case .skipping = behaviour.kind {
            return true
        }
        return false
    }
    
    /// `true` if the rule creates ndoes, false otherwise
    public var scanning : Bool {
        if case .scanning = behaviour.kind {
            return true
        }
        return false
    }

    /**
     Standard implementation that uses the evaluate function to apply the behaviour of the rule.
     
     - Parameter lexer: The lexer controlling the scanning head
     - Parameter ir: The intermediate representation to use
     - Returns: The match result
    */
    public func match(with lexer: LexicalAnalyzer, for ir: IntermediateRepresentation) throws {
        // Log entrance
        do {
            try evaluate(test,using: lexer, and: ir)
            //Log result
        } catch {
            // Log failure
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
    public func evaluate(_ matcher:@escaping Test, using lexer:LexicalAnalyzer, and ir:IntermediateRepresentation) throws {
        //Prepare for any lookahead by putting a fake IR in place if is lookahead
        //as well as taking an additional mark to ensure position will always be
        //where it was
        
        // Neither skipping nor lookahead should generate tokens
        let ir = behaviour.lookahead || skipping ? LookAheadIR() : ir
        if behaviour.lookahead {
            lexer.mark(skipping:true)
        }
        defer {
            if behaviour.lookahead {
                lexer.rewind()
            }
        }
        
        if let token = behaviour.token {
            ir.evaluating(token)
            lexer.mark(skipping: false)
        } else {
            lexer.mark(skipping:skipping)
        }
        
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
                        try matcher(lexer, ir)
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
                    throw ProcessingError(with: behaviour, and: annotations, whenUsing: lexer, causes: nil)
                }
                matches += 1
            }
        } catch let error as CausalErrorType where error.isFatal {
            throw error
        } catch {
            if matches == 0 && skippable {
                #warning("If a structural node is pinned we should tell the IR to create a node anyway")
                lexer.rewind()
                if structural {
                    ir.failed()
                }
                return
            }
            if matches < behaviour.cardinality.minimumMatches {
                lexer.rewind()
                if structural {
                    ir.failed()
                }
                if let specificError = self.error {
                    let causes : [Error]
                    #warning("Make this a predifined annotation")
                    if annotations[RuleAnnotation.custom(label: "coalesce")] != nil {
                        causes = []
                    } else {
                        causes = [error]
                    }
                    #warning("Make this a predefined annotation")
                    if annotations[RuleAnnotation.custom(label: "fatal")] != nil {
                        throw ProcessingError.fatal(message: specificError, causes: causes)
                    }
                    throw ProcessingError.parsing(message: specificError, range: lexer.index...lexer.index, causes: causes)
                } else {
                    throw error
                }
            }
        }

        switch behaviour.kind {
        case .structural(let token):
            let context = lexer.proceed()
            ir.succeeded(token: token, annotations: annotations, range: context.range)
        case .scanning, .skipping:
            _ = lexer.proceed()
        }
        
    }
}
