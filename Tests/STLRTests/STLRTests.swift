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
@testable import ExampleLanguages
@testable import STLR

fileprivate enum TestToken : Int, Token{
    case pass
}

let testGrammarName = "grammar STLRTest\n"

class STLRTest: XCTestCase {
    
    func testBackslash(){
        let backSlash = ".backslash"
        
        let ruleSource = """
        id = \(backSlash) "x"
"""
        guard let testLanguage = STLRParser(source: testGrammarName+ruleSource).ast.runtimeLanguage else {
            XCTFail("Could not compile")
            return
        }
        
        let source = "\\x"
        
        do {
            let ast = try AbstractSyntaxTreeConstructor().build(source, using: testLanguage)
            if ast.children.count != 0 {
                XCTFail("Expected one node, no children")
//                print(ast.description)
                return
            }
            XCTAssertEqual(ast.token.rawValue, 1)
        } catch {
            XCTFail("Parsing failed, but it should have succeeded")
        }
        
    }
    
    func testPinnedNodes(){

        
        let ruleSource = """
            letters = .letter+
            digits = .decimalDigit+

            pass = letters " " @pin @token("numbers") digits?
"""

        let stlr = STLRParser(source: testGrammarName+ruleSource)
        guard let testLanguage = stlr.ast.runtimeLanguage else {
            XCTFail("Compilation failed"); return
        }


//        print(stlr.ast.swift(grammar: "Test")!)
        
        var source = "abc 123"
        let ast = try! AbstractSyntaxTreeConstructor().build(source, using: testLanguage)
       
//        print(ast.description)
        XCTAssertNotNil(ast["letters"])
        XCTAssertNotNil(ast["numbers"])
        XCTAssertNil(ast["numbers"]?["digits"]) //Numbers should have directly subsumed the expression from digits, and not just wrapped the node
        XCTAssertEqual(ast["letters"]?.matchedString ?? "", "abc")
        XCTAssertEqual(ast["numbers"]?.matchedString ?? "", "123")

        
        // This should fail
        source = "abc "
        XCTAssertNil(try? AbstractSyntaxTreeConstructor().build(source, using: testLanguage))
    }
    
    func testVoidSugar(){
        let expectedAnnotations = [ RuleAnnotation.void : RuleAnnotationValue.set]
        let rule = "-identifier = -\"/\""
        let parser = STLRParser.init(source: testGrammarName+rule)

        guard let identifier = parser.ast.identifiers["identifier"] else {
            XCTFail("Rule was not compiled \(parser.ast.errors)")
            return
        }
        XCTAssertEqual(identifier.annotations.asRuleAnnotations,expectedAnnotations)
        
        if case let STLRScope.Expression.element(element) = identifier.grammarRule!.expression! {
            XCTAssertEqual(element.elementAnnotations.asRuleAnnotations, expectedAnnotations)
        } else {
            XCTFail("Expected the identifier element to be an element")
        }
    }
    
    func testTransientSugar(){
        let expectedAnnotations = [ RuleAnnotation.transient : RuleAnnotationValue.set]
        let rule = "~identifier = ~(\"/\")"
        let parser = STLRParser.init(source: testGrammarName+rule)
        
        guard let identifier = parser.ast.identifiers["identifier"] else {
            XCTFail("Rule was not compiled \(parser.ast.errors)")
            return
        }
        XCTAssertEqual(identifier.annotations.asRuleAnnotations,[ RuleAnnotation.transient : RuleAnnotationValue.set])
        
        if case let STLRScope.Expression.element(element) = identifier.grammarRule!.expression! {
            XCTAssertEqual(element.elementAnnotations.asRuleAnnotations, expectedAnnotations)
        } else {
            XCTFail("Expected the identifier element to be an element")
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

