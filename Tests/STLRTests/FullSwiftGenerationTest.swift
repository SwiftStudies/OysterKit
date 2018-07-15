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
        do {
            for rule in try IR.build("hello = .letter").grammar.rule{
                rule.expression.element!
                print(rule.expression.element.debugDescription)
            }
        } catch {
            XCTFail("Failed: \(error)")
        }
    }

}
