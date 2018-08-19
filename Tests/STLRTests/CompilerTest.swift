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
        let terminalASN = STLRAbstractSyntaxTree.Terminal(regex: "Cat", terminalString: nil, characterSet: nil, characterRange: nil)
        
        let terminal = terminalASN.build()
        
        
        
        XCTAssertEqual(terminal.regex?.pattern ?? "FAIL", "^Cat")
    }

}
