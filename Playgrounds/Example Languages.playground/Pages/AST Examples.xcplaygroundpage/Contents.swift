//: Playground - noun: a place where people can play

import Foundation
import STLR
import OysterKit


//
// STLR Generated Swift File
//
// Generated: 2018-07-10 01:30:36 +0000
//
#if os(macOS)
import Cocoa
#elseif os(iOS)
import UIKit
#else
import Foundation
#endif
import OysterKit

//
// Pets Parser
//
enum Pets : Int, Token {
    
    // Convenience alias
    private typealias T = Pets
    
    case _transient = -1, `feline`, `canine`, `pet`
    
    func _rule(_ annotations: RuleAnnotations = [ : ])->Rule {
        switch self {
        case ._transient:
            return CharacterSet(charactersIn: "").terminal(token: T._transient)
        // feline
        case .feline:
            return ScannerRule.regularExpression(token: T.feline, pattern: try! NSRegularExpression(pattern: "^(c|C)at(s)?",options: []), annotations: annotations)
        // canine
        case .canine:
            return ScannerRule.regularExpression(token: T.canine, pattern: try! NSRegularExpression(pattern: "^(d|D)og(s|gie)?",options: []), annotations: annotations)
        // pet
        case .pet:
            return [
                T.feline._rule(),
                T.canine._rule(),
                ].oneOf(token: T.pet, annotations: annotations)
        }
    }
    
    
    // Create a language that can be used for parsing etc
    public static var generatedLanguage : Parser {
        return Parser(grammar: [T.pet._rule()])
    }
    
    // Convient way to apply your grammar to a string
    public static func parse(source: String) throws -> HomogenousTree {
        return try AbstractSyntaxTreeConstructor().build(source, using: generatedLanguage)
    }
}

Pets.generatedLanguage.grammar.count
