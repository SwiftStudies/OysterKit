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

public protocol ExtendedRule : Rule {
    var  behaviour   : Behaviour {get}
    var  annotations : RuleAnnotations {get}
    
    func test(with lexer : LexicalAnalyzer, `for` ir:IntermediateRepresentation) throws
    func instanceWith(behaviour:Behaviour?, annotations:RuleAnnotations?)->Self
}

public extension ExtendedRule {
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
    
    public var structural : Bool {
        if case .structural(_) = behaviour.kind {
            return true
        }
        return false
    }
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
    
    public func instanceWith(with behaviour:Behaviour)->Self{
        return instanceWith(behaviour: behaviour, annotations: annotations)
    }
    
    public func instanceWith(annotations:RuleAnnotations)->Self{
        return instanceWith(behaviour: behaviour, annotations: annotations)
    }
    
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
    
    public func newBehaviour(_ kind:Kind?=nil, negated:Bool? = nil, lookahead:Bool? = nil)->Self{
        return instanceWith(behaviour: Behaviour(kind ?? behaviour.kind, cardinality: behaviour.cardinality, negated: negated ?? behaviour.negate, lookahead: lookahead ?? behaviour.lookahead), annotations: annotations)
    }
    
    public func newBehaviour(_ kind:Kind?=nil, cardinality: ClosedRange<Int>, negated:Bool? = nil, lookahead:Bool? = nil)->Self{
        return instanceWith(behaviour: behaviour.instanceWith(kind, cardinality: cardinality, negated: negated, lookahead: lookahead), annotations: annotations)
    }
    
    public func newBehaviour(_ kind:Kind?=nil, cardinality: PartialRangeFrom<Int>, negated:Bool? = nil, lookahead:Bool? = nil)->Self{
        return instanceWith(behaviour: behaviour.instanceWith(kind, cardinality: cardinality, negated: negated, lookahead: lookahead), annotations: annotations)
    }
    
    
    public func match(with lexer: LexicalAnalyzer, for ir: IntermediateRepresentation) throws -> MatchResult {
        return try evaluate(test,using: lexer, and: ir)
    }
    
    public func evaluate(_ matcher:RuleTest, using lexer:LexicalAnalyzer, and ir:IntermediateRepresentation) throws -> MatchResult {
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
        
        if structural {
            ir.willEvaluate(token: produces, at: lexer.index)
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
                    if structural {
                        ir.didEvaluate(token: produces,annotations: annotations,  matchResult: result)
                        return result
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
        if structural {
            ir.didEvaluate(token: produces, annotations: annotations, matchResult: result)
        }
        
        return result
    }
    
}
