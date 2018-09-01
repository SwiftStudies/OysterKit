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

fileprivate enum STLRStringTest : Int, TokenType {
    
    // Convenience alias
    private typealias T = STLRStringTest
    
    private static var regularExpressionCache = [String : NSRegularExpression]()
    
    /// Returns a pre-compiled pattern from the cache, or if not in the cache builds
    /// the pattern, caches and returns the regular expression
    ///
    /// - Parameter pattern: The pattern the should be built
    /// - Returns: A compiled version of the pattern
    ///
    private static func regularExpression(_ pattern:String)->NSRegularExpression{
        if let cached = regularExpressionCache[pattern] {
            return cached
        }
        do {
            let new = try NSRegularExpression(pattern: pattern, options: [])
            regularExpressionCache[pattern] = new
            return new
        } catch {
            fatalError("Failed to compile pattern /\(pattern)/\n\(error)")
        }
    }
    case _transient = -1, `stringQuote`, `terminalBody`, `terminalString`
    var rule : Rule {
        switch self {
        case ._transient:
            return ~CharacterSet(charactersIn: "")
        /// stringQuote
        case .stringQuote:
            return "\"".reference(.structural(token: self))
            
        /// terminalBody
        case .terminalBody:
            return T.regularExpression("^(\\\\.|[^\"\\\\\\n])+").reference(.structural(token: self))
            
        /// terminalString
        case .terminalString:
            return [    -T.stringQuote.rule,    T.terminalBody.rule.annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string("Terminals must have at least one character")]),    -T.stringQuote.rule.annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string("Missing terminating quote")])].sequence.reference(.structural(token: self))
        }
    }
    
    // Create a language that can be used for parsing etc
    static var generatedLanguage : Parser {
        return Parser(grammar: [T.terminalString.rule])
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
            // Adding a token because by default it's skipping
            let ast = try test(STLRStringTest.terminalBody.rule.scan(), with: source)
            print(ast.description)
            XCTAssertEqual(String(source.dropLast()), ast.matchedString)
        } catch {
            XCTFail("Match should not have thrown: \(error)")
        }
    }
    
    func testNotStringCharacter(){
        let characters = ["\"","\n"]
        
        for character in characters {
            do {
                _ = try test(STLRStringTest.terminalBody.rule, with: character)
                XCTFail("Match should not have passed for \(character.debugDescription)")
            } catch {
            }
        }
    }
    
    func testStringCharacter(){
        let characters = ["\\r","\\n","\\t","\\\"","\\\\"]
        
        for character in characters {
            do {
                print(try test(STLRStringTest.terminalBody.rule, with: "\\\(character)").description)
            } catch {
                XCTFail("Match should not have thrown for \(character): \(error)")
            }
        }
    }
    
    func testStringQuote(){
        do {
            let ast = try test(STLRStringTest.stringQuote.rule, with: "\"")

            XCTAssertEqual(ast.matchedString, "\"")
        } catch {
            XCTFail("Match should not have thrown: \(error)")
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
            XCTAssertTrue("\(errors[0])".hasPrefix("Parsing Error: Missing terminating quote at 2"))
        } catch {
            XCTFail("Unexpected error \(error)")
        }
        
    }
}
