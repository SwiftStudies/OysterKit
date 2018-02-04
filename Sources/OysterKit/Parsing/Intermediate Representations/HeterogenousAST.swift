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
 Provides a default implementation of an `ASTNodeConstructor` that is expected to construct nodes that can have different fundamental data types. All nodes
 are of type `HeterogeneousNode`.
*/
@available(*, deprecated, message: "Use AbstractSyntaxTree() instead")
public final class DefaultHeterogenousConstructor : ASTNodeConstructor{
    /// All nodes must conform to the protocol `HeterogeneousNode`
    public typealias NodeType =  HeterogeneousNode
    
    /// Create a new instance of the constructor
    public init(){
        
    }
    
    /**
     Does nothing
     
     - Parameter with: The source `String` being parsed
     */
    public func begin(with source: String) {
        
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
    final public func match(token: Token, annotations:RuleAnnotations, context: LexicalContext, children: [HeterogeneousNode]) -> HeterogeneousNode? {
        guard !token.transient else {
            return nil
        }
        
        switch children.count{
        case 0:
            return HeterogeneousNode(for: token, at: context.range,value:nil,  annotations: annotations)
        case 1:
            if children[0].annotations[RuleAnnotation.pinned] == nil {
                return HeterogeneousNode(for: token, at: children[0].range, value: children[0].value, annotations: annotations)
            }
            fallthrough
        default:
            return HeterogeneousNode(for: token, at: children.combinedRange, value: children, annotations: annotations)
        }
        
    }

    /**
     If the token is not transient but is pinned a node is created with a range at the current scan-head but no value. Otherwise `nil` is returned.
     
     - Parameter token: The token that failed to be matched identified in the source
     - Parameter annotations: The annotations that had been marked on this instance of the token
     - Returns: Any `Node` that was created, or `nil` if not
     */
    public func ignoreableFailure(token: Token, annotations: [RuleAnnotation : RuleAnnotationValue], index: String.UnicodeScalarView.Index)->HeterogeneousNode? {
        if !token.transient && annotations[RuleAnnotation.pinned] != nil{
            let range = index..<index
            return HeterogeneousNode(for: token, at: range, annotations: annotations)
        }
        return nil
    }

    /// No behaviour
    public func failed(token: Token) {
        
    }

    /**
     Returns the supplied errors without modification
     
     -Parameter parsingErrors: The errors created during parsing
     -Returns: A potentially modified `Array` of errors.
     */
    public func complete(parsingErrors: [Error]) -> [Error] {
        return parsingErrors
    }
}

/// The default implementation of a `HeterogenousAST` using the `DefaultHeterogenousConstructor`
@available(*, deprecated, message: "Use AbstractSyntaxTree() instead")
public typealias DefaultHeterogeneousAST = HeterogenousAST<HeterogeneousNode,DefaultHeterogenousConstructor>

/// The base class for any 'HeterogenousAST'
@available(*, deprecated, message: "Use AbstractSyntaxTree() instead")
public final class HeterogenousAST<NodeType : ValuedNode, Constructor : ASTNodeConstructor> : HomogenousAST<NodeType,Constructor> where Constructor.NodeType == NodeType{
    
}


