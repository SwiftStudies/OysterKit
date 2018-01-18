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
 `ASTNodeConstructor`s are responsible for building the data-structures used by the default homogenous and heterogenous `IntermediateRepresentations`. They
  allow you to, by providing your own implementations, control the behaviour of `Node` creation of those default implementations.
 */
public protocol ASTNodeConstructor{
    // The type of Node that the the implementation manages
    associatedtype  NodeType : Node
    
    // Create a new instance of the constructor
    init()
    
    /**
     Called when parsing begins so the implementer can prepare any data structures
     
     - Parameter with: The source `String` being parsed
    */
    func begin(with source:String)
    
    /**
     Called when a rule has matched and a `Node` for the token could be created
     
     - Parameter token: The token that has been successfully identified in the source
     - Parameter annotations: The annotations that had been marked on this instance of the token
     - Parameter context: The `LexicalContext` from the `LexicalAnalyzer` from which an implementation can extract the matched range.
     - Parameter children: Any `Node`s that were created while this token was being evaluated.
     - Returns: Any `Node` that was created, or `nil` if not
    */
    func match(token:Token, annotations:[RuleAnnotation:RuleAnnotationValue], context: LexicalContext, children: [NodeType])->NodeType?
    
    /**
    Called when a rule has failed, but the failure is ignorable (it was optional) and a `Node` for the token could be created
     
     - Parameter token: The token that failed to be matched identified in the source
     - Parameter annotations: The annotations that had been marked on this instance of the token
     - Returns: Any `Node` that was created, or `nil` if not
     */
    func ignoreableFailure(token:Token, annotations:[RuleAnnotation:RuleAnnotationValue], index: String.UnicodeScalarView.Index)->NodeType?

    /**
     Called when a rule has failed
     
     - Parameter token: The token that failed to be matched in the source
     */
    func failed(token:Token)
    
    /**
     Called when parsing is complete. Any generated errors are supplied.
     
     -Parameter parsingErrors: The errors created during parsing
     -Returns: A potentially modified `Array` of errors.
    */
    func complete(parsingErrors: [Error])->[Error]
}

/**
 A default constructor implementation which can be specialised for specific node types.
*/
final class DefaultConstructor<N:Node> : ASTNodeConstructor{
    /// The `Node` implementation to be used
    typealias NodeType = N
    
    /// Creates a new instance of the constructor
    init(){
        
    }
    
    /**
     If the supplied `token` is transient no `Node` will be created and all `children` will be discarded.
     Then depending on the number of children different behaviours are applied:
     
        - 0 Children: A new node is created
        - 1 Child: If this Child is not pinned the range of all child matches and this match are combined, and a new node is returned with the supplied `token`. If it is pinned then a new node is returned with the child`s range and the supplied `token`
        - N Children: A new node is returned with the combined range of all children and the supplied `token`
     
     - Parameter token: The matched token
     - Parameter annotations: Any annotations on the token
     - Parameter context: The `LexicalContext` for the matched rule
     - Parameter children: Any child `Node`s that were matched in sub-rules of the rule that created the `token`
     - Return if required (see above) the created `Node`
    */
    final func match(token: Token, annotations:[RuleAnnotation:RuleAnnotationValue], context: LexicalContext, children: [N]) -> N? {
        guard !token.transient else {
            return nil
        }
        
        switch children.count{
        case 0:
            return N(for: token, at: context.range, annotations: annotations)
        case 1:
            if children[0].annotations[.pinned] == nil{
                return N(for: token, at: children[0].range, annotations: annotations)
            }
            fallthrough
        default:
            return N(for: token, at: children.combinedRange, annotations: annotations)
        }
        
    }
    
    /**
     Only returns a `Node` if the `token` is not transient and _is_ pinned. If so a `Node` is created with the supplied data.
     
     - Parameter token: The matched token
     - Parameter annotations: Any annotations on the token
     - Parameter context: The `LexicalContext` for the matched rule
     - Returns `nil` unless the requirements above are met
     */
    final func ignoreableFailure(token: Token, annotations: [RuleAnnotation : RuleAnnotationValue], index: String.UnicodeScalarView.Index)->N? {
        if !token.transient && annotations[RuleAnnotation.pinned] != nil{
            let range = index..<index
            return N(for: token, at: range, annotations: annotations)
        }
        return nil
    }

    /// Does nothing
    final internal func failed(token: Token){
    }
    
    /// Returns the supplied errors
    /// - Parameter parsingErrors: The errors generated during parsing
    /// - Return: The value of the `parsingErrors` parameter
    final internal func complete(parsingErrors: [Error]) -> [Error] {
        return parsingErrors
    }
    
    /// Does nothing
    final internal func begin(with source: String) {
        
    }
}

/// A default concrete implementation of a `HomogenousAST` which uses the `DefaultConstructor`
final public class DefaultHomogenousAST<NodeType:Node> : HomogenousAST<NodeType, DefaultConstructor<NodeType>>{
    required public init() {
        super.init()
    }
}

/**
 HomogenousAST is an `InternalRepresenation` which uses an instance of `ASTNodeConstructor` to build its AST. Each node
 is off the same type.
 
 -SeeAlso: DefaultHomogenousAST<NodeType:Node> which provides a default implementation using `DefaultConstructor<NodeType:Node>`
 */
public class HomogenousAST<NodeType, Constructor : ASTNodeConstructor> : IntermediateRepresentation where Constructor.NodeType == NodeType{
    /// The original scalars view
    private var     scalars   : String.UnicodeScalarView!
    
    /// The context stack of nodes
    private var     nodeStack = NodeStack<NodeType>()
    
    /// The _errors collected during parsing
    private var     _errors     = [Error]()
    
    /// The constructor used to create `Node`s of `NodeType`
    public  let     constructor : Constructor
    
    /// The errors generated during parsing
    public  var     errors : [Error] {
        return _errors
    }
    
    /// The top-level children of the AST
    /// SeeAlso: `tokens`
    var     children  : [NodeType]{
        return nodeStack.top?.nodes ?? []
    }
    
    /// The top-level children of the AST
    /// SeeAlso: `tokens`
    public var tokens : [NodeType]{
        return children
    }
    
    /// Creates a new instance
    public required init(){
        constructor = Constructor()
    }
    
    /**
     Creates a new instance with the supplied `Constructor`
     
     -Parameters constructor: A preinitialized constructor
    */
    public init(constructor:Constructor) {
        self.constructor = constructor
    }
    
    
    /// Completely resets the state of the AST removing all generated structure and errors
    final public func resetState() {
        nodeStack.reset()
        _errors.removeAll()
    }
    
    /**
     Resets the state of the AST and signals to the constructor that parsing is about to begin
     
     -Parameter source: The `String` to be parsed.
     -Parameter with: The `Language` to be used to parse with.
    */
    final public func willBuildFrom(source: String, with: Language) {
        scalars = source.unicodeScalars
        constructor.begin(with: source)
        resetState()
    }
    
    /**
     Errors generated captured during parsing are passed to the `ASTNodeConstructuro` for processing and made available through the `errors` property.
    */
    final public func didBuild() {
        _errors = constructor.complete(parsingErrors: _errors)
    }
    
    /**
     Adds a new context to the node stack
     
     - Parameter rule: The `Rule` that will be evaluated
     - Parameter at: The position in the source of the scan-head
     - Returns: A pre-existing `MatchResult` if known for this rule at this position, or `nil` if evaluation should proceed
     */
    final public func willEvaluate(rule: Rule, at position:String.UnicodeScalarView.Index)->MatchResult?{
        nodeStack.push()
        return nil
    }
    
    /**
     Based on `matchResult` it will pop the topmost item from the nodeStack (gathering all children) and then:
     
     * `.success`: If the rule is `void` (see @void annotation) no action will be taken. Otherwise if the token is not transient (see @transient) and the `ASTNodeConstructor` returns a new Node that node will be added to children of the new top of the node stack. If no `Node` is created or the `token` is @transient the new top of the node stack will adopt the children of the previous top (hoisting)
     * `.ignoreFailure`: If this constructor creates a node (for example because the token is @pin'd) the new node is added to the children of the nodestack top. Otherwise the children are adopted by the current node stack top.
     * `.failure`: If existing `LanguageError`s then they are flushed and the new `ParsingError` is appended to the `errors` for the AST. The `ASTConstructor.failure()` is called.
     * `.consume`: Nothing is done
     
     - Parameter rule: The `Rule` that has been evaluated
     - Parameter matchResult: The result of the evaluation
     */
    final public func didEvaluate(rule: Rule, matchResult: MatchResult) {
        let children = nodeStack.pop()
        
        switch matchResult {
        case .success(let context):
            //If the rule is void return nothing
            if rule.void {
                return
            }
            
            // If it's transient, or the constructor produces no nodes then the current top should adopt the children
            /// TODO: Is this a defect (see github issue 24 https://github.com/SwiftStudies/OysterKit/issues/24)
            guard let node = rule.transient ? nil : constructor.match(token: rule.produces, annotations: rule.annotations, context: context, children: children.nodes) else {
                nodeStack.top?.adopt(children.nodes)
                return
            }
            
            nodeStack.top?.append(node)
        case .ignoreFailure(let index):
            if let node = constructor.ignoreableFailure(token: rule.produces, annotations: rule.annotations, index: index){
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
            constructor.failed(token: rule.produces)
        case .consume:
            break
        }
    }
    
    /**
     Produces a description of a `NodeStackEntry<NodeType` that can be displayed to a user
     
     - Parameter entry: The entry to describe
     - Returns: A String containing a description of the entry
    */
    private func describe(entry:NodeStackEntry<NodeType>)->String{
        var result = ""
        
        result += entry.nodes.map({ (entry)->String in
            return "entry.description"
        }).joined(separator: ", ")
        
        return "[\(result)]"
    }
    
    /// Provides a human readable description of the AST
    public var description: String{
        var result = ""
        for entry in nodeStack.all {
            result += describe(entry: entry)
        }
        
        return result
    }
    
    
}
