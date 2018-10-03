//    Copyright (c) 2018, RED When Excited
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

public enum SerializedTerminal : CustomStringConvertible {
    case characterSequence(String)
    case characterSet(CharacterSet)
    case characterRange(start:UnicodeScalar, end:UnicodeScalar)
    case regularExpression(pattern:String)
    case endOfFile
    
    var testDescription : String {
        switch self {
        case .endOfFile:
            return ".endOfFile"
        case .characterSequence(let string):
            return string.debugDescription
        case .characterSet(let characterSet):
            return characterSet.matchDescription
        case .characterRange(let start, let end):
            return """
            \(start.debugDescription)...\(end.debugDescription)
            """
        case .regularExpression(let pattern):
            return "/\(pattern)/"
        }
    }
    
    public var description: String {
        return testDescription
    }
}

public enum SerializedExpression : CustomStringConvertible{
    case sequence([SerializedTerm])
    case choice([SerializedTerm])
    case term(SerializedTerm)
    
    var testDescription : String {
        switch self {
        case .sequence(let terms):
            return "\(terms.map({$0.description}).joined(separator: " "))"
        case .choice(let terms):
            return "\(terms.map({$0.description}).joined(separator: " | "))"
        case .term(let term):
            return term.description
        }
    }
    
    public var description: String {
        return testDescription
    }
}

public struct SerializedReference : CustomStringConvertible {
    public let identifier : String
    public let recursive  : Bool
    private func declarationKind(in symbolTable:SymbolTable<SerializedSymbol>) throws -> Behaviour.Kind{
        guard let symbol = symbolTable[identifier] else {
            if !symbolTable.ast.defined(identifier: identifier){
                throw ProcessingError.fatal(message: "No symbol found for \(identifier)", causes: [])
            }
            
            let rule = symbolTable.ast[identifier]
            if rule.isVoid {
                return .skipping
            } else if rule.isTransient {
                return .scanning
            } else {
                return .structural(token: StringToken(identifier))
            }
        }
        return symbol.kind
    }
    
    public init(to identifier:String, in symbolTable:SymbolTable<SerializedSymbol>){
        self.identifier = identifier
        recursive = symbolTable.isLeftHandRecursive(identifier)
    }
    
    fileprivate func apply(override kind: Behaviour.Kind, from symbolTable:SymbolTable<SerializedSymbol>) throws ->Behaviour.Kind {
        let declaredKind = try declarationKind(in: symbolTable)
        switch kind {
        case .structural:
            return  declaredKind
        case .scanning:
            if case .skipping = declaredKind {
                throw ProcessingError.fatal(message: "You cannot upgrade -\(identifier) to scanning", causes: [])
            }
            return kind
        case .skipping:
            return kind
        }
    }
    
    public var testDescription : String {
        return identifier
    }
    
    public var description: String {
        return (recursive ? "🔁" : "") + testDescription
    }
}


public struct SerializedTerm : CustomStringConvertible {
    public indirect enum TermType : CustomStringConvertible {
        case terminal(SerializedTerminal, negated: Bool, looksahead:Bool)
        case group(SerializedExpression, negated: Bool, looksahead:Bool)
        case reference(SerializedReference, negated: Bool, looksahead:Bool)
        
        public func test(lexer: LexicalAnalyzer, ir: IntermediateRepresentation) throws {
            throw ProcessingError.fatal(message: "Serialized Terms cannot be tested", causes: [])
        }
        
        public var negates: Bool {
            switch self {
            case .terminal(_, let negated, _), .group(_, let negated, _), .reference(_, let negated, _):
                return negated
            }
        }

        public var looksahead: Bool {
            switch self {
            case .terminal(_, _, let looksahead), .group(_, _, let looksahead), .reference(_, _, let looksahead):
                return looksahead
            }
        }
        
        public var testDescription: String {
            switch self {
            case .terminal(let terminal, _,_):
                return terminal.testDescription
            case .group(let group, _,_):
                return "(\(group.testDescription))"
            case .reference(let reference, _,_):
                return reference.testDescription
            }
        }
        
        public var description: String {
            switch self {
            case .terminal(let terminal, _,_):
                return terminal.description
            case .group(let group, _,_):
                return "(\(group.description))"
            case .reference(let reference, _,_):
                return reference.description
            }
        }
    }
    
    public let term : TermType
    public let kind: Behaviour.Kind
    public let cardinality: Cardinality
    public let annotations: RuleAnnotations
    
    init(_ kind:Behaviour.Kind, requiring cardinality:Cardinality, of term:TermType, annotatedWith annotations:RuleAnnotations, in symbolTable:SymbolTable<SerializedSymbol>) throws {
        if case let .reference(reference,_,_) = term  {
            self.kind = try reference.apply(override: kind, from: symbolTable)
        } else {
            self.kind = kind
        }
        self.cardinality = cardinality
        self.annotations = annotations
        self.term = term
    }
    
    public func term(_ kind: Behaviour.Kind, term: TermType, requiring cardinality: Cardinality, with annotations: RuleAnnotations, in symbolTable:SymbolTable<SerializedSymbol>) throws -> SerializedTerm {
        return try SerializedTerm(kind, requiring: cardinality, of: term, annotatedWith: annotations, in: symbolTable)
    }
    
    public var description: String {
        var prefix : String
        
        if !annotations.isEmpty {
            prefix = "\(annotations.stlrDescription) "
        } else {
            prefix = ""
        }

        
        if case .skipping = kind {
            prefix += "-"
        }
        
        if term.negates {
            prefix = "\(prefix)!"
        }
        if term.looksahead {
            prefix = "\(prefix)>>"
        }
        
        
        var suffix : String
        
        if cardinality == Cardinality(1...1){
            suffix = ""
        } else if cardinality == Cardinality(1...) {
            suffix = "+"
        } else if cardinality == Cardinality(0...) {
            suffix = "*"
        } else if cardinality == Cardinality(0...1) {
            suffix = "?"
        } else {
            suffix = "[\(cardinality.minimumMatches)...\(cardinality.maximumMatches == nil ? "" : "\(cardinality.maximumMatches!)")]"
        }
        
        return "\(prefix)\(term.description)\(suffix)"
                
    }
}

#warning("When we don't have both implementaions, this can become just Symbol")
public final class SerializedSymbol : SymbolType {
    public let identifier : String
    public let expression  : SerializedExpression
    public let annotations : RuleAnnotations
    public let kind        : Behaviour.Kind
    let recursive : Bool
    let referenced : Bool
    
    public static func build(for identifier: String, in symbolTable: SymbolTable<SerializedSymbol>) throws -> SerializedSymbol {
        let grammar = symbolTable.ast
        
        guard symbolTable.ast.defined(identifier: identifier) else {
            throw ProcessingError.interpretation(message: "\(identifier) is not defined in \(symbolTable.ast.scopeName)", causes: [])
        }
        
        let declaration             = grammar[identifier]
        #warning("Should make this a special function that filters out an inapplicable annotations")
        let annotations             = declaration.annotations?.ruleAnnotations ?? [:]
        let kind : Behaviour.Kind   = declaration.isVoid ? .skipping : declaration.isTransient ? .scanning : .structural(token: StringToken(identifier))
        
        return SerializedSymbol(identifier, with: try declaration.expression.serialize(in:symbolTable), kind: kind, annotations: annotations, recursive: symbolTable.ast.isLeftHandRecursive(identifier: identifier), referenced: !symbolTable.ast.isRoot(identifier: identifier))
    }
    
    public func term(in symbolTable: SymbolTable<SerializedSymbol>) throws ->  SerializedTerm {
        return try SerializedTerm(kind, requiring: .one, of: .group(expression, negated: false, looksahead: false), annotatedWith: annotations, in: symbolTable)
    }
    
    public func resolve(in symbolTable: SymbolTable<SerializedSymbol>) throws {
//        if let wrapper = expression as? RecursionWrapper {
//            wrapper.wrapped.surrogateRule = grammar[identifier].expression.rule(using: symbolTable)
//        }
    }
    
    public func validate(in symbolTable: SymbolTable<SerializedSymbol>) throws {
        
    }
    
    init(_ identifier:String, with expression:SerializedExpression,kind: Behaviour.Kind, annotations:RuleAnnotations, recursive:Bool, referenced:Bool){
        self.identifier = identifier
        self.expression = expression
        self.kind = kind
        self.annotations = annotations
        self.recursive = recursive
        self.referenced = referenced
    }
    
    public var description: String{
        let type : String
        if let typeValue = self.annotations[RuleAnnotation.type], case let RuleAnnotationValue.string(typeName) = typeValue {
            type = ": \(typeName) "
        } else {
            type = ""
        }
        
        let annotations = self.annotations.filter { (annotationEntry) -> Bool in
            switch annotationEntry.key {
            case .type, .token:
                return false
            case .error, .void, .transient, .pinned, .custom(_):
                return true
                
            }
        }
        
        return "\(annotations.stlrDescription) \(recursive ? "🔁" : (referenced ? "" : "⏺"))\(identifier) \(type)= \(expression.description)"
    }
}

extension STLR {
    func analyze<Symbol:SymbolType>(_ type : Symbol.Type) throws -> SymbolTable<Symbol> {
        let symbolTable = SymbolTable<Symbol>(self.grammar)
        
        try symbolTable.build()
        
        return symbolTable
    }
}

public protocol SymbolType : CustomStringConvertible {
    static func build(for identifier: String, in symbolTable: SymbolTable<Self>) throws ->Self
    
    func resolve(in symbolTable: SymbolTable<Self>) throws
    func validate(in symbolTable: SymbolTable<Self>) throws
    
    var identifier   : String {get}
}

public class SymbolTable<Symbol:SymbolType> : CustomStringConvertible, Sequence {
    public typealias Iterator = Array<Symbol>.Iterator
    public let ast : STLR.Grammar
    private var identifiers = [String : Symbol]()
    
    /**
     Creates a new symbol table for the specified grammar. The table will be empty, and the caller
     should subsequently call `build()`, `resolve()`, then `validate()` before the table can be used.
     **/
    public init(_ grammr:STLR.Grammar){
        ast = grammr
    }
    
    public func makeIterator() -> IndexingIterator<Array<Symbol>> {
        return identifiers.map({$0.value}).makeIterator()
    }
    
    /**
     Builds the symbol table. Implementers of the `SymbolType` should not attempt to resolve
     recursion at this stage, but create a forward reference that can be turned into a final
     reference in the resolution phase.
     **/
    public func build() throws{
        var errors = [Error]()
        for rule in ast.rules {
            if identifiers[rule.identifier] == nil {
                do {
                    identifiers[rule.identifier] = try Symbol.build(for: rule.identifier, in: self)
                } catch {
                    errors.append(error)
                }
            }
        }
        if !errors.isEmpty {
            throw ProcessingError.fatal(message: "Cannot build symbol table", causes: errors)
        }
    }
    
    /**
     Any evaluation of symbols (for example as a result of recursion) that were left as forward
     references should be resolved at this stage.
     **/
    public func resolve() throws{
        var errors = [Error]()
        for (_,symbol) in identifiers {
            do {
                try symbol.resolve(in: self)
            } catch {
                errors.append(error)
            }
        }
        
        if !errors.isEmpty {
            throw ProcessingError.interpretation(message: "Failed to resolve symbol table", causes: errors)
        }
    }
    
    /**
     A final validation step to ensure there are no issues in the table.
     **/
    public func validate() throws {
        var errors = [Error]()
        for (_,symbol) in identifiers {
            do {
                try symbol.validate(in: self)
            } catch {
                errors.append(error)
            }
        }
        
        if !errors.isEmpty {
            throw ProcessingError.interpretation(message: "Failed to validate symbol table", causes: errors)
        }
    }
    
    public func isLeftHandRecursive(_ identifier:String)->Bool{
        var closedList = [String]()
        return ast[identifier].expression.references(identifier, grammar: ast, closedList: &closedList)
    }
    
    public func compactMap<T>(_ using:(SymbolTable, Symbol) throws ->T?) throws -> [T]{
        return try identifiers.compactMap { (entry) -> T? in
            return try using(self, entry.value)
        }
    }
    
    public subscript(_ identifier:String) -> Symbol? {
        return identifiers[identifier]
    }
    
    public var description: String{
        let declarationDescriptions = identifiers.map { (entry) -> String in
            return entry.value.description
        }
        
        return declarationDescriptions.joined(separator: "\n")
    }
}

fileprivate extension STLR.Expression {
    func serialize(in symbolTable:SymbolTable<SerializedSymbol>) throws ->SerializedExpression {
        switch self {
        case .choice(let choice):
            return SerializedExpression.choice(try choice.map({try $0.serialize(in: symbolTable)}))
        case .sequence(let sequence):
            return SerializedExpression.sequence(try sequence.map({try $0.serialize(in: symbolTable)}))
        case .element(let element):
            return try SerializedExpression.term(element.serialize(in: symbolTable))
        }
    }
}

extension STLR.Terminal {
    func serialized() throws -> SerializedTerminal {
        switch self {
        case .terminalString(let terminalString):
            return .characterSequence(terminalString.terminalBody.unescaped)
        case .characterRange(let characterRange):
            if let first = characterRange.first?.terminalBody.first?.unicodeScalars.first, let last = characterRange.last?.terminalBody.first?.unicodeScalars.first {
                return .characterRange(start: first, end: last)
            }
            throw ProcessingError.fatal(message: "Could not create character range, first and last characters could not be determined", causes: [])
        case .characterSet(let characterSet):
            return .characterSet(characterSet.characterSetName.characterSet)
        case .endOfFile(_):
            return .endOfFile
        case .regex(let regex):
            return .regularExpression(pattern: regex)
        }
    }
}

extension SerializedTerm.TermType {
    
    static func term(for element:STLR.Element, in symbolTable:SymbolTable<SerializedSymbol>) throws ->SerializedTerm.TermType {
        if let terminal = element.terminal {
            return .terminal(try terminal.serialized(), negated: element.isNegated, looksahead: element.isLookahead)
        } else if let group = element.group {
            return .group(try group.expression.serialize(in: symbolTable), negated: element.isNegated, looksahead: element.isLookahead)
        } else if let identifier = element.identifier {
            return .reference(SerializedReference(to: identifier, in: symbolTable), negated: element.isNegated, looksahead: element.isLookahead)
        }
        throw ProcessingError.fatal(message: "Element is not a group, terminal or identifier:\n\(element.description)", causes: [])
    }
}

fileprivate extension STLR.Element {
    
    func serialize(in symbolTable:SymbolTable<SerializedSymbol>) throws ->SerializedTerm {
        //Is there an inline declaration here?
        if let token = ruleAnnotations.token {
            //Create a reference to the identified element
            return try SerializedTerm(.structural(token: token), requiring: .one, of: SerializedTerm.TermType.reference(SerializedReference(to: token, in: symbolTable), negated: false, looksahead: false), annotatedWith: [:], in: symbolTable )
        }
        
        return try SerializedTerm(kind, requiring: behaviour.cardinality, of: try SerializedTerm.TermType.term(for: self, in: symbolTable), annotatedWith: ruleAnnotations, in: symbolTable)
    }
}
