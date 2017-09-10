//
//  TokenStreams.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

public extension Language{
    public func stream<N:Node,L:LexicalAnalyzer>(lexer:L)->AnySequence<N>{
        return AnySequence<N>(StreamRepresentation<N,L>(source: lexer.source, language: self))
    }
    public func stream<N:Node>(source:String)->AnySequence<N>{
        return stream(lexer: Lexer(source: source))
    }
}


// TODO: DELETE ME - I think this can go
final public class StreamConstructor<NodeType:Node> : ASTNodeConstructor{
    
    public required init() {
        
    }
    
    public func begin(with source: String) {
        
    }
    
    public func match(token: Token, annotations: RuleAnnotations ,context: LexicalContext, children: [NodeType]) -> NodeType? {
        return NodeType(for: token, at: context.range, annotations: annotations)
    }
    
    public func failed(token: Token) {
        
    }
    
    public func ignoreableFailure(token: Token, annotations: [RuleAnnotation : RuleAnnotationValue], index: String.UnicodeScalarView.Index)->NodeType? {
        if !token.transient && annotations[RuleAnnotation.pinned] != nil{
            let range = index..<index
            return NodeType(for: token, at: range, annotations: annotations)
        }
        return nil
    }

    public func complete(parsingErrors: [Error]) -> [Error] {
        return parsingErrors
    }
}

public class NodeIterator<N:Node> : IteratorProtocol{
    public typealias Element = N
    public typealias Constructor = HomogenousAST<N,StreamConstructor<N>>
    
    private let rules   : [Rule]
    private var lexer   : LexicalAnalyzer
    private var sr      : Constructor
    private var productionErrors  = [Error]()
    
    public var parsingErrors : [Error]{
        return productionErrors
    }
    
    fileprivate init(sr:Constructor, lexer:LexicalAnalyzer,grammar rules:[Rule]) {
        self.sr    = sr
        self.lexer = lexer
        self.rules = rules
    }
    
    public func next() -> N? {
        
        productionErrors.removeAll()
        sr.resetState()
        
        guard !lexer.endOfInput else {
            sr.didBuild()
            return nil
        }
        
        for rule in rules {
            do {
                switch try rule.match(with: lexer, for: sr){
                case .success:
                    if let node = sr.children.first {
                        return node
                    }
                case .failure(let position):
                    //I've added this to try and capture errors. If it causes unit test failures, it used to be combined with .consume below and just ate the error
                    if let error = rule.error {
                        productionErrors.append(LanguageError.parsingError(at: position..<position, message: error))
                    }
                    fallthrough
                case .consume:
                    return next()
                case .ignoreFailure:
                    break
                }
            } catch (let error) {
                productionErrors.append(error)
            }
        }
        
        sr.didBuild()
        return nil
    }
    
    public var endOfInput : Bool {
        return lexer.endOfInput
    }
}

public class StreamRepresentation<N:Node,L:LexicalAnalyzer> : Sequence{
    public typealias Iterator = NodeIterator<N>
    
    let source    : String
    let language  : Language
    
    public init(source:String, language: Language){
        self.source = source
        self.language = language
    }
    
    public func makeIterator() -> Iterator {
        let ir = HomogenousAST<N,StreamConstructor<N>>()
        ir.willBuildFrom(source: source, with: language)
        return NodeIterator<N>(sr: ir,lexer: L(source: source), grammar: language.grammar)
    }
}

