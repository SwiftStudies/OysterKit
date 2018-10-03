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

public final class LookupTable {
    private var table = Dictionary<Int, Testable>()
    
    public subscript(_ token:TokenType) -> Testable? {
        get {
            return table[token.rawValue]
        }
        
        set {
            table[token.rawValue] = newValue
        }
    }
}

public struct IndirectExpression : Testable {
    
    let token : TokenType
    let cache : LookupTable

    public func test(with lexer: LexicalAnalyzer, for ir: IntermediateRepresentation) throws {
        guard let test = cache[token] else {
            throw ProcessingError.fatal(message: "No entry in lookup table for \(token)", causes: [])
        }
        try test.test(with: lexer, for: ir)
    }
    
    public let matchDescription : String
}

public struct _Rule : RuleType {
    public let kind: Behaviour.Kind
    public let cardinality: Cardinality
    public let annotations: RuleAnnotations
    public let testable: Testable

    public func rule(_ kind: Behaviour.Kind, test: Testable, requiring: Cardinality, with annotations: RuleAnnotations) -> RuleType {
        return _Rule(kind: kind, cardinality: requiring, annotations: annotations, testable: test)
    }
}

extension String : Testable {
    
}

extension CharacterSet : Testable {
    
}

extension NSRegularExpression : Testable {
    
}

extension EndOfFile : Testable {
    
}

extension SerializedTerminal {
    func test() throws -> Testable {
        switch self {
        case .characterSequence(let string):
            return string
        case .characterSet(let characterSet):
            return characterSet
        case .characterRange(let start, let end):
            return CharacterSet(charactersIn: start...end)
        case .regularExpression(let pattern):
            return try NSRegularExpression(pattern: "^\(pattern)", options: [])
        case .endOfFile:
            return EndOfFile()
        }
    }
}

extension SerializedExpression {
    func test(with lookupTable:LookupTable, from symbolTable:SymbolTable<SerializedSymbol>) throws -> Testable {
        switch self {
        case .sequence(let elements):
            return SequenceTest(try elements.map({try $0.rule(with: lookupTable, from: symbolTable)}))
        case .choice(let choices):
            return ChoiceTest(try choices.map({try $0.rule(with: lookupTable, from: symbolTable)}))
        case .term(let term):
            return SequenceTest([try term.rule(with: lookupTable, from: symbolTable)])
        }
    }
}

extension SerializedReference {
    private func test(for expression:SerializedExpression, with lookupTable:LookupTable, from symbolTable:SymbolTable<SerializedSymbol>) throws -> Testable {
        if recursive {
            return IndirectExpression(token: StringToken(identifier), cache: lookupTable, matchDescription: expression.description)
        } else {
            return try expression.test(with: lookupTable, from: symbolTable)
        }
    }
    
    func rule(with lookupTable:LookupTable, from symbolTable:SymbolTable<SerializedSymbol>) throws -> RuleType {
        guard let symbol = symbolTable[identifier] else {
            throw ProcessingError.fatal(message: "Unknown identifier \(identifier)", causes: [])
        }
        
        return _Rule(kind: symbol.kind, cardinality: .one, annotations: symbol.annotations, testable: try test(for: symbol.expression, with: lookupTable, from: symbolTable))
    }
}

extension SerializedSymbol {
    func rule(with lookupTable:LookupTable, from symbolTable:SymbolTable<SerializedSymbol>) throws -> RuleType {
        return try term(in: symbolTable).rule(with: lookupTable, from: symbolTable)
    }
}

extension SerializedTerm {
    func rule(with lookupTable:LookupTable, from symbolTable:SymbolTable<SerializedSymbol>) throws -> RuleType {
        var rule : RuleType
        
        switch term {
        case .terminal(let terminal, _, _):
            rule = _Rule(kind: kind, cardinality: cardinality, annotations: annotations, testable: try terminal.test())
        case .group(let group , _, _):
            rule = _Rule(kind: kind, cardinality: cardinality, annotations: annotations, testable: try group.test(with:lookupTable, from: symbolTable))
        case .reference(let reference, _, _):
            rule = kind.apply(to: try reference.rule(with: lookupTable, from: symbolTable).require(cardinality).add(annotations))
        }
        
        rule = term.looksahead ? rule.lookahead() : rule
        return term.negates ? rule.negate() : rule
    }
}

extension SymbolTable : Grammar where Symbol == SerializedSymbol{
    
    internal subscript(dynamicRuleFor identifier:String)->Rule? {
        do {
            let lookupTable = LookupTable()
            var allRules = [String:Rule]()
            
            _ = try compactMap({ (symbolTable, symbol) -> RuleType? in
                let rule = try symbol.rule(with: lookupTable, from: self)
                
                allRules[symbol.identifier] = rule

                return rule
            })
            
            for symbol in self where symbol.recursive {
                lookupTable[StringToken(symbol.identifier)] = try symbol.expression.test(with: lookupTable, from: self)
            }
            
            return allRules[identifier]
        } catch let error as ProcessingError {
            print(String(reflecting: error))
            return nil
        } catch {
            print("\(error)")
            return nil
        }
    }
    
    public var rules: [Rule] {
        
        
        do {
            let lookupTable = LookupTable()
            var rootRules = [Rule]()

            _ = try compactMap({ (symbolTable, symbol) -> RuleType? in
                let rule = try symbol.rule(with: lookupTable, from: self)
                
                if !symbol.referenced {
                    rootRules.append(rule)
                }
                
                return rule
            })
            
            for symbol in self where symbol.recursive {
                lookupTable[StringToken(symbol.identifier)] = try symbol.expression.test(with: lookupTable, from: self)
            }
            
            return rootRules
        } catch let error as ProcessingError {
            print(String(reflecting: error))
            return []
        } catch {
            print("\(error)")
            return []
        }
    }
}
