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
import OysterKit

public extension _STLR.Grammar {
    public subscript(_ identifier:String)->_STLR.Rule{
        for rule in rules {
            if rule.identifier == identifier {
                return rule
            }
        }
        fatalError("Undefined identifier: \(identifier)")
    }
    
    public func isLeftHandRecursive(identifier:String)->Bool{
        var closedList = [String]()
        return self[identifier].expression.references(identifier, grammar: self, closedList: &closedList)
    }
    
    public func isDirectLeftHandRecursive(identifier:String)->Bool{
        var closedList = [String]()
        return self[identifier].expression.directlyReferences(identifier, grammar: self, closedList: &closedList)
    }
    
    public func isRoot(identifier:String)->Bool{
        var closedList = [String]()
        for rule in rules {
            if rule.identifier != identifier && rule.expression.references(identifier, grammar: self, closedList: &closedList){
                return false
            }
        }
        return true
    }

    public func validate(rule:_STLR.Rule) throws {
        if isDirectLeftHandRecursive(identifier: rule.identifier){
            throw TestError.interpretationError(message: "\(rule.identifier) is directly left hand recursive (references itself without moving scan head forward)", causes: [])
        }
    }
    
}

public extension _STLR.Quantifier {
    /// The minimum number of matches required to satisfy the quantifier
    public var minimumMatches : Int {
        switch self {
        case .star, .questionMark:
            return 0
        case .plus:
            return 1
        case .dash:
            fatalError("Should be depricated and not used")
        }
    }
    
    /// The maximum number of matches required to satisfy the quantifier
    public var maximumMatches : Int? {
        switch self {
        case .questionMark:
            return 1
        case .plus, .star:
            return nil
        case .dash:
            fatalError("Should be depricated and not used")
        }
    }
}

public extension _STLR.Expression {
    fileprivate var elements : [_STLR.Element] {
        switch self {
        case .sequence(let sequence):
            return sequence
        case .choice(let choice):
            return choice
        case .element(let element):
            return [element]
        }
    }

    public func directlyReferences(_ identifier:String, grammar:_STLR.Grammar, closedList:inout [String])->Bool {
        for element in elements {
            if element.directlyReferences(identifier, grammar: grammar, closedList: &closedList){
                return true
            }
            //If it's not lookahead it's not directly recursive
            if !(element.lookahead == nil ? false : element.lookahead! == ">>") || (element.quantifier?.minimumMatches ?? 1) > 0{
                return false
            }
            
        }
        return false
    }

    
    public func references(_ identifier:String, grammar:_STLR.Grammar, closedList: inout [String])->Bool {
        for element in elements {
            if element.references(identifier, grammar: grammar, closedList: &closedList){
                return true
            }
        }
        return false
    }
}

public extension _STLR.Element {

    /// The annotations defined as `RuleAnnotations`
    public var ruleAnnotations : RuleAnnotations {
        return annotations?.ruleAnnotations ?? [:]
    }
    
    /// True if the rule is skipping
    public var isVoid : Bool {
        return void != nil || (annotations?.void ?? false)
    }
    
    /// True if the rule is lookahead
    public var isLookahead : Bool {
        return lookahead != nil
    }
    
    /// True if the rule is negated
    public var isNegated : Bool {
        return negated != nil
    }
    
    /// True if it is a scanning rule
    public var isTransient : Bool {
        return transient != nil || (annotations?.transient ?? false)
    }
    
    /// The `Kind` of the rule
    public var kind : Behaviour.Kind {
        if isVoid {
            return .skipping
        } else if isTransient {
            return .scanning
        }
        if let token = annotations?.token {
            return .structural(token: LabelledToken(withLabel: token))
        } else {
            if let identifier = identifier {
                return .structural(token:LabelledToken(withLabel: identifier))
            }
            return .scanning
        }
    }
    
    /// The `Cardinality` of the match
    public var cardinality : Cardinality {
        guard let quantifier = quantifier else {
            return .one
        }
        
        switch quantifier {
        case .questionMark:
            return .optionally
        case .star:
            return .noneOrMore
        case .plus:
            return .oneOrMore
        default:
            return .one
        }
    }
    
    /// The `Behaviour` of the rule
    public var behaviour : Behaviour {
        return Behaviour(kind, cardinality: cardinality, negated: isNegated, lookahead: isLookahead)
    }
    
    /**
     Determines if the `Element` directly references the supplied identifier (references it at a point where it is
     possible the scan head has not moved.
     
     - Parameter identifier: The identifier that may be referenced
     - Parameter grammar: The grammar both the identifier and this element is in
     - Returns: `true` if the identifier could be referenced before the scan head has moved
    */
    public func directlyReferences(_ identifier:String, grammar:_STLR.Grammar)->Bool{
        var closedList = [String]()
        return directlyReferences(identifier, grammar: grammar, closedList: &closedList)
    }
    
    func directlyReferences(_ identifier:String, grammar:_STLR.Grammar, closedList:inout [String])->Bool {
        if let group = group {
            return group.expression.directlyReferences(identifier, grammar: grammar, closedList: &closedList)
        } else if let _ = terminal {
            return false
        } else if let referencedIdentifier = self.identifier{
            if referencedIdentifier == identifier {
                return true
            }
            if !closedList.contains(referencedIdentifier){
                closedList.append(referencedIdentifier)
                return grammar[referencedIdentifier].expression.directlyReferences(identifier, grammar:grammar, closedList: &closedList)
            }
        }
        return false
    }

    /**
     Determines if the `Element` references the supplied identifier (that is the identifier appears in the element or some part of
     an expression that forms the element.
     
     - Parameter identifier: The identifier that may be referenced
     - Parameter grammar: The grammar both the identifier and this element is in
     - Returns: `true` if the identifier is referenced
     */
    func references(_ identifier:String, grammar:_STLR.Grammar)->Bool{
        var closedList = [String]()
        return references(identifier, grammar: grammar, closedList: &closedList)
    }

    func references(_ identifier:String, grammar:_STLR.Grammar, closedList:inout [String])->Bool {
        if let group = group {
            return group.expression.references(identifier, grammar: grammar, closedList: &closedList)
        } else if let _ = terminal {
            return false
        } else if let referencedIdentifier = self.identifier{
            if referencedIdentifier == identifier {
                return true
            }

            if !closedList.contains(referencedIdentifier){
                closedList.append(referencedIdentifier)
                return grammar[referencedIdentifier].expression.references(identifier, grammar:grammar, closedList: &closedList)
            }
        }
        return false
    }
}

extension String {
    var unescaped: String {
        let entities = ["\0", "\t", "\n", "\r", "\"", "\'", "\\"]
        var current = self
        for entity in entities {
            let description = String(entity.debugDescription.dropFirst().dropLast())
            current = current.replacingOccurrences(of: description, with: entity)
        }
        return current
    }
}

extension _STLR.String {
    public var terminal : String {
        return stringBody.unescaped
    }
}

extension _STLR.TerminalString {
    public var terminal : String {
        return terminalBody.unescaped
    }
}

extension _STLR.CharacterSet {
    /// Creates the appropriate terminal from the character set node
    public var terminal : Terminal {
        switch characterSetName {
        case .letter:
            return CharacterSet.letters
        case .uppercaseLetter:
            return CharacterSet.uppercaseLetters
        case .lowercaseLetter:
            return CharacterSet.lowercaseLetters
        case .alphaNumeric:
            return CharacterSet.alphanumerics
        case .decimalDigit:
            return CharacterSet.decimalDigits
        case .whitespaceOrNewline:
            return CharacterSet.whitespacesAndNewlines
        case .whitespace:
            return CharacterSet.whitespaces
        case .newline:
            return CharacterSet.newlines
        case .backslash:
            return "\\"
        }
    }
    
}

fileprivate extension _STLR.Label {
    
    /// `true` if the impact of the annotation is captured in a rules `Behaviour`
    var isBehavioural : Bool {
        switch  self {
        case .definedLabel(let defined):
            switch defined {
                
            case .token, .void, .transient:
                return true
            case .error:
                return false
            }
        default:
            return false
        }
    }
}

public extension Array where Element == _STLR.Annotation {
    
    private subscript(_ desiredAnnotation:RuleAnnotation)->RuleAnnotationValue?{
        for annotation in self {
            if annotation.ruleAnnotation == desiredAnnotation {
                return annotation.ruleAnnotationValue
            }
        }
        return nil
    }
    
    /// The annotations on the element with any that would be captured in `Behaviour` removed (@token, @transient, @void)
    public var ruleAnnotations : RuleAnnotations {
        var ruleAnnotations = [RuleAnnotation : RuleAnnotationValue]()
        for annotation in filter({!$0.label.isBehavioural}){
            ruleAnnotations[annotation.ruleAnnotation]  = annotation.ruleAnnotationValue
        }
        return ruleAnnotations
    }
    
    /// The token if any specified in the annotations
    public var token : String? {
        guard let tokenAnnotationValue = self[RuleAnnotation.token] else {
            return nil
        }
        switch tokenAnnotationValue{
        case .string(let value):
            return value
        case .int(let value):
            return "\(value)"
        default:
            return nil
        }
    }
    
    /// `true` if the annotations include @void
    public var void : Bool {
        return self[RuleAnnotation.void] != nil
    }
    
    /// `true` if the annotations include @transient
    public var transient : Bool {
        return self[RuleAnnotation.transient] != nil
    }
    
    
}
