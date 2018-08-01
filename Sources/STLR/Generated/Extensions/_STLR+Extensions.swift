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
        return self[identifier].expression.references(identifier, grammar: self, closedList: [])
    }
    
    public func isDirectLeftHandRecursive(identifier:String)->Bool{
        return self[identifier].expression.directlyReferences(identifier, grammar: self, closedList: [])
    }
    
    public func isRoot(identifier:String)->Bool{
        for rule in rules {
            if rule.identifier != identifier && rule.expression.references(identifier, grammar: self, closedList: []){
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

    public func directlyReferences(_ identifier:String, grammar:_STLR.Grammar, closedList:[String])->Bool {
        for element in elements {
            if element.directlyReferences(identifier, grammar: grammar, closedList: closedList){
                return true
            }
            //If it's not lookahead it's not directly recursive
            if !(element.lookahead == nil ? false : element.lookahead! == ">>") || (element.quantifier?.minimumMatches ?? 1) > 0{
                return false
            }
            
        }
        return false
    }

    
    public func references(_ identifier:String, grammar:_STLR.Grammar, closedList:[String])->Bool {
        for element in elements {
            if element.references(identifier, grammar: grammar, closedList: closedList){
                return true
            }
        }
        return false
    }
}

public extension _STLR.Element {
    func directlyReferences(_ identifier:String, grammar:_STLR.Grammar, closedList:[String])->Bool {
        if let group = group {
            return group.expression.directlyReferences(identifier, grammar: grammar, closedList: closedList)
        } else if let _ = terminal {
            return false
        } else if let referencedIdentifier = self.identifier{
            if referencedIdentifier == identifier {
                return true
            }
            if !closedList.contains(referencedIdentifier){
                return grammar[referencedIdentifier].expression.references(identifier, grammar:grammar, closedList: closedList)
            }
        }
        return false
    }


    func references(_ identifier:String, grammar:_STLR.Grammar, closedList:[String])->Bool {
        if let group = group {
            return group.expression.references(identifier, grammar: grammar, closedList: closedList)
        } else if let _ = terminal {
            return false
        } else if let referencedIdentifier = self.identifier{
            if referencedIdentifier == identifier {
                return true
            }
            if !closedList.contains(referencedIdentifier){
                return grammar[referencedIdentifier].expression.references(identifier, grammar:grammar, closedList: closedList)
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
