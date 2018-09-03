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
@testable import TestingSupport
@testable import STLR

fileprivate enum TestToken : Int, TokenType{
    case pass
}

let testGrammarName = "grammar STLRTest\n"

class STLRTest: XCTestCase {
    
    func testBackslash(){
        do {
            let backSlash = ".backslash"
            
            let ruleSource = """
            id = \(backSlash) "x"
            """
            let testLanguage = try ProductionSTLR.build(testGrammarName+ruleSource).grammar.dynamicRules

            let source = "\\x"
            
            do {
                let ast = try AbstractSyntaxTreeConstructor().build(source, using: testLanguage)
                if ast.children.count != 0 {
                    XCTFail("Expected one node, no children")
                    //                print(ast.description)
                    return
                }
                XCTAssertEqual("\(ast.token)", "id")
            } catch {
                XCTFail("\(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
    }
    
    func testVoidSugar(){
        do {
            let rule = "-identifier = -\"/\""
            let parser = try ProductionSTLR.build(testGrammarName+rule)
            
            let identifier = parser.grammar["identifier"]
            
            XCTAssert(identifier.isVoid)
            
            if case let ProductionSTLR.Expression.element(element) = identifier.expression {
                XCTAssert(element.isVoid)
            } else {
                XCTFail("Expected the identifier element to be an element")
            }

        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testTransientSugar(){
        do {
            let rule = "~identifier = ~(\"/\")"
            let parser = try ProductionSTLR.build(testGrammarName+rule)
            
            let identifier = parser.grammar["identifier"]
            
            XCTAssert(identifier.isTransient)
            
            if case let ProductionSTLR.Expression.element(element) = identifier.expression {
                XCTAssert(element.isTransient)
            } else {
                XCTFail("Expected the identifier element to be an element")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExpressionGroupExpressionElement(){
        do {
            let rule = "identifier = (.letter)"
            _ = try ProductionSTLR.build(testGrammarName+rule)            
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testParseSelf(){
////        for bundle in Bundle.allBundles{
////            print("BUNDLE PATH: \(bundle)")
////        }
//        
//        if let _ = try? String(contentsOfFile: "/Volumes/Personal/SPM/OysterKit/Resources/STLR.stlr") {
//            let source = """
//            @void a = "a"
//            b = "b"
//            ab= a b
//            """
//            
//            let compiledScope = STLRScope(building: source)
//            
//            compiledScope.errors.forEach(){
//                XCTFail("\($0)")
//            }
//            
////            compiledScope.rules.forEach(){
////                print($0.description)
////            }
//            
////            print(compiledScope.swift(grammar: "Test")!)
//        } else {
//            XCTFail("Could not load source")
//        }

    }
    
    var allTests : [(()->Void)]{
        return [
            testParseSelf
        ]
    }
    
}

