//
//  STLR Constructor.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

extension STLRIntermediateRepresentation : ASTNodeConstructor {
    public typealias NodeType = HeterogeneousNode
    
    public func begin(with source: String) {
        
    }
    
    private func createElement(from node:ValuedNode, _ quantifier:Modifier, _ lookahead:Bool, _ annotations: ElementAnnotations)->Element{
        if let terminal : STLRIntermediateRepresentation.Terminal = node.cast(){
            return Element.terminal(terminal, quantifier, lookahead, annotations)
        } else if let identifier : STLRIntermediateRepresentation.Identifier = node.cast(){
            return Element.identifier(identifier, quantifier, lookahead, annotations)
        } else if let expression : STLRIntermediateRepresentation.Expression = node.cast(){
            return Element.group(expression, quantifier, lookahead, annotations)
        } else {
            fatalError("Element should be a terminal, identifier, or group")
        }
    }
    
    
    public func match(token: Token, annotations: [RuleAnnotation : RuleAnnotationValue], context: LexicalContext, children: [HeterogeneousNode]) -> HeterogeneousNode? {
        guard let token = token as? STLR, !token.transient else {
            return nil
        }
        
        let matchRange = children.count > 0 ? children.combinedRange : context.range
        
        switch token{
        // These can just have their children hoisted
        case .whitespace, .comment, .grammar, .then, .or, .stringCharacter, .terminalString, .string, .definedLabel, .characterSet, .lhs:
            return nil
        case .group:
            guard let child = children[STLR.expression] else {
                fatalError("Groups must have an expression")
            }
            
            return HeterogeneousNode(for: token, at: matchRange, value: child.value, annotations: [:])
        case .expression:
            guard children.count == 1 else {
                fatalError("Expressions should have exactly one child")
            }
            
            // If it's already an expression, do nothing
            if let _ : Expression = children[0].cast() {
                return nil
            }
            
            guard let element : Element = children[0].cast() else {
                fatalError("Expression expects an element")
            }
            
            return HeterogeneousNode(for: token, at: matchRange, value: Expression.element(element), annotations: [:])
        case .rule:
            
            var annotations : ElementAnnotations    = children[STLR.annotations]?.cast() ?? []
            let transient   : Bool                  = children[STLR.transient]?.cast()   ?? false
            guard let identifier  : STLRIntermediateRepresentation.Identifier = children[STLR.identifier]?.cast() else {
                fatalError("Rules must have an identifier")
            }
            
            if transient && annotations[annotation: ElementAnnotation.transient] == nil {
                annotations.append(ElementAnnotationInstance(ElementAnnotation.transient, value: ElementAnnotationValue.set))
            }
            
            let rule : GrammarRule
            if identifier.grammarRule == nil {
                rule = GrammarRule(self, range: context.range)
                identifier.grammarRule = rule
                rule.identifier = identifier
            } else {
                rule = identifier.grammarRule!
            }
            
            guard let child = children[STLR.expression] ?? children[STLR.element] else {
                fatalError("No element or expression specified in \(children)")
            }

            
            if let expression:STLRIntermediateRepresentation.Expression = child.cast(){
                rule.expression = expression
            } else if let element:STLRIntermediateRepresentation.Element = child.cast(){
                rule.expression = Expression.element(element)
            }
            
            for annotation in annotations {
                if identifier.annotations[annotation: annotation.annotation] != nil {
                    errors.append(LanguageError.warning(at: identifier.references[0], message: "\(identifier.name) has overlapping annotations"))
                }
                
                identifier.annotations.append(annotation)
            }
            
            rules.append(rule)
            return HeterogeneousNode(for: token, at: matchRange, value: rule, annotations: [:])
        case .characterRange:
            guard let lowerString : String = children[0].cast() else {
                fatalError("Character range requires a lower bound")
            }
            guard let upperString : String = children[1].cast() else {
                fatalError("Character range requires an upper bound")
            }
            
            let lower = lowerString.unicodeScalars.first!
            let upper = upperString.unicodeScalars.first!
            
            if upper<lower{
                return HeterogeneousNode(for: STLR.characterSet, at: matchRange, value: TerminalCharacterSet.customRange(CharacterSet(charactersIn: upper...lower), start: upper, end: lower), annotations: [:])
            }
            
            return HeterogeneousNode(for: STLR.characterSet,at: matchRange , value: TerminalCharacterSet.customRange(CharacterSet(charactersIn: lower...upper), start: lower, end: upper), annotations: [:])
        case .element:
            //Newer, cleaner, more robust syntax for accessing AST
            var annotations : ElementAnnotations    = children[STLR.annotations]?.cast() ?? []
            let lookahead   : Bool                  = children[STLR.lookahead]?.cast() ?? false
            let transient   : Bool                  = children[STLR.transient]?.cast() ?? false
            var negated     : Modifier            = children[STLR.negated]?.cast() ?? .one
            var quantifier  : Modifier            = children[STLR.quantifier]?.cast() ?? .one
            
            guard let elementChild = children[STLR.terminal] ?? children[STLR.group] ?? children[STLR.identifier] else {
                fatalError("No element specified in \(children)")
            }
            
            //If there is no specific annotation and a transient mark (~) was given then create an annotation for it
            if transient && annotations[annotation: ElementAnnotation.transient] == nil{
                annotations.append(ElementAnnotationInstance(ElementAnnotation.transient, value: ElementAnnotationValue.set))
            }
            
            //If we can shunt the negation into the quantifier
            if quantifier == .one  {
                quantifier = negated
                negated = .one
            }
            
            var element : Element
            
            if let inlineIdentifier = annotations[annotation: ElementAnnotation.token], case let ElementAnnotationValue.string(stringValue) = inlineIdentifier {
                var identifier : Identifier
                
                if let existingIdentifier = identifiers[stringValue] {
                    identifier = existingIdentifier
                } else {
                    identifier = getIdentifier(named: stringValue, at: context.range)
                    
                    // This is a copy from rule and should be refactored into a common sub-method
                    let rule : GrammarRule
                    if identifier.grammarRule == nil {
                        rule = GrammarRule(self, range: context.range)
                        identifier.grammarRule = rule
                        rule.identifier = identifier
                        
                        //This may be a bug in rule definition too
                        rules.append(rule)
                    } else {
                        rule = identifier.grammarRule!
                    }
                    
                    rule.expression = Expression.element(createElement(from: elementChild, quantifier, lookahead, []))
                    
                    for annotation in annotations.remove(ElementAnnotation.token) {
                        if identifier.annotations[annotation: annotation.annotation] != nil {
                            errors.append(LanguageError.warning(at: identifier.references[0], message: "\(identifier.name) has overlapping annotations"))
                        }
                        
                        identifier.annotations.append(annotation)
                    }
                }
                
                //Finally create a new element as if they had always referenced the identifier here
                annotations = []
                element = Element.identifier(identifier, .one, false, [])
            } else {
                //Wrap elements with negation AND another quantifier in a group
                if negated != .one && quantifier != .one {
                    //Wrap in a lookahead group
                    element = Element.group(
                        Expression.element(
                            createElement(from: elementChild, negated, false, [])
                        ), quantifier, lookahead, annotations)
                } else {
                    element = createElement(from: elementChild, quantifier, lookahead, annotations)
                }
            }
            

            
            //Wrap elements with lookahead AND a quantifier in a group
            if quantifier != .one && lookahead {
                //Change the lookahead setting on the element
                element.setLookahead(lookahead: false)
                
                //Wrap in a lookahead group
                element = Element.group(Expression.element(element), Modifier.one, true, annotations)
            }
            
            return HeterogeneousNode(for: token,at: matchRange , value: element, annotations: [:])
        case .sequence, .choice:
            //Only worry here is that there is always more than one element, but I believe that to be the case
            guard let elementNodes : [HeterogeneousNode] = children[STLR.element]?.cast() else {
                fatalError("No elements")
            }
            
            let elements = elementNodes.flatMap({ (elementNode)->STLRIntermediateRepresentation.Element? in
                return elementNode.cast()
            })
            
            
            if case .sequence = token {
                return HeterogeneousNode(for: STLR.expression,at: matchRange , value: STLRIntermediateRepresentation.Expression.sequence(elements), annotations: [:])
            } else {
                return HeterogeneousNode(for: STLR.expression,at: matchRange , value: STLRIntermediateRepresentation.Expression.choice(elements), annotations: [:])
            }
        case .characterSetName:
            switch context.matchedString {
            case "backslash":
                return HeterogeneousNode(for: STLR.terminal, at: matchRange, value: STLRIntermediateRepresentation.Terminal(with:"\\\\"), annotations: [:])
            default:
                let characterSet = STLRIntermediateRepresentation.TerminalCharacterSet(rawValue:context.matchedString) ?? STLRIntermediateRepresentation.TerminalCharacterSet.customString("")
                return HeterogeneousNode(for: STLR.characterSet,at: matchRange , value: characterSet, annotations: [:])
            }
        case .terminal:
            switch children[0].token as? STLR ?? STLR._transient {
            case .characterSet:
                guard let characterSet : STLRIntermediateRepresentation.TerminalCharacterSet = children[0].cast() else {
                    fatalError("Expected a TerminalCharacterSet")
                }
                return HeterogeneousNode(for: STLR.terminal,at: matchRange , value: STLRIntermediateRepresentation.Terminal(with: characterSet), annotations: [:])
            case .stringBody:
                guard let string : String = children[0].cast() else {
                    fatalError("Expected a string")
                }
                return HeterogeneousNode(for: STLR.terminal,at: matchRange , value: STLRIntermediateRepresentation.Terminal(with: string), annotations: [:])
            default:
                return nil
            }
        case .identifier:
            return HeterogeneousNode(for: token,at: matchRange , value: getIdentifier(named: context.matchedString, at: context.range), annotations: [:])
        case .lookahead, .transient:
            return HeterogeneousNode(for: token,at: matchRange , value: true, annotations: [:])
        case .negated:
            return HeterogeneousNode(for: token,at: matchRange , value: STLRIntermediateRepresentation.Modifier(from: context.matchedString), annotations: [:])
        case .quantifier:
            return HeterogeneousNode(for: token,at: matchRange , value: STLRIntermediateRepresentation.Modifier(from: context.matchedString), annotations: [:])
        case .annotations:
            let annotations = children.map({ (child)->ElementAnnotationInstance in
                guard let annotation : ElementAnnotationInstance = child.cast() else {
                    fatalError("Annotations must all be ElementAnnotationInstances")
                }
                
                return annotation
            })
            
            return HeterogeneousNode(for: token,at: matchRange , value: annotations, annotations: [:])
        case .annotation:
            guard let annotation : ElementAnnotation = children[0].cast() else {
                fatalError("Annotations must have a label")
            }
            
            var value : ElementAnnotationValue?
            
            if children.count > 1 {
                if let annotationValue : ElementAnnotationValue = children[1].cast() {
                    value = annotationValue
                }
            }
            
            return HeterogeneousNode(for: token,at: matchRange , value: ElementAnnotationInstance(annotation, value: value ?? ElementAnnotationValue.set), annotations: [:])
        case .literal:
            guard !children.isEmpty else {
//                print("Serious Error: Expected a value")
                return HeterogeneousNode(for: token, at: matchRange, value: ElementAnnotationValue.set, annotations: [:])
            }
            if let value : Bool = children[0].cast() {
                return HeterogeneousNode(for: token,at: matchRange , value: ElementAnnotationValue.bool(value), annotations: [:])
            } else if let value : Int = children[0].cast() {
                return HeterogeneousNode(for: token,at: matchRange , value: ElementAnnotationValue.int(value), annotations: [:])
            } else if let value : String = children[0].cast(){
                return HeterogeneousNode(for: token,at: matchRange , value: ElementAnnotationValue.string(value), annotations: [:])
            } else {
                fatalError("Unknown literal type for \(children[0])")
            }
        case .number:
            return HeterogeneousNode(for: token,at: matchRange , value: Int.init(context.matchedString) ?? 0, annotations: [:])
        case .boolean:
            return HeterogeneousNode(for: token,at: matchRange , value: context.matchedString == "true", annotations: [:])
        case .label:
            return HeterogeneousNode(for: token,at: matchRange , value: ElementAnnotation(rawValue: context.matchedString), annotations: [:])
        case .stringBody, .terminalBody:
            return HeterogeneousNode(for: STLR.stringBody,at: matchRange , value: context.matchedString, annotations: [:])
        default:
            return nil
        }
    }
    
    
    public func failed(token: Token) {
        
    }
    
    public func ignoreableFailure(token: Token, annotations: [RuleAnnotation : RuleAnnotationValue], index: String.UnicodeScalarView.Index)->HeterogeneousNode? {
        if !token.transient && annotations[RuleAnnotation.pinned] != nil{
            let range = index..<index
            return HeterogeneousNode(for: token, at: range, annotations: annotations)
        }
        return nil
    }

    public func complete(parsingErrors: [Error]) -> [Error] {
    
        return validate(parsingErrors: parsingErrors)
    }
    
    private func getIdentifier(named name:String, at range:Range<String.UnicodeScalarView.Index>)->STLRIntermediateRepresentation.Identifier{
        if let existing = identifiers[name] {
            identifiers[name]?.references.append(range)
            return existing
        }
        
        let newIdentifier = STLRIntermediateRepresentation.Identifier(name: name, rawValue: identifiers.count+1)
        newIdentifier.references.append(range)
        identifiers[name] = newIdentifier
        
        return newIdentifier
    }
}
