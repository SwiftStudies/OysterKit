//
//  HeterogenousAST.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

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


