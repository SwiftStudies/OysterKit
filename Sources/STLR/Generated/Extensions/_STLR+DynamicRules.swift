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
    var behaviouralRule : Rule

    static func buildRule(for identifier: String, from grammar: _STLR.Grammar, in symbolTable: SymbolTable<Symbol>) -> Symbol {
        return Symbol(behaviouralRule: grammar[identifier].rule(using: symbolTable))
    }
    
    fileprivate init(behaviouralRule:Rule){
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





fileprivate extension Array where Element == _STLR.Element {
    func choice(with behaviour: Behaviour, and annotations:RuleAnnotations, using symbolTable:SymbolTable<Symbol>) -> Rule {
        return ChoiceRule(behaviour, and: annotations, for: map({$0.rule(symbolTable: symbolTable)}))
    }
    func sequence(with behaviour: Behaviour, and annotations:RuleAnnotations, using symbolTable:SymbolTable<Symbol>) -> Rule {
        return SequenceRule(behaviour, and: annotations, for: map({$0.rule(symbolTable: symbolTable)}))
    }
}

fileprivate extension _STLR.Element {
    func rule(symbolTable:SymbolTable<Symbol>)->Rule {
        if let group = group {
            return group.expression.rule(with: behaviour, and: ruleAnnotations, using: symbolTable)
        } else if let terminal = terminal {
            return terminal.rule(with:behaviour, and: ruleAnnotations)
        } else if let identifier = identifier {
            let symbolRule = symbolTable[identifier].behaviouralRule
            return symbolRule.rule(with: behaviour, annotations: symbolRule.annotations.merge(with: ruleAnnotations))
        }
        fatalError("Could not generate rule for, \(self) it appears to not be a group, terminal or identifier")
    }
    
    func rule(with behaviour:Behaviour, and annotations:RuleAnnotations, using symbolTable:SymbolTable<Symbol>)->Rule {
        return rule(symbolTable: symbolTable).rule(with: behaviour, annotations: ruleAnnotations.merge(with:annotations))
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
    func rule(with behaviour:Behaviour, and annotations:RuleAnnotations)->Rule {
        switch self {
        case .regex(let regex):
            let regularExpression = try! NSRegularExpression(pattern: "^\(regex)", options: [])
            return TerminalRule(behaviour, and: annotations, for: regularExpression)
        case .characterRange(let characterRange):
            let characterSet = CharacterSet(charactersIn: characterRange[0].terminalBody.first!.unicodeScalars.first!...characterRange[1].terminalBody.first!.unicodeScalars.first!)
            return TerminalRule(behaviour, and: annotations, for: characterSet)
        case .characterSet(let characterSet):
            return TerminalRule(behaviour, and: annotations, for: characterSet.terminal)
        case .terminalString(let terminalString):
            return TerminalRule(behaviour, and: annotations, for: terminalString.terminal)
        }
    }
}

fileprivate extension _STLR.Expression {
    func rule(with behaviour:Behaviour, and annotations:RuleAnnotations, using symbolTable:SymbolTable<Symbol>)->Rule {
        switch self {
        case .sequence(let elements):
            return elements.sequence(with: behaviour, and: annotations, using: symbolTable)
        case .choice(let elements):
            return elements.choice(with: behaviour, and: annotations, using: symbolTable)
        case .element(let element):
            #warning("There is an optimization oppertunity here. If it's a single element with no specific annotations we don't need to wrap in a sequence but can 'merge' and hoist")
            return [element].sequence(with: behaviour, and: annotations, using: symbolTable)
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

    func rule(using symbolTable:SymbolTable<Symbol>)->Rule {
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
    /// Builds a set of `Rule`s that can be used directly at run-time in your application
    public var dynamicRules : [Rule] {
        let symbolTable = SymbolTable<Symbol>(self)
        
        let rootRules = rules.filter({
            return self.isRoot(identifier: $0.identifier)
        })
        
        if rootRules.isEmpty {
            guard let lastRule = rules.last else {
                return []
            }
            return [lastRule.rule(using: symbolTable)]
        } else {
            return rootRules.map({$0.rule(using: symbolTable)})
        }
    }
}


