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
 An extension of the base `Node` type used by the standard ASTs that supports values of type `Any`. This is used primarily by `HeterogeousAST`s
 */
@available(*, deprecated, message: "Use AbstractSyntaxTree() instead")
public protocol ValuedNode : Node {
    /**
     Create a new instance
     
     -Parameter for: The `Token` the node captures
     -Parameter at: The range the token was matched at in the original source string
     -Parameter value: The value, if any
     -Prameter annotations: Any annotations that should be stored with the node
    */
    init(`for` token:Token, at range:Range<String.UnicodeScalarView.Index>, value :Any?, annotations:RuleAnnotations)

    /// The value associated with the Node
    var value : Any? { get }
}

/// A set of extensions to the `ValuedNode` protocol to provide default behaviour
@available(*, deprecated, message: "Use AbstractSyntaxTree() instead")
public extension ValuedNode{
    
    /// A human readable description of the node
    public var description: String{
        return "\(token):\(value ?? "nil")"
    }
    
    /**
     Casts the node's value to the receiving data type. For example:
     
             guard let value : Int = valuedNode.cast() else {
                fatalError("Expected the value of \(node) to be an Int")
             }
     
     - Returns: The value as type `N`
    */
    public func cast<N>()->N?{
        return value as? N
    }
    
    /**
     If the value is an array of child nodes, and a child node exists with the specified token, returns that node. If more than
     one child has that token, the first is returned.
     
     - Parameter token: The `Token` to retreive
     - Returns: The requested `Token` or `nil`
     */
    public subscript(_ token:Token)->Self?{
        if let children : [Self] = cast() {
            return children[token]?.cast()
        }
        
        return nil
    }
    
    /**
     If the value is an array of child nodes, and a child node exists at the specified index, returns that node
     
     - Parameter token: The index of the child to retreive
     - Returns: The requested `Token` or `nil`
     */
    public subscript(_ index:Int)->Self?{
        if let children : [Self] = cast(){
            if children.count > index && index >= 0{
                return children[index]
            }
            
            return nil
        }
        
        if index == 0 {
            return value as? Self
        }
        
        return nil
    }

}

/// An extension for any collection containing a `ValuedNode`
@available(*, deprecated, message: "Use AbstractSyntaxTree() instead")
public extension Collection where Iterator.Element : ValuedNode {
    
    /**
     Returns the first node with the specified `token`, if any.
     
     - Parameter token: The desired token
     - Returns: The `ValuedNode` or `nil` if none exists
    */
    public subscript(token:Token)->ValuedNode?{
        let allMatches = flatMap({ (match)->ValuedNode? in
            return match.token == token ? match : nil
        })
        
        switch allMatches.count {
        case 0:
            return nil
        case 1:
            return allMatches[0]
        default:
            let finalRange = reduce(first!.range, { (rangeSoFar, nextChild) -> Range<String.UnicodeScalarView.Index> in
                let lowerBound = rangeSoFar.lowerBound < nextChild.range.lowerBound ? rangeSoFar.lowerBound : nextChild.range.lowerBound
                let upperBound = rangeSoFar.upperBound > nextChild.range.upperBound ? rangeSoFar.upperBound : nextChild.range.upperBound
                
                return lowerBound..<upperBound
            })
  
            
            return Iterator.Element(for: token, at: finalRange, value: allMatches, annotations: [:])
        }
    }
    
    /**
     Returns the value of first element found with the specified token providing it can be cast to the receiving return type.
     
     - Paramaeter token: The desired token
     - Returns: The value or `nil` if no element with the token was found or the value cannot be cast
    */
    public func child<N>(token:Token)->N?{
        for child in self{
            if child.token == token {
                return child.cast()
            }
        }
        
        return nil
    }
}

/**
 The default implementation of `ValuedNode`.
 */
@available(*, deprecated, message: "Use AbstractSyntaxTree() instead")
public struct HeterogeneousNode : ValuedNode {
    /// The token created
    public      let token       : Token
    /// The range of the match in the source string
    public      let range       : Range<String.UnicodeScalarView.Index>
    
    /// The (opitional) value.
    public      let value       : Any?
    
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
        self.value = nil
        self.annotations = annotations
    }

    /**
     Creates a new instance
     
     -Parameter for: The `Token` the node captures
     -Parameter at: The range the token was matched at in the original source string
     -Parameter value: The value, if any
     -Prameter annotations: Any annotations that should be stored with the node
     */
    public init(for token: Token, at range: Range<String.UnicodeScalarView.Index>, value:Any?, annotations:RuleAnnotations) {
        self.token = token
        self.range = range
        self.value = value
        self.annotations = annotations
    }
    
}
