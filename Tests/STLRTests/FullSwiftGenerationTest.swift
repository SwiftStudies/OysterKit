//
//  FullSwiftGenerationTest.swift
//  OysterKitTests
//
//  Created on 15/07/2018.
//

import XCTest
import OysterKit
@testable import ExampleLanguages

class FullSwiftGenerationTest: XCTestCase {


    func testExample() {
        func build(_ source : String) throws ->IR.Grammar  {
            
            let intermediateRepresentation = try AbstractSyntaxTreeConstructor().build(source, using: IRTokens.generatedLanguage)
            
            print(intermediateRepresentation.description)
            
            return try ParsingDecoder().decode(IR.Grammar.self, using: intermediateRepresentation)
        }
        
        do {
            for rule in try build("hello = .letter").rule{
                rule.expression.element!
                print(rule.expression.element.debugDescription)
            }
        } catch {
            print("\(error)")
        }
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

}
