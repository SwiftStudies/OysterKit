//
//  FixValidations.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import XCTest
@testable import OysterKit
import STLR

class FixValidations: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        STLRIntermediateRepresentation.removeAllOptimizations()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    //
    // Effect: Quantifiers specified on one element could leak into another element (typically the next one along)
    // when an element evaluation failed. In this case the created 'import' rule would be 'import'* leaking the * from
    // .decimalDigits
    //
    func testQuantifierLeak() {
        let grammarString = "number  = .decimalDigits*\n keyword = \"import\" | \"wibble\""
        
        let stlr = STLRParser(source: grammarString)
        
        let ast = stlr.ast
        
        guard ast.rules.count == 2 else {
            XCTFail("Only \(ast.rules.count) rules created, expected 2")
            return
        }
        
        XCTAssert("\(ast.rules[0])" == "number = .decimalDigits*", "Malformed rule: \(ast.rules[0])")
        XCTAssert("\(ast.rules[1])" == "keyword = \"import\" | \"wibble\"", "Malformed rule: '\(ast.rules[1])'")
    }

    //
    // Effect: When the CharacterSet optimization is applied to a choice of a single character string
    // and a character set, the single character set is lost.
    //
    func testCharacterSetOmmision() {
        let grammarString = "variableStart = .letters | \"_\""
        
        let stlr = STLRParser(source: grammarString)
        
        let ast = stlr.ast
        
        guard ast.rules.count == 1 else {
            XCTFail("Only \(ast.rules.count) rules created, expected 1")
            return
        }
        
        XCTAssert("\(ast.rules[0])" == "variableStart = .letters | \"_\"", "Malformed rule: \(ast.rules[0])")
        
        STLRIntermediateRepresentation.register(optimizer: CharacterSetOnlyChoiceOptimizer())
        ast.optimize()
        
        XCTAssert("\(ast.rules[0])" == "variableStart = (.letters|(\"_\"))", "Malformed rule: \(ast.rules[0])")
    }

    //
    // Effect: When the CharacterSet optimization is applied to a choice of a single character string
    // and a character set, the single character set is lost.
    //
    func testBadFolding() {
        let grammarString = "operators = \":=\" | \";\""
        
        let stlr = STLRParser(source: grammarString)
        
        let ast = stlr.ast
        
        guard ast.rules.count == 1 else {
            XCTFail("Only \(ast.rules.count) rules created, expected 1")
            return
        }
        
        XCTAssert("\(ast.rules[0])" == "operators = \":=\" | \";\"", "Malformed rule: \(ast.rules[0])")
        
        STLRIntermediateRepresentation.register(optimizer: CharacterSetOnlyChoiceOptimizer())
        ast.optimize()
        
        XCTAssert("\(ast.rules[0])" == "operators = \":=\" | \";\"", "Malformed rule: \(ast.rules[0])")
    }
    
    //
    // Effect: Rule annotation to report an error on missing terminal string is lost
    //
    func testLostAnnotation(){
        enum STLRStringTest : Int, Token {
            
            // Convenience alias
            private typealias T = STLRStringTest
            
            case _transient = -1, `stringQuote`, `escapedCharacters`, `escapedCharacter`, `stringCharacter`, `terminalBody`, `terminalString`
            
            func _rule(_ annotations: RuleAnnotations = [ : ])->Rule {
                switch self {
                case ._transient:
                    return CharacterSet(charactersIn: "").terminal(token: T._transient)
                // stringQuote
                case .stringQuote:
                    return "\"".terminal(token: T.stringQuote, annotations: annotations.isEmpty ? [:] : annotations)
                // escapedCharacters
                case .escapedCharacters:
                    return [
                        T.stringQuote._rule(),
                        "r".terminal(token: T._transient),
                        "n".terminal(token: T._transient),
                        "t".terminal(token: T._transient),
                        "\\".terminal(token: T._transient),
                        ].oneOf(token: T.escapedCharacters)
                // escapedCharacter
                case .escapedCharacter:
                    return [
                        "\\".terminal(token: T._transient),
                        T.escapedCharacters._rule(),
                        ].sequence(token: T.escapedCharacter, annotations: annotations.isEmpty ? [ : ] : annotations)
                // stringCharacter
                case .stringCharacter:
                    return [
                        T.escapedCharacter._rule(),
                        [
                            T.stringQuote._rule(),
                            CharacterSet.newlines.terminal(token: T._transient),
                            ].oneOf(token: T._transient).not(producing: T._transient),
                        ].oneOf(token: T.stringCharacter, annotations: [RuleAnnotation.void : RuleAnnotationValue.set])
                // terminalBody
                case .terminalBody:
                    return T.stringCharacter._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 1, producing: T.terminalBody, annotations: annotations)
                // terminalString
                case .terminalString:
                    return [
                        T.stringQuote._rule(),
                        T.terminalBody._rule([RuleAnnotation.error : RuleAnnotationValue.string("Terminals must have at least one character")]),
                        T.stringQuote._rule([RuleAnnotation.error : RuleAnnotationValue.string("Missing terminating quote")]),
                        ].sequence(token: T.terminalString, annotations: annotations.isEmpty ? [ : ] : annotations)
                }
            }
            
            // Create a language that can be used for parsing etc
            public static var generatedLanguage : Parser {
                return Parser(grammar: [T.terminalString._rule()])
            }
            
            // Convient way to apply your grammar to a string
            public static func parse(source: String) -> DefaultHeterogeneousAST {
                return STLRStringTest.generatedLanguage.build(source: source)
            }
        }

        let ast = STLRStringTest.parse(source: "\"h")
        
        XCTAssertEqual(1, ast.errors.count,"Expected unterminated string error")
    }
}
