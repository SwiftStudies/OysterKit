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

/// There's a rule stack, when you push a testable it puts a rule on the top of the stack

public enum ParserInstruction {
    /// Rule
    case push(Testable)         //Creates a rule with the test on the top of the stack
    case negate                 // Pops negates pushes
    case lookahead              // Pops negates pushes
    case require(Cardinality)   //Pops sets requirement pushes
    case annotations(RuleAnnotations) //Pops sets annotations and pushes
    
    /// Lexer
    case mark(skipping:Bool)    // Scanner mark
    case proceed
    case rewind
    
    /// Scanner
    case scanAdvance(Int)
    case scanSequence(String)
    case scanRegex(NSRegularExpression)
    case scanCharacterSet(CharacterSet)
    
    // IR
    case open                   // IR start
    case pass(token:TokenType)  // IR pass
    case fail(error:Error)      // IR fail

    // Flow
    case call(identifier:String)
    case `return`
}

public protocol Testable {
    func test(with:LexicalAnalyzer, for:IntermediateRepresentation) throws
    
    var  matchDescription : String {get}
}

public extension Testable {
    var negates : Bool {
        return false
    }
    
    var looksahead : Bool {
        return false
    }
}

public extension Testable {
    func lookahead()->Testable {
        if !looksahead {
            return Lookahead(for: self)
        }
        return self
    }
    
    func negate()->Testable {
        if !negates {
            return Negate(test: self)
        }
        return self
    }
}

#warning("The hash rule is just for transition")
public protocol RuleType : Rule {
    var     kind : Behaviour.Kind { get }
    var     testable : Testable { get }
    var     cardinality : Cardinality { get }
    var     annotations : RuleAnnotations { get }
    
    func    rule(_ kind:Behaviour.Kind, test : Testable, requiring: Cardinality, with annotations:RuleAnnotations)->RuleType
}


/// Properties

extension RuleType {
    public var behaviour : Behaviour {
        return Behaviour(kind, cardinality: cardinality, negated: testable.negates, lookahead: testable.looksahead)
    }
    
    public func test(with lexer : LexicalAnalyzer, `for` ir:IntermediateRepresentation) throws {
        try testable.test(with: lexer, for: ir)
    }
    
    public func rule(with behaviour:Behaviour?, annotations:RuleAnnotations?)->Rule{
        var test = (behaviour?.negate ?? self.testable.negates) ? self.testable.negate() : self.testable
        test = (behaviour?.lookahead ?? test.looksahead) ? test.lookahead() : test
        
        return rule(behaviour?.kind ?? kind, test: test, requiring: behaviour?.cardinality ?? cardinality, with: annotations ?? self.annotations)
    }
    
    public var description : String {
        return shortDescription
    }
    
    /// An abrieviated description of the rule that should reflect behaviour, but not annotations
    /// and should not expand references
    public var shortDescription : String {
        return behaviour.describe(match: testable.matchDescription, annotatedWith: annotations)
    }
    
    
    
    public var token : TokenType? {
        if case let Behaviour.Kind.structural(token) = kind {
            return token
        }
        return nil
    }
    
    public var error : String? {
        guard let errorAnnotationValue = annotations[RuleAnnotation.error] else {
            return nil
        }
        switch errorAnnotationValue {
        case .string(let value):
            return value
        case .bool(_), .int(_), .set:
            return nil
        }
    }
    
    fileprivate var coalesceErrors : Bool {
        return annotations[RuleAnnotation.custom(label: "_coalesce")] != nil
    }

    fileprivate var fatalError : Bool {
        return annotations[RuleAnnotation.custom(label: "_fatal")] != nil
    }
}

/// Modifiers
extension RuleType {
    public func skip()->RuleType {
        return rule(.skipping, test: testable, requiring: cardinality, with: annotations)
    }
    
    public func scan()->RuleType {
        return rule(.scanning, test: testable, requiring: cardinality, with: annotations)
    }
    
    public func parse(as token:TokenType)->RuleType {
        return rule(.structural(token: token), test: testable, requiring: cardinality, with: annotations)
    }
    
    public func negate()->RuleType{
        return rule(kind, test: testable.negate(), requiring: cardinality, with: annotations)
    }
    
    public func lookahead()->RuleType {
        return rule(kind, test: testable.lookahead(), requiring: cardinality, with: annotations)
    }
    
    public func require(_ cardinality:Cardinality)->RuleType {
        return rule(kind, test: testable, requiring: cardinality, with: annotations)
    }
    
    public func set(_ annotation:RuleAnnotation, to value:RuleAnnotationValue)->RuleType {
        
        return rule(kind, test: testable, requiring: cardinality, with: annotations.merge(with: [annotation : value ]))
    }
    
    public func add(_ annotations:RuleAnnotations)->RuleType {
        return rule(kind, test: testable, requiring: cardinality, with: self.annotations.merge(with: annotations))
    }

}

///Executors
extension RuleType {
    func evaluate(lexer:LexicalAnalyzer, ir:IntermediateRepresentation) throws {
        
        var token : TokenType?
        switch kind {
        case .structural(let createdToken):
            ir.evaluating(createdToken)
            token = createdToken
            fallthrough
        case .scanning:
            lexer.mark(skipping: false)
        case .skipping:
            lexer.mark(skipping: true)
        }
        let structural = token != nil
        
        let skippable = cardinality.minimumMatches == 0
        let unlimited = cardinality.maximumMatches == nil
        
        var matches = 0
        do {
            while unlimited || matches < cardinality.maximumMatches! {
                try testable.test(with: lexer, for: ir)

                matches += 1
            }
        } catch let error as CausalErrorType where error.isFatal {
            lexer.rewind()
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
            if matches < cardinality.minimumMatches {
                lexer.rewind()
                if structural {
                    ir.failed()
                }
                if let specificError = self.error {
                    let causes : [Error] = coalesceErrors ? [] : [error]
                    
                    if fatalError {
                        throw ProcessingError.fatal(message: specificError, causes: causes)
                    }
                    throw ProcessingError.parsing(message: specificError, range: lexer.index...lexer.index, causes: causes)
                } else {
                    throw error
                }
            }
        }
        
        let context = lexer.proceed()
        if let token = token {
            ir.succeeded(token: token, annotations: annotations, range: context.range)
        }
    }
}



struct Lookahead : Testable {
    static let ir = LookAheadIR()
    let     `for` : Testable
    
    init(for test : Testable){
        `for` = test
    }
    
    var looksahead: Bool {
        return true
    }
    
    var negates: Bool {
        return `for`.negates
    }
    
    func test(with lexer:LexicalAnalyzer, for ir:IntermediateRepresentation) throws {
        lexer.mark(skipping: true)
        defer {
            lexer.rewind()
        }
        
        try `for`.test(with: lexer, for: Lookahead.ir)
    }
    
    var matchDescription: String {
        return ">>\(`for`.matchDescription)"
    }
}

struct Negate : Testable {
    let     negated : Testable
    
    init(test : Testable){
        negated = test
    }
    
    var negates: Bool {
        return true
    }
    
    var looksahead: Bool {
        return negated.looksahead
    }
    
    func test(with lexer:LexicalAnalyzer, for ir:IntermediateRepresentation) throws {
        do {
            lexer.mark(skipping: true)
            defer {
                lexer.rewind()
            }
            try negated.test(with:lexer, for:ir)
        } catch {
            try lexer.scanNext()
            return
        }

        //To pass it needed to throw and be handled in the catch block above
        throw ProcessingError.testFailed
    }
    
    var matchDescription: String {
        return "!\(negated.matchDescription)"
    }
}
