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
            let rules = try STLR.build("hello = .letter | .decimalDigit").grammar.rules
            
            guard rules.count == 1 else {
                XCTFail("Expected 1 rule")
                return
            }

            let helloRule = rules[0]

            XCTAssertNotNil(helloRule.expression.element?.terminal?.characterSet,"Expected the rule to have an expression with just an element")
            XCTAssertEqual("letter", helloRule.expression.element?.terminal?.characterSet?.characterSetName ?? "NILLED")
        } catch {
            XCTFail("Failed: \(error)")
        }
    }

}
