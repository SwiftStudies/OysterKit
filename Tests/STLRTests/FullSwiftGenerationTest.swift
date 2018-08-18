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
        let file = TextFile("Test.swift")
        let source = try! String(contentsOfFile: "/Users/nhughes/Documents/Code/SPM/OysterKit/Resources/OneOfEverythingGrammar.stlr")
        let stlr = try! _STLR.build(source)
        stlr.swift(in: file)
        let context = OperationContext(with: URL(fileURLWithPath: "/Users/nhughes/Desktop/")){
            print($0)
        }
        try! file.perform(in: context)
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
