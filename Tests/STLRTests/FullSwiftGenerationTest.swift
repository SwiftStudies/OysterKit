//
//  FullSwiftGenerationTest.swift
//  OysterKitTests
//
//  Created on 15/07/2018.
//

import XCTest
import OysterKit
@testable import STLR
@testable import ExampleLanguages

class FullSwiftGenerationTest: XCTestCase {

    func testGeneratedCode(){
        #warning("This should go")
        do {
            let source = try String(contentsOfFile: "/Users/nhughes/Documents/Code/SPM/OysterKit/Resources/STLR.stlr")
            let stlr = try _STLR.build(source)
            
            let operations = try SwiftStructure.generate(for: stlr, grammar: "Test", accessLevel: "public")
            
            let context = OperationContext(with: URL(fileURLWithPath: "/Users/nhughes/Desktop/")){
                print($0)
            }
            
            for operation in operations {
                try operation.perform(in: context)
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    func testOldGeneratedCode(){
        #warning("This should go")

        do {
            let source = try String(contentsOfFile: "/Users/nhughes/Documents/Code/SPM/OysterKit/Resources/STLR.stlr")
            let stlr = STLRParser(source: source)
            
            let operations = try SwiftStructure.generate(for: stlr.ast, grammar: "Test", accessLevel: "public")
            
            let context = OperationContext(with: URL(fileURLWithPath: "/Users/nhughes/Desktop/")){
                print($0)
            }
            
            for operation in operations {
                try operation.perform(in: context)
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    func testGeneratedIR() {
        do {
            let rules = try STLR.build("hello = .letter").grammar.rules
            
            guard rules.count == 1 else {
                XCTFail("Expected 1 rule")
                return
            }

            let helloRule = rules[0]
            
            if case let .element(element) = helloRule.expression {
                if case .characterSet(let characterSet) = element.terminal ?? STLR.Terminal.regex(regex: "") {
                    XCTAssertEqual(STLR.CharacterSetName.letter, characterSet.characterSetName)
                } else {
                    XCTAssertNotNil("Expected a character set terminal")
                }
            } else {
                XCTFail("Expected the hello rule to create an element expression")
            }
            
        } catch {
            XCTFail("Failed: \(error)")
        }
    }

}
