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

/// An extension that provides streaming functions to any `Language`
public extension Language{
    
    /**
     Creates a `Sequence` of `Nodes` that can be iterated over. The intention is that these are lazily constructed meaning that they appropriate for use
     for large files where a full AST is not necessarily required.
     
     - Parameter lexer: The `LexicalAnalyzer` to use
     - Returns: A sequence of `Node`s
    */
    public func stream<N:Node,L:LexicalAnalyzer>(lexer:L)->AnySequence<N>{
        return AnySequence<N>(StreamRepresentation<N,L>(source: lexer.source, language: self))
    }
    /**
     Creates a `Sequence` of `Nodes` that can be iterated over using the standard `LexicalAnalyzer`, `Lexer`. The intention is that these are lazily constructed meaning that they appropriate for use
     for large files where a full AST is not necessarily required.
     
    - Returns: A sequence of `Node`s
     */
    public func stream<N:Node>(source:String)->AnySequence<N>{
        return stream(lexer: Lexer(source: source))
    }
}


/**
 A default constructor to be used for streams. Unlike AST constructors it does not attempt to maintain any kind of hierarchy of nodes
 */
final public class StreamConstructor<NodeType:Node> : ASTNodeConstructor{
    
    /// Creates a new instance of the constructor
    public required init() {
        
    }
    
    /**
     Does nothing
     
     - Parameter with: The source `String` being parsed
     */
    public func begin(with source: String) {
        
    }
    
    /**
     Creates a new `NodeType` and returns it
     
     - Parameter token: The token that has been successfully identified in the source
     - Parameter annotations: The annotations that had been marked on this instance of the token
     - Parameter context: The `LexicalContext` from the `LexicalAnalyzer` from which an implementation can extract the matched range.
     - Parameter children: Any `Node`s that were created while this token was being evaluated.
     - Returns: Any `Node` that was created, or `nil` if not
     */
    public func match(token: Token, annotations: RuleAnnotations ,context: LexicalContext, children: [NodeType]) -> NodeType? {
        return NodeType(for: token, at: context.range, annotations: annotations)
    }
    
    /**
     Called when a rule has failed, and does nothing
     
     - Parameter token: The token that failed to be matched in the source
     */
    public func failed(token: Token) {
        
    }
    
    /**
     If the token is not transient and not pinned returns a node for the failure
     
     -Parameter parsingErrors: The errors created during parsing
     -Returns: A potentially modified `Array` of errors.
     */
    public func ignoreableFailure(token: Token, annotations: [RuleAnnotation : RuleAnnotationValue], index: String.UnicodeScalarView.Index)->NodeType? {
        if !token.transient && annotations[RuleAnnotation.pinned] != nil{
            let range = index..<index
            return NodeType(for: token, at: range, annotations: annotations)
        }
        return nil
    }

    /// Returns the supplied errors
    /// - Parameter parsingErrors: The errors generated during parsing
    /// - Return: The value of the `parsingErrors` parameter
    public func complete(parsingErrors: [Error]) -> [Error] {
        return parsingErrors
    }
}

/**
 A lazy iterator that parses for the next `Token` each time the consumer of the `IteratorProtocol` requests the `next()` entry. These cannot
 be created directly but are supplied from the `stream()` functions of a `Language`
 */
public class NodeIterator<N:Node> : IteratorProtocol{
    /// Elements are always `Node`s
    public typealias Element = N
    
    /// Uses the HomogenousAST to create it with the `StreamConstructor` provided as a lighter weight constructor
    public typealias Constructor = HomogenousAST<N,StreamConstructor<N>>
    
    /// The rules being used for parsing
    private let rules   : [Rule]
    
    /// The lexical analyzer
    private var lexer   : LexicalAnalyzer
    
    /// The HomogenousAST being used as the `IntermediateRepresentation`. This is too heavy see Github issue #26
    private var sr      : Constructor
    
    /// The errors generated during parsing
    private var productionErrors  = [Error]()
    
    /// The errors generated during parsing
    public var parsingErrors : [Error]{
        return productionErrors
    }
    
    /**
    Creates a new instance of the stream
     
     - Parameter sr: The `IntermediateRepresentation` to be used to create the stream
     - Parameter lexer: The lexer the parser should use
     - Parameter grammar: The rule set to parse with
    */
    fileprivate init(sr:Constructor, lexer:LexicalAnalyzer,grammar rules:[Rule]) {
        self.sr    = sr
        self.lexer = lexer
        self.rules = rules
    }
    
    /**
     Returns the next node in the stream
     
     - Returns: The next node in the stream or `nil` if the end of the source has been reached or a fatal error has occured
    */
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
    
    /// Returns true if the scan-head is at the end of the source `String`
    public var endOfInput : Bool {
        return lexer.endOfInput
    }
}

/**
 Enables a lazy sequence of `Nodes` to be created from a source `String` and `Language` to be applied
 */
public class StreamRepresentation<N:Node,L:LexicalAnalyzer> : Sequence{
    /// The iterator type to use
    public typealias Iterator = NodeIterator<N>
    
    /// The source string
    let source    : String
    
    /// The language to use
    let language  : Language
    
    /**
     Creates a new instance using the supplied source and language
     
     - Parameter source: The source to be used
     - Parameter language: The language to use for parsing
    */
    public init(source:String, language: Language){
        self.source = source
        self.language = language
    }
    
    /**
     Creates (when called) an `Iterator` for the `Sequence`.
     
     - Returns: A lazy(ish) `Iterator`
    */
    public func makeIterator() -> Iterator {
        let ir = HomogenousAST<N,StreamConstructor<N>>()
        ir.willBuildFrom(source: source, with: language)
        return NodeIterator<N>(sr: ir,lexer: L(source: source), grammar: language.grammar)
    }
}

