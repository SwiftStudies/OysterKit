//
//  FixValidations.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import XCTest
@testable import OysterKit
@testable import ExampleLanguages

fileprivate enum STLRStringTest : Int, Token {
    
    // Convenience alias
    private typealias T = STLRStringTest
    
    case _transient = -1, `stringQuote`, `escapedCharacters`, `escapedCharacter`, `stringCharacter`, `terminalBody`, `terminalString`
    
    func _rule(_ annotations: RuleAnnotations = [ : ])->BehaviouralRule {
        switch self {
        case ._transient:
            return ~CharacterSet(charactersIn: "")
        // stringQuote
        case .stringQuote:
            return "\"".parse(as:T.stringQuote).annotatedWith(annotations)
        // escapedCharacters
        case .escapedCharacters:
            return [
                T.stringQuote._rule(),
                ~"r",
                ~"n",
                ~"t",
                ~"\\",
                ].choice.parse(as: self).annotatedWith(annotations)
        // escapedCharacter
        case .escapedCharacter:
            return [
                ~"\\",
                T.escapedCharacters._rule(),
                ].sequence.parse(as:self).annotatedWith(annotations)
        // stringCharacter
        case .stringCharacter:
            return -[
                T.escapedCharacter._rule(),
                    ~(![
                        T.stringQuote._rule(),
                        ~CharacterSet.newlines,
                    ].choice),
                ].choice
        // terminalBody
        case .terminalBody:
            return T.stringCharacter._rule().instanceWith(with: Behaviour(.skipping, cardinality: .oneOrMore))
        // terminalString
        case .terminalString:
            return [
                T.stringQuote._rule(),
                T.terminalBody._rule([RuleAnnotation.error : RuleAnnotationValue.string("Terminals must have at least one character")]),
                T.stringQuote._rule([RuleAnnotation.error : RuleAnnotationValue.string("Missing terminating quote")]) ,
                ].sequence.parse(as:self).annotatedWith(annotations)

        }
    }
    
    // Create a language that can be used for parsing etc
    static var generatedLanguage : Parser {
        return Parser(grammar: [T.terminalString._rule()])
    }
    
    // Convient way to apply your grammar to a string
    static func parse(source: String) throws -> HomogenousTree {
        return try AbstractSyntaxTreeConstructor().build(source, using: STLRStringTest.generatedLanguage)
    }
}



class FixValidations: XCTestCase {

    func testTerminalBody(){
        let source = "This is the body of a string \\\" that ends here\""
        do {
            let result = try test(STLRStringTest.terminalBody._rule(), with: source)
            guard case let .consume(context) = result else {
                XCTFail("Result should have been success but was \(result)")
                return
            }
            XCTAssertEqual(source[context.range.upperBound..<source.unicodeScalars.endIndex], "\"")
        } catch {
            XCTFail("Match should not have thrown: \(error)")
        }
    }
    
    func testNotStringCharacter(){
        let characters = ["\"","\n","\r"]
        
        for character in characters {
            do {
                _ = try test(STLRStringTest.stringCharacter._rule(), with: character)
                XCTFail("Match should not have passed for \(character.debugDescription)")
            } catch {
            }
        }
    }
    
    func testStringCharacter(){
        let characters = ["\\r","\\n","\\t","\\\"","\\\\"]
        
        for character in characters {
            do {
                let result = try test(STLRStringTest.stringCharacter._rule(), with: "\\\(character)")
                guard case .consume(_) = result else {
                    XCTFail("Result should have been success but was \(result) for \(character)")
                    continue
                }
            } catch {
                XCTFail("Match should not have thrown for \(character): \(error)")
            }
        }
    }
    
    func testStringQuote(){
        do {
            let result = try test(STLRStringTest.stringQuote._rule(), with: "\"")
            guard case let .success(context) = result else {
                XCTFail("Result should have been success but was \(result)")
                return
            }
            XCTAssertEqual(context.matchedString, "\"")
        } catch {
            XCTFail("Match should not have thrown: \(error)")
        }
    }
    
    func testEscapedCharacter(){
        let characters = ["r","n","t","\"","\\"]
        
        for character in characters {
            do {
                let result = try test(STLRStringTest.escapedCharacter._rule(), with: "\\\(character)")
                guard case let .success(context) = result else {
                    XCTFail("Result should have been success but was \(result) for \(character)")
                    return
                }
                XCTAssertEqual(context.matchedString, "\\\(character)")
            } catch {
                XCTFail("Match should not have thrown for \(character): \(error)")
            }
        }
    }
    
    //
    // Effect: Rule annotation to report an error on missing terminal string is lost
    //
    func testLostAnnotation(){

        do{
            let _ = try STLRStringTest.parse(source: "\"h\n")
            XCTFail("Expected unterminated string error" )
        } catch AbstractSyntaxTreeConstructor.ConstructionError.constructionFailed(let errors) {
            XCTAssertEqual(errors.count, 1)
            XCTAssertTrue("\(errors[0])".hasPrefix("Missing terminating quote"))
        } catch {
            XCTFail("Unexpected error \(error)")
        }
        
    }
}
