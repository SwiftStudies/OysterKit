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

public final class DefaultHeterogenousConstructor : ASTNodeConstructor{
    public typealias NodeType =  HeterogeneousNode
    
    public init(){
        
    }
    
    public func begin(with source: String) {
        
    }
    
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

    public func ignoreableFailure(token: Token, annotations: [RuleAnnotation : RuleAnnotationValue], index: String.UnicodeScalarView.Index)->HeterogeneousNode? {
        if !token.transient && annotations[RuleAnnotation.pinned] != nil{
            let range = index..<index
            return HeterogeneousNode(for: token, at: range, annotations: annotations)
        }
        return nil
    }

    
    public func failed(token: Token) {
        
    }
    
    public func complete(parsingErrors: [Error]) -> [Error] {
        return parsingErrors
    }
}

public typealias DefaultHeterogeneousAST = HeterogenousAST<HeterogeneousNode,DefaultHeterogenousConstructor>

public final class HeterogenousAST<NodeType : ValuedNode, Constructor : ASTNodeConstructor> : HomogenousAST<NodeType,Constructor> where Constructor.NodeType == NodeType{
    
}


