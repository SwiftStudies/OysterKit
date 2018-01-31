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
import STLR


class STLRTest: XCTestCase {
    
    func prettyPrint(nodes contents:[HeterogeneousNode], from source:String , indent : String = ""){
        for node in contents {
            if node.children.count > 0 {
                print("\(indent)"+"\(node.token)")
                prettyPrint(nodes: node.children,from:source,  indent: indent+"\t")
            } else {
                print("\(indent)"+"\(node.token)"+" '\(String(source[node.range]).escaped)'")
            }
        }
    }
    
    func testBackslash(){
        let backSlash = ".backslash"
        
        let ruleSource = """
        id = \(backSlash) "x"
"""
        guard let testLanguage = STLRParser(source: ruleSource).ast.runtimeLanguage else {
            XCTFail("Could not compile")
            return
        }
        
        let source = "\\x"
        
        let ast : DefaultHeterogeneousAST = Parser(grammar: testLanguage.grammar).build(source: source)
        if ast.children.count != 1 {
            XCTFail("Expected one token")
            prettyPrint(nodes: ast.children, from: source)
            return
        }
        XCTAssertEqual(ast.children[0].token.rawValue, 1)
    }
    
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
