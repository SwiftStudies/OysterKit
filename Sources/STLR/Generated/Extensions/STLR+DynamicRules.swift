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

fileprivate struct RecursionWrapper : Rule {
    var behaviour: Behaviour
    var annotations: RuleAnnotations
    var wrapped : RecursiveRule
    
    func test(with lexer: LexicalAnalyzer, for ir: IntermediateRepresentation) throws {
        try wrapped.test(with: lexer, for: ir)
    }
    
    func rule(with behaviour: Behaviour?, annotations: RuleAnnotations?) -> Rule {
        return RecursionWrapper(behaviour: behaviour ?? self.behaviour, annotations: annotations ?? self.annotations, wrapped: wrapped)
    }
    
    var shortDescription: String {
        return behaviour.describe(match: wrapped.description, annotatedWith: annotations)
    }
    
    var description: String {
        return behaviour.describe(match: wrapped.shortDescription, annotatedWith: annotations)
    }
    
    
}

fileprivate final class Symbol : SymbolType {
    let identifier : String
    private var expression: Rule
    private var baseAnnotations : RuleAnnotations
    private var baseKind : Behaviour.Kind
    
    static func build(for identifier: String, from grammar: STLR.Grammar, in symbolTable: SymbolTable<Symbol>) -> Symbol {

        let declaration = grammar[identifier]
        if grammar.isLeftHandRecursive(identifier: identifier){
            let recursive = RecursiveRule(stubFor: Behaviour(.scanning), with: [:])
            let wrapped = RecursionWrapper(behaviour: Behaviour(.scanning), annotations: [:], wrapped: recursive)
            return Symbol(identifier, with: wrapped, baseKind: declaration.behaviour.kind, baseAnnotations: declaration.annotations?.ruleAnnotations ?? [:])
        } else {
            var rule = grammar[identifier].expression.rule(using: symbolTable)
            
            // Terminal rules
            if let terminalRule = rule as? TerminalRule, !terminalRule.annotations.isEmpty {
                rule = [rule].sequence
            }
            
            return Symbol(identifier, with: rule, baseKind: declaration.behaviour.kind, baseAnnotations: declaration.annotations?.ruleAnnotations ?? [:])
        }
    }
    
    func resolve(from grammar:STLR.Grammar, in symbolTable: SymbolTable<Symbol>) throws {
        if let wrapper = expression as? RecursionWrapper {
            wrapper.wrapped.surrogateRule = grammar[identifier].expression.rule(using: symbolTable)
        }
    }
    
    func validate(from grammar: STLR.Grammar, in symbolTable: SymbolTable<Symbol>) throws {
        
    }
    
    init(_ identifier:String, with expression:Rule, baseKind: Behaviour.Kind, baseAnnotations:RuleAnnotations){
        self.identifier = identifier
        self.expression = expression
        self.baseKind = baseKind
        self.baseAnnotations = baseAnnotations
    }
    
    func reference(with behaviour:Behaviour, and instanceAnnotations:RuleAnnotations)->Rule{
        return expression.annotatedWith(baseAnnotations.merge(with: instanceAnnotations)).reference(behaviour.kind).rule(with:behaviour,annotations: nil).scan()
    }
    
    var  rule : Rule {
        let behaviour = Behaviour(baseKind, cardinality: expression.behaviour.cardinality, negated: expression.behaviour.negate, lookahead: expression.behaviour.lookahead)
        return expression.rule(with: behaviour, annotations: baseAnnotations.merge(with: expression.annotations))
    }
}

extension STLR.DefinedLabel {
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

extension STLR.Label {
    var ruleAnnotation : RuleAnnotation {
        switch self {
        case .customLabel(let customLabel):
            return RuleAnnotation.custom(label: customLabel)
        case .definedLabel(let definedLabel):
            return definedLabel.ruleAnnotation
        }
    }
}

extension STLR.Literal {
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

extension STLR.Annotation {
    var ruleAnnotation : RuleAnnotation {
        return label.ruleAnnotation
    }
    var ruleAnnotationValue : RuleAnnotationValue {
        return literal?.ruleAnnotationValue ?? RuleAnnotationValue.set
    }
}





fileprivate extension Array where Element == STLR.Element {
    func choice(with behaviour: Behaviour, and annotations:RuleAnnotations, using symbolTable:SymbolTable<Symbol>) -> Rule {
        return ChoiceRule(behaviour, and: annotations, for: map({$0.rule(symbolTable: symbolTable)}))
    }
    func sequence(with behaviour: Behaviour, and annotations:RuleAnnotations, using symbolTable:SymbolTable<Symbol>) -> Rule {
        return SequenceRule(behaviour, and: annotations, for: map({$0.rule(symbolTable: symbolTable)}))
    }
}

fileprivate extension STLR.Element {
    private static func rule(for element:STLR.Element, using symbolTable:SymbolTable<Symbol>)->Rule {
        if let terminal = element.terminal {
            return terminal.rule(with: element.behaviour, and: element.annotations?.ruleAnnotations ?? [:])
        } else if let identifier = element.identifier {
            return symbolTable[identifier].reference(with: element.behaviour, and: element.annotations?.ruleAnnotations ?? [:])
        } else if let group = element.group {
//            if case let _STLR.Expression.element(singleElement) = group.expression {
//                #warning("Could this be more efficiently implemented by creating a RuleReference rather than a sequence?")
//                return [singleElement.rule(symbolTable: symbolTable)].sequence.rule(with: element.behaviour, annotations: element.annotations?.ruleAnnotations ?? [:])
//            } else {
                #warning("This might be bogus, remove warning when tests pass")
                return [group.expression.rule(using: symbolTable)].sequence.rule(with: element.behaviour,annotations: element.annotations?.ruleAnnotations ?? [:])
//            }
        }
        fatalError("Element is not a terminal, and identifier reference, or a group")
    }
    func rule(symbolTable:SymbolTable<Symbol>)->Rule {
        let element : STLR.Element
        if let token = token {
            element = STLR.Element(annotations: annotations?.filter({!$0.label.isToken}), group: nil, identifier: "\(token)", lookahead: lookahead, negated: negated, quantifier: quantifier, terminal: nil, transient: transient, void: void)
        } else {
            element = self
        }
        return STLR.Element.rule(for:element, using:symbolTable)
     }
}

extension STLR.CharacterSetName {
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

extension STLR.Terminal {
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

fileprivate extension STLR.Expression {
    func rule(using symbolTable:SymbolTable<Symbol>)->Rule {
        switch self {
        case .sequence(let elements):
            return elements.map({ (element) -> Rule in
                element.rule(symbolTable: symbolTable)
            }).sequence
        case .choice(let elements):
            return elements.map({ (element) -> Rule in
                element.rule(symbolTable: symbolTable)
            }).choice
        case .element(let element):
            return element.rule(symbolTable: symbolTable)
        }
    }
}

fileprivate extension STLR.Rule {
    var cardinality : Cardinality {
        return Cardinality.one
    }
    
    var kind : Behaviour.Kind {
        if let _ = void {
            return .skipping
        } else if let _ = transient {
            return .scanning
        } else {
            return .structural(token: StringToken(identifier))
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

}

public extension STLR.Grammar {
    /// Builds a set of `Rule`s that can be used directly at run-time in your application
    public var dynamicRules : [Rule] {
        let symbolTable = SymbolTable<Symbol>(self)
        
        do {
            try symbolTable.build()
            try symbolTable.resolve()
            try symbolTable.validate()
        } catch {
            fatalError("Failed to construct symbol table: \(error)")
        }
        
        let rootRules = rules.filter({
            return self.isRoot(identifier: $0.identifier)
        })
        
        if rootRules.isEmpty {
            guard let lastRule = rules.last else {
                return []
            }
            return [
                symbolTable[lastRule.identifier].rule
            ]
        } else {
            return rootRules.map({symbolTable[$0.identifier].rule})
        }
    }
}


