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

public struct HomogenousTree : Parsable, CustomStringConvertible {
    public init(with node: AbstractSyntaxTreeNode, from source:String) throws {
        token = node.token
        matchedString = String(source[node.range])
        children = try node.children.map({ try HomogenousTree(with:$0, from: source)})
    }
    
    public let     token         : Token
    public let     matchedString : String
    public let     children      : [HomogenousTree]
    
    private func pretify(prefix:String = "")->String{
        return "\(prefix)\(token) - '\(matchedString)'\(children.count > 0 ? children.reduce("\n", { (previous, current) -> String in return previous+current.pretify(prefix:prefix+"\t")}) : "\n")"
    }
    
    public var description: String{
        return pretify()
    }
}

/**
 Parsable types can construct themselves from nodes generated during parsing
 */
public protocol Parsable {
    /**
     Create a new instance of the object using the supplied node
     
     - Parameter node: The node to use to populate the fields of the type
    */
    init(with node:AbstractSyntaxTreeNode, from source:String) throws
}

/**
 An entry in the tree.
 */
public struct AbstractSyntaxTreeNode : Node {
    /// The token created
    public      let token       : Token
    /// The range of the match in the source string
    public      let range       : Range<String.UnicodeScalarView.Index>
    
    /// Children of this node
    public      let children       : [AbstractSyntaxTreeNode]
    
    /// Any associated annotations made on the `token`
    public      let annotations: [RuleAnnotation : RuleAnnotationValue]
    
    /**
     Creates a new instance with no `value`
     
     -Parameter for: The `Token` the node captures
     -Parameter at: The range the token was matched at in the original source string
     -Prameter annotations: Any annotations that should be stored with the node
     */
    public init(for token: Token, at range: Range<String.UnicodeScalarView.Index>, annotations:RuleAnnotations) {
        self.token = token
        self.range = range
        self.children = []
        self.annotations = annotations
    }
    
    /**
     Creates a new instance
     
     -Parameter for: The `Token` the node captures
     -Parameter at: The range the token was matched at in the original source string
     -Parameter children: Any child nodes of this node
     -Prameter annotations: Any annotations that should be stored with the node
     */
    public init(for token: Token, at range: Range<String.UnicodeScalarView.Index>, children:[AbstractSyntaxTreeNode], annotations:RuleAnnotations) {
        self.token = token
        self.range = range
        self.children = children
        self.annotations = annotations
    }
}

/**
 An abstract syntax tree allows you to build a data structure from the results of parsing. The root element must be parsable.
 */
public final class AbstractSyntaxTreeConstructor<RootNode : Parsable>  {
    /// The original source string
    private let     source    : String
    
    /// The original scalars view
    private let     scalars   : String.UnicodeScalarView
    
    /// The context stack of nodes
    private var     nodeStack = NodeStack<AbstractSyntaxTreeNode>()
    
    /// The _errors collected during parsing
    private var     _errors     = [Error]()
    
    /// The errors generated during parsing
    public  var     errors : [Error] {
        return _errors
    }
    
    public init(){
        fatalError("TODO: This requirement for an IR should be removed")
    }

    /// Creates a new instance, preparing to parse the supplied source
    public init(with source:String){
        self.source  = source
        self.scalars = source.unicodeScalars
    }
    
    /**
     Parses the source supplied at initialization with supplied language, returning an instance of `RootNode`
     
     - Parameter language: The language to use to parse the source
     - Parameter lexer: An optional special lexer instance to use. This must be initialized with the same string as the AST
     - Returns: An instance of RootNode or nil (in which case callers should user the errors property to determine the cause of the problems
    */
    public func parse(using language:Language, andLexicalAnalyzer lexer:LexicalAnalyzer? = nil)->RootNode?{
        let _ = language.build(intermediateRepresentation: self, using: lexer ?? Lexer(source: source))
        
        do {
            let topNode : AbstractSyntaxTreeNode

            guard let topNodes = nodeStack.top?.nodes, topNodes.count > 0 else {
                _errors.append(LanguageError.parsingError(at: scalars.startIndex..<scalars.startIndex, message: "No nodes created"))
                return nil
            }

            if topNodes.count > 1 {
                // Wrap it in a single node
                topNode = AbstractSyntaxTreeNode(for: transientTokenValue.token, at: topNodes.combinedRange, annotations: [:])
            } else {
                topNode = topNodes[0]
            }
            return try RootNode(with: topNode, from: source)
        } catch {
            _errors.append(error)
        }
        
        return nil
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
    
    /// Does nothing
    public func willEvaluate(rule: Rule, at position: String.UnicodeScalarView.Index) -> MatchResult? {
        nodeStack.push()
    
        return nil
    }
    
    public func didEvaluate(rule: Rule, matchResult: MatchResult) {
        let children = nodeStack.pop()
        
        switch matchResult {
        case .success(let context):
            //If the rule is void return nothing
            if rule.void {
                return
            }
            
            // If it's transient, or the constructor produces no nodes then the current top should adopt the children
            /// TODO: Is this a defect (see github issue 24 https://github.com/SwiftStudies/OysterKit/issues/24)
            guard let node = rule.transient ? nil : match(token: rule.produces, annotations: rule.annotations, context: context, children: children.nodes) else {
                nodeStack.top?.adopt(children.nodes)
                return
            }
            
            nodeStack.top?.append(node)
        case .ignoreFailure(let index):
            if let node = ignoreableFailure(token: rule.produces, annotations: rule.annotations, index: index){
                nodeStack.top?.append(node)
            } else {
                nodeStack.top?.adopt(children.nodes)
            }
        case .failure(let index):
            //If we have an error on the rule
            if let error = rule.error {
                let errorEnd = scalars.index(after:index)
                let parsingError = LanguageError.parsingError(at: index..<errorEnd, message: error)
                
                let existing = _errors.flatMap({ (error)->Error? in
                    if let error = error as? LanguageError {
                        if error == parsingError {
                            return error
                        }
                    }
                    return nil
                })
                
                if existing.count == 0{
                    _errors.append(parsingError)
                }
                
            }
            failed(token: rule.produces)
        case .consume:
            break
        }
    }
    
    public func didBuild() {
        
    }
    
    public func resetState() {
        
    }
    
    /**
     If the token is transient `nil` is returned. Otherwise the behaviour is determined by the number of children
     
     - 0: A new instance of `HeterogeneousNode` is created and returned
     - 1: Providing the token is not @pin'd a new `HeterogeousNode` is created for the child's range and value and returned If it is @pin'd behaviour falls through to
     - _n_: Return a new `HeterogeneousNode` with the combined range of all children and the children are set as the node's value
     
     - Parameter token: The token that has been successfully identified in the source
     - Parameter annotations: The annotations that had been marked on this instance of the token
     - Parameter context: The `LexicalContext` from the `LexicalAnalyzer` from which an implementation can extract the matched range.
     - Parameter children: Any `Node`s that were created while this token was being evaluated.
     - Returns: Any `Node` that was created, or `nil` if not
     */
    final public func match(token: Token, annotations:RuleAnnotations, context: LexicalContext, children: [AbstractSyntaxTreeNode]) -> AbstractSyntaxTreeNode? {
        guard !token.transient else {
            return nil
        }
        
        switch children.count{
        case 0:
            return AbstractSyntaxTreeNode(for: token, at: context.range,  annotations: annotations)
        case 1:
            if children[0].annotations[RuleAnnotation.pinned] == nil {
                return AbstractSyntaxTreeNode(for: token, at: children[0].range, children: children[0].children, annotations: annotations)
            }
            fallthrough
        default:
            return AbstractSyntaxTreeNode(for: token, at: children.combinedRange, children: children, annotations: annotations)
        }
    }
    
    /**
     If the token is not transient but is pinned a node is created with a range at the current scan-head but no value. Otherwise `nil` is returned.
     
     - Parameter token: The token that failed to be matched identified in the source
     - Parameter annotations: The annotations that had been marked on this instance of the token
     - Returns: Any `Node` that was created, or `nil` if not
     */
    public func ignoreableFailure(token: Token, annotations: [RuleAnnotation : RuleAnnotationValue], index: String.UnicodeScalarView.Index)->AbstractSyntaxTreeNode? {
        if !token.transient && annotations[RuleAnnotation.pinned] != nil{
            let range = index..<index
            return AbstractSyntaxTreeNode(for: token, at: range, annotations: annotations)
        }
        return nil
    }
    
    /// No behaviour
    public func failed(token: Token) {
        
    }
}

/// A standard Homogenous Abstract Syntax Tree constructor
public typealias HomogenousAbstractSyntaxTreeConstructor = AbstractSyntaxTreeConstructor<HomogenousTree>
