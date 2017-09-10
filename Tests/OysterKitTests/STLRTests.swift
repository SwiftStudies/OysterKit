//
//  STLRTests.swift
//  OysterKitTests
//
//  Created  on 06/09/2017.
//  Copyright © 2017 RED When Excited. All rights reserved.
//

import Foundation

import XCTest
@testable import OysterKit


class STLRTest: XCTestCase {
    
    func testPinnedNodes(){
        enum TestToken : Int, Token{
            case pass
        }
        
        let ruleSource = """
            letters = .letters+
            digits = .decimalDigits+

            pass = letters " " @pin @token("numbers") digits?
"""

        let stlr = STLRParser(source: ruleSource)
        guard let testLanguage = stlr.ast.runtimeLanguage else {
            XCTFail("Compilation failed"); return
        }


        print(stlr.ast.swift(grammar: "Test")!)
        
        var source = "abc 123"
        var ast : DefaultHeterogeneousAST = Parser(grammar: testLanguage.grammar).build(source: source)
       
        prettyPrint(nodes: ast.children, from: source)
        
        XCTAssertNotNil(ast.children.first?.token , "Basic parsing did not work")

        source = "abc "
        ast = Parser(grammar: testLanguage.grammar).build(source: source)

        prettyPrint(nodes: ast.children, from: source)

        XCTAssert(ast.children.first?.children[0].matchedString(source) ?? "fail" == "abc" , "Letters node does not exist or contains the wrong value")

        
        
        print("Done")
    }
    
}
