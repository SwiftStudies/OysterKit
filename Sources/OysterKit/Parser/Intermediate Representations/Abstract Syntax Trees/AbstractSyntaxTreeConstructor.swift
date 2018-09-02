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

/**
 AbstractSyntaxTreeConstructor is an `IntermediateRepresentation` responsible for briding between the parsing results and an AbstractSyntaxTree.
 It encapsulates a parsing strategy that creates it's own lightweight homogenous representation of the parsed data. It can build into any
 ``AbstractSyntaxTree``, utilizing the `HomogenousTree` by default. In addition it can parse into a heterogenous abstract syntax tree represented by
 any Swift Type by utlizing the Swift Decoder framework to decode the intermediate representation into a decodable container structure.
 */
public class AbstractSyntaxTreeConstructor  {
    
    /// Errors that can occur during AST creation
    @available(*,deprecated,message: "Use ProcessingError instead")
    public typealias ConstructionError = ProcessingError
    
    /**
     An entry in the tree.
     */
    public struct IntermediateRepresentationNode : Node {
        /// The token created
        public      let token       : TokenType
        /// The range of the match in the source string
        public      let range       : Range<String.UnicodeScalarView.Index>
        
        /// Children of this node
        public      let children       : [IntermediateRepresentationNode]
        
        /// Any associated annotations made on the `token`
        public      let annotations: [RuleAnnotation : RuleAnnotationValue]
        
        /**
         Creates a new instance with no `value`
         
         -Parameter for: The `TokenType` the node captures
         -Parameter at: The range the token was matched at in the original source string
         -Prameter annotations: Any annotations that should be stored with the node
         */
        public init(for token: TokenType, at range: Range<String.UnicodeScalarView.Index>, annotations:RuleAnnotations) {
            self.token = token
            self.range = range
            self.children = []
            self.annotations = annotations
        }
        
        /**
         Creates a new instance
         
         -Parameter for: The `TokenType` the node captures
         -Parameter at: The range the token was matched at in the original source string
         -Parameter children: Any child nodes of this node
         -Prameter annotations: Any annotations that should be stored with the node
         */
        public init(for token: TokenType, at range: Range<String.UnicodeScalarView.Index>, children:[IntermediateRepresentationNode], annotations:RuleAnnotations) {
            self.token = token
            self.range = range
            self.children = children
            self.annotations = annotations
        }
    }
    
    
    /// The original source string
    private var     source    : String!
    
    /// The original scalars view
    private var     scalars   : String.UnicodeScalarView!
    
    /// The context stack of nodes
    private var     nodeStack = NodeStack<IntermediateRepresentationNode>()
    
    /// The _errors collected during parsing
    internal var     _errors     = [Error]()
    
    /// The errors generated during parsing
    public  var     errors : [Error] {
        return _errors
    }
    
    //// A cache which can optionally be used
    fileprivate var cache : StateCache<String.UnicodeScalarView.Index, Int, MatchResult>?
    
    /// Creates a new instance, preparing to parse the supplied source
    public required init(){
    }
    
    /// Used for testing, creates a new blank instance for manipulation
    public init(with source:String){
        self.source = source
        self.scalars = source.unicodeScalars
    }
    
    /**
     Constructs a heterogenous AST by first constructing the specified DecodableAbstractSyntaxTree (meeting the requirements of the ``ParsingDecoder`` class).
     You typically do not need to use this method (where you are specifying your own AST to use) and you should consider
     ``build<T:Decodable>(_ heterogenousType:T.Type, from source: String, using language: Language)`` which will create a ``HomegenousTree`` which is very
     easy to use to decode into a concrete type.
     
     - Parameter heterogenousType: The ``Decodable`` Swift Type being constructed
     - Parameter using: The ``DecodableAbstractSyntaxTree`` to construct prior to decoding
     - Parameter from: The text to parse and build the tree from
     - Parameter using: The language to use to parse the source
     - Returns: An instance of a decodable type
     */
    public func build<T:Decodable, AST:DecodeableAbstractSyntaxTree>(_ heterogenousType:T.Type, using astType:AST.Type, from source: String, using language: Language) throws -> T{
        return try heterogenousType.decode(source, with: astType, using: language)
    }
    
    /**
     Creates a new empty cache. By default a cache is not used, but this can speed up processing of nodes where there can be
     a series of failures of evaluating a previous set of tokens before failing.
     
     - Parameter size The number of entries that can be cached
     */
    public func initializeCache(depth:Int, breadth: Int){
        cache = StateCache<String.UnicodeScalarView.Index, Int, MatchResult>(memorySize: depth, breadth: breadth)
    }
    
    /**
     Constructs a heterogenous AST by first constructing a ``HomogenousAbstractSyntaxTree`` which is then passed to the ``ParsingDecoder`` to leverage
     Swift's Decoder framework to create the heterogenous AST.
     
     - Parameter heterogenousType: The ``Decodable`` Swift Type being constructed
     - Parameter from: The text to parse and build the tree from
     - Parameter using: The language to use to parse the source
     - Returns: An instance of a decodable type
     */
    public func build<T:Decodable>(_ heterogenousType:T.Type, from source: String, using language: Language) throws -> T{
        return try build(heterogenousType, using: HomogenousTree.self, from: source, using: language)
    }
    
    /**
     Constructs a homogenous AST from the supplied source and language. You typically do not need to use this method (where you are
     specifying your own AST to use) and you should consider ``build(from source: String, using language: Language)`` which creates a
     ``HomegenousTree`` which is very easy to work with.
     
     - Parameter using: The ``AbstractSyntaxTree`` to construct
     - Parameter from: The text to parse and build the tree from
     - Parameter using: The language to use to parse the source
     - Returns: The ``AbstractSyntaxTree``
     */
    public func build<AST:AbstractSyntaxTree>(_ astType:AST.Type, from source: String, using language: Language) throws -> AST{
        self.source  = source
        self.scalars = source.unicodeScalars
        
        do {
            try ParsingStrategy.parse(source, using: language, with: Lexer.self, into: self)
            return try generate(astType)
        } catch {
            _errors.append(error)
            throw ProcessingError.interpretation(message: "AST construction failed", causes: _errors)
        }
    }
    
    /**
     Generates a homogenous AST based on the current state of the IR
     
     - Parameter using: The ``AbstractSyntaxTree`` to construct
     - Returns: The ``AbstractSyntaxTree``
     */
    func generate<AST:AbstractSyntaxTree>(_ astType:AST.Type, source:String? = nil) throws ->AST {
        do {
            let topNode : IntermediateRepresentationNode
            
            guard let topNodes = nodeStack.top?.nodes, topNodes.count > 0 else {
                let error = ProcessingError.interpretation(message: "No nodes created", causes: _errors)
                _errors.append(error)
                throw error
            }
            
            if topNodes.count > 1 {
                // Wrap it in a single node
                topNode = IntermediateRepresentationNode(for: StringToken("root"), at: topNodes.combinedRange, children: topNodes , annotations: [:])
            } else {
                topNode = topNodes[0]
            }
            return try AST(with: topNode, from: source ?? self.source)
        } catch {
            _errors.append(error)
            throw ProcessingError.interpretation(message: "AST construction failed", causes: _errors)
        }
    }
    
    /**
     Constructs a homogenous AST from the supplied source and language.
     
     - Parameter from: The text to parse and build the tree from
     - Parameter language: The language to use to parse the source
     - Returns: A ``HomogenousAbstractSyntaxTree``
     */
    public func build(_ source:String, using language:Language) throws -> HomogenousTree{
        return try build(HomogenousTree.self, from: source, using: language)
    }

    /**
     Constructs a homogenous AST from the supplied language.
     
     - Parameter language: The language to use to parse the source
     - Returns: A ``HomogenousAbstractSyntaxTree``
     */
    public func build(using language:Language) throws -> HomogenousTree{
        return try build(HomogenousTree.self, from: source, using: language)
    }
    
}

/**
 Provide the required implementation of the `IntermediateRepresentation` without exposing API consumers to it. This will enable more
 aggressive refactoring without code breaking changes
 */
extension AbstractSyntaxTreeConstructor : IntermediateRepresentation {
    /// Does nothing
    public func willBuildFrom(source: String, with: Language) {
    }
    
    public func evaluating(_ token: TokenType) {
        nodeStack.push()
    }
    
    public func succeeded(token: TokenType, annotations: RuleAnnotations, range: Range<String.Index>) {
        let children = nodeStack.pop().nodes
        
        let node = IntermediateRepresentationNode(for: token, at: range, children: children, annotations: annotations)
        
        nodeStack.top?.append(node)
    }
    
    public func failed() {
        _ = nodeStack.pop()
    }
    
    /// Does nothing
    public func didBuild() {
        
    }
    
    /// Does nothing
    public func resetState() {
        
    }
}
