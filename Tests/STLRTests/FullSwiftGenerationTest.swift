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
