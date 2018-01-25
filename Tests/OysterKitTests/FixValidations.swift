//
//  FixValidations.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import XCTest
@testable import OysterKit

class FixValidations: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
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
