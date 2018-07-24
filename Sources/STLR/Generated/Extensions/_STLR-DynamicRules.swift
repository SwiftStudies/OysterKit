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

fileprivate final class Symbol : SymbolType {
    var behaviouralRule : BehaviouralRule

    static func buildRule(for identifier: String, from grammar: _STLR.Grammar, in symbolTable: SymbolTable<Symbol>) -> Symbol {
        return Symbol(behaviouralRule: grammar[identifier].rule(using: symbolTable))
    }
    
    fileprivate init(behaviouralRule:BehaviouralRule){
        self.behaviouralRule = behaviouralRule
    }
}

extension _STLR.DefinedLabel {
    var ruleAnnotation : RuleAnnotation{
        switch self {
        case .token:
            return RuleAnnotation.token
        case .error:
            return RuleAnnotation.error
        case .void:
            return RuleAnnotation.void
        case .transient:
            return RuleAnnotation.transient
        }
    }
}

extension _STLR.Label {
    var ruleAnnotation : RuleAnnotation {
        switch self {
        case .customLabel(let customLabel):
            return RuleAnnotation.custom(label: customLabel)
        case .definedLabel(let definedLabel):
            return definedLabel.ruleAnnotation
        }
    }
}

extension _STLR.Literal {
    var ruleAnnotationValue : RuleAnnotationValue {
        switch self {
        case .string(let string):
            return RuleAnnotationValue.string(string.stringBody)
        case .number(let number):
            return RuleAnnotationValue.int(number)
        case .boolean(let boolean):
            return RuleAnnotationValue.bool(boolean == .true)
        }
    }
}

extension _STLR.Annotation {
    var ruleAnnotation : RuleAnnotation {
        return label.ruleAnnotation
    }
    var ruleAnnotationValue : RuleAnnotationValue {
        return literal?.ruleAnnotationValue ?? RuleAnnotationValue.set
    }
}

extension Array where Element == _STLR.Annotation {
    var ruleAnnotations : RuleAnnotations {
        var ruleAnnotations = [RuleAnnotation : RuleAnnotationValue]()
        for annotation in self {
            ruleAnnotations[annotation.ruleAnnotation]  = annotation.ruleAnnotationValue
        }
        return ruleAnnotations
    }
}

fileprivate extension Array where Element == _STLR.Element {
    func choice(with behaviour: Behaviour, and annotations:RuleAnnotations, using symbolTable:SymbolTable<Symbol>) -> BehaviouralRule {
        return ChoiceRule(behaviour, and: annotations, for: map({$0.rule(symbolTable: symbolTable)}))
    }
    func sequence(with behaviour: Behaviour, and annotations:RuleAnnotations, using symbolTable:SymbolTable<Symbol>) -> BehaviouralRule {
        return SequenceRule(behaviour, and: annotations, for: map({$0.rule(symbolTable: symbolTable)}))
    }
}

fileprivate extension _STLR.Element {
    
    var ruleAnnotations : RuleAnnotations {
        return annotations?.ruleAnnotations ?? [:]
    }
    
    var isVoid : Bool {
        return void != nil
    }
    
    var isLookahead : Bool {
        return lookahead != nil
    }
    
    var isNegated : Bool {
        return negated != nil
    }
    
    var isTransient : Bool {
        return transient != nil
    }
    
    var kind : Behaviour.Kind {
        if isVoid {
            return .skipping
        } else if isTransient {
            return .scanning
        }
        if let token = ruleAnnotations.token {
            return .structural(token: LabelledToken(withLabel: token))
        } else {
            return .scanning
        }
    }
    
    var cardinality : Cardinality {
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
    
    var behaviour : Behaviour {
        return Behaviour(kind, cardinality: cardinality, negated: isNegated, lookahead: isLookahead)
    }

    func rule(symbolTable:SymbolTable<Symbol>)->BehaviouralRule {
        if let group = group {
            return group.expression.rule(with: behaviour, and: ruleAnnotations, using: symbolTable)
        } else if let terminal = terminal {
            return terminal.rule(with:behaviour, and: ruleAnnotations)
        } else if let identifier = identifier {
            return symbolTable[identifier].behaviouralRule
        }
        fatalError("Could not generate rule for, \(self) it appears to not be a group, terminal or identifier")
    }
    
    func rule(with behaviour:Behaviour, and annotations:RuleAnnotations, using symbolTable:SymbolTable<Symbol>)->BehaviouralRule {
        return rule(symbolTable: symbolTable).instanceWith(behaviour: behaviour, annotations: ruleAnnotations.merge(with:annotations))
    }
    
}

extension _STLR.CharacterSetName {
    var characterSet : CharacterSet {
        switch self {
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
            return CharacterSet(charactersIn: "\\")
        }
    }
}

extension _STLR.Terminal {
    func rule(with behaviour:Behaviour, and annotations:RuleAnnotations)->BehaviouralRule {
        switch self {
        case .regex(let regex):
            let regularExpression = try! NSRegularExpression(pattern: regex, options: [])
            return ClosureRule(with: behaviour, and: annotations){(lexer,ir) in
                return try lexer.scan(regularExpression: regularExpression)
            }
        case .characterRange(let characterRange):
            let characterSet = CharacterSet(charactersIn: characterRange[0].terminalBody.first!.unicodeScalars.first!...characterRange[1].terminalBody.first!.unicodeScalars.first!)
            return ClosureRule(with: behaviour, and: annotations){(lexer,ir) in
                return try lexer.scan(oneOf: characterSet)
            }
        case .characterSet(let characterSet):
            return ClosureRule(with: behaviour, and: annotations){(lexer,ir) in
                return try lexer.scan(oneOf: characterSet.characterSetName.characterSet)
            }
        case .terminalString(let terminalString):
            return ClosureRule(with: behaviour, and: annotations){(lexer,ir) in
                return try lexer.scan(terminal: terminalString.terminalBody)
            }
        }
    }
}

fileprivate extension _STLR.Expression {
    func rule(with behaviour:Behaviour, and annotations:RuleAnnotations, using symbolTable:SymbolTable<Symbol>)->BehaviouralRule {
        switch self {
        case .sequence(let elements):
            return elements.sequence(with: behaviour, and: annotations, using: symbolTable)
        case .choice(let elements):
            return elements.choice(with: behaviour, and: annotations, using: symbolTable)
        case .element(let element):
            return element.rule(symbolTable: symbolTable)
        }
    }
}

fileprivate extension _STLR.Rule {
    var cardinality : Cardinality {
        return Cardinality.one
    }
    
    var kind : Behaviour.Kind {
        if let _ = void {
            return .skipping
        } else if let _ = transient {
            return .scanning
        } else {
            return .structural(token: LabelledToken(withLabel: identifier))
        }
    }
    
    var behaviour : Behaviour {
        return Behaviour(kind, cardinality: cardinality, negated: false, lookahead: false)
    }
    
    var ruleAnnotations : RuleAnnotations {
        #warning("This is only required whilst legacy rules may be involved, as it is formally captured in Behaviour.Kind")
        let assumed : RuleAnnotations = void != nil ? [.void : .set] : transient != nil ? [.transient : .set ] : [:]
    
        return assumed.merge(with: annotations?.ruleAnnotations ?? [:])
    }

    func rule(using symbolTable:SymbolTable<Symbol>)->BehaviouralRule {
        if symbolTable[hasRule: identifier] {
            return symbolTable[identifier].behaviouralRule
        }
        
        if symbolTable.ast.isLeftHandRecursive(identifier: identifier){
            let rule = BehaviouralRecursiveRule(stubFor: behaviour, with: ruleAnnotations)
            symbolTable[identifier] = Symbol(behaviouralRule: rule)
            rule.surrogateRule = expression.rule(with: behaviour, and: ruleAnnotations, using: symbolTable)
            return rule
        } else {
            let rule = expression.rule(with: behaviour, and: ruleAnnotations, using: symbolTable)
            symbolTable[identifier] = Symbol(behaviouralRule: rule)
            return rule
        }
    }
}

extension _STLR.Grammar {
    var dynamicRules : [BehaviouralRule] {
        let symbolTable = SymbolTable<Symbol>(self)
        return rules.map({(rule) in
            rule.rule(using: symbolTable)
        })
    }
}