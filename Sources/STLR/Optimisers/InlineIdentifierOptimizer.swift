//
//  InlineIdentifierOptimization.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

public struct InlineIdentifierOptimization : STLRExpressionOptimizer{
    private typealias Quantifier           = STLRScope.Modifier
    private typealias Element              = STLRScope.Element
    private typealias Expression           = STLRScope.Expression
    private typealias TerminalCharacterSet = STLRScope.TerminalCharacterSet
    private typealias Terminal             = STLRScope.Terminal
    
    public init(){
    }

    private func optimize(element: Element) -> Element? {
        // These are normally important so do not optimize them
        if element.quantifier == Quantifier.zeroOrOne {
            return nil
        }
        if case .identifier(let identifier, let originalQuantifier,let lookahead,let originalAnnotations) = element , lookahead == false{
            guard let expression = identifier.grammarRule?.expression else {
                return nil
            }
            if case .element(let element) = expression{
                if case .terminal(let terminal, let quantifier,let lookahead,let annotations) = element , quantifier == .one && lookahead == false && annotations.count == 0{                    
                    return Element(terminal, originalQuantifier, identifier.annotations.merge(with: originalAnnotations))
                }
            }
        }
        
        return nil
    }
    
    private func optimize(elements: [Element]) -> [Element]? {
        var newElements = [Element]()
        var changed     = false
        
        for element in elements{
            if let newElement = optimize(element: element) {
                newElements.append(newElement)
                changed = true
            } else {
                newElements.append(element)
            }
        }
        
        return changed ? newElements : nil
    }
    
    
    public func optimize(expression: STLRScope.Expression) -> STLRScope.Expression? {
        switch expression {
        case .element(let element):
            if let element = optimize(element: element){
                return Expression.element(element)
            }
        case .choice(let elements):
            if let elements = optimize(elements: elements) {
                return Expression.choice(elements)
            }
        case .sequence(let elements):
            if let elements = optimize(elements: elements) {
                return Expression.sequence(elements)
            }
        case .group:
            break
        }

        //Give up
        return nil
    }
    
    
    
    public var description: String{
        return "Inlines identifiers in containing expressions where possible"
    }
}
