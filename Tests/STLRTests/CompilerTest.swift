//
//  CompilerTest.swift
//  STLRTests
//
//  Created by Nigel Hughes on 10/07/2018.
//

import XCTest
@testable import STLR
import OysterKit

class CompilerTest: XCTestCase {


    func testRegularExpressionBuild() {
        let terminalASN = ProductionSTLR.Terminal.regex(regex: "Cat")
        
        if let terminal = terminalASN.rule(with: Behaviour(.skipping), and: [:]) as? TerminalRule{
            if let regularExpression = terminal.terminal as? NSRegularExpression {
                XCTAssertEqual(regularExpression.pattern, "^Cat")
            } else {
                XCTFail("Should have generated an NSRegularExpression terminal")
            }
        } else {
            XCTFail("Should have generated a TerminalRule")
        }        
    }

}
