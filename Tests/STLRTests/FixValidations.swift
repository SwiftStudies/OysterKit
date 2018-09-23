//
//  FixValidations.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import XCTest
@testable import OysterKit
@testable import STLR
@testable import TestingSupport

class FixValidations: XCTestCase {

    let testGrammarName = "grammar FixValidations\n"
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        ProductionSTLR.removeAllOptimizations()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    //
    // Effect: Quantifiers specified on one element could leak into another element (typically the next one along)
    // when an element evaluation failed. In this case the created 'import' rule would be 'import'* leaking the * from
    // .decimalDigits
    //
    func testQuantifierLeak() {
        let grammarString = testGrammarName+"number  = .decimalDigit*\n keyword = \"import\" | \"wibble\""
        
        do {
            let stlr = try ProductionSTLR.build(grammarString)
            
            let grammar = stlr.grammar
            
            guard grammar.rules.count == 2 else {
                XCTFail("Only \(grammar.rules.count) rules created, expected 2")
                return
            }
            
            XCTAssert("\(grammar.rules[0])" == "number = .decimalDigit*", "Malformed rule: \(grammar.rules[0])")
            XCTAssert("\(grammar.rules[1])" == "keyword = \"import\" | \"wibble\"", "Malformed rule: '\(grammar.rules[1])'")
        } catch {
            XCTFail("Unexpected failure: \(error)")
        }
    }

    //
    // https://github.com/SwiftStudies/OysterKit/issues/68
    //
    // Effect: When an identifier is inlined that was annotated with @void the resulting substituted Terminal looses
    // the void annotation
    //
    func testFixForIssue68() {
        let grammar = testGrammarName+"""
        @void inlined = "/"
        expr = inlined !inlined+ inlined
        """
        
        do {
            ProductionSTLR.register(optimizer: InlineIdentifierOptimization())
            let stlr = try ProductionSTLR.build(grammar)
            XCTAssertEqual(stlr.grammar .rules[1].description, "expr = inlined !inlined+ inlined")
        } catch {
            XCTFail("Unexpted failure: \(error)")
        }
        
    }

    //
    // Effect: When the CharacterSet optimization is applied to a choice of a single character string
    // and a character set, the single character set is lost.
    //
    func testBadFolding() {
        do {
            let grammarString = testGrammarName+"operators = \":=\" | \";\""
            
            let stlr = try ProductionSTLR.build(grammarString)
            
            let ast = stlr.grammar
            
            guard ast.rules.count == 1 else {
                XCTFail("Only \(ast.rules.count) rules created, expected 1")
                return
            }
            
            XCTAssert("\(ast.rules[0])" == "operators = \":=\" | \";\"", "Malformed rule: \(ast.rules[0])")
            
            ProductionSTLR.register(optimizer: CharacterSetOnlyChoiceOptimizer())
            ast.optimize()
            
            XCTAssert("\(ast.rules[0])" == "operators = \":=\" | \";\"", "Malformed rule: \(ast.rules[0])")
        } catch {
            XCTFail("Unexpted failure: \(error)")
        }
    }
    
    //
    // Effect: When an identifier instance is over-ridden with a new token name the result is a rule that
    // is a squence containing the overridden symbol. This is both inefficient and undesirable (as the
    // generated hierarchy has an additional layer
    //
    func testTokenOverride(){
        do {
            let source = testGrammarName+"""
            letter          = .letter
            doubleLetter    = letter "+" letter
            phrase          = doubleLetter .whitespace @token("doubleLetter2") doubleLetter
            """
            let compiled = try ProductionSTLR.build(source)
        
//            print()
            
            XCTAssertEqual(compiled.grammar["doubleLetter"].expression.description, compiled.grammar["doubleLetter2"].expression.description)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testErrorOnDeclaration(){
        #warning("Errors annotated on declarations are not thrown as specificErrors")
    }
        
    
    func testErrorOnRecursiveRule(){
        let rule = TestingSupport.STLRTokens.expression.rule.annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string("Expected expression"),RuleAnnotation.custom(label:"fatal"):RuleAnnotationValue.set])

        print(rule)
        
        do {
            _ = try AbstractSyntaxTreeConstructor(with: ".bogusCharacterSet").build(using: [rule])
            XCTFail("Should have failed")
        } catch let error as ProcessingError {
            print(error.debugDescription)
            if let error = error.filtered(including: [.fatal]){
                XCTAssertEqual((error.causedBy?.first as? ProcessingError)?.message ?? "", "Fatal Error: Expected expression")
                return
            }
            XCTFail("Incorrect error type")
        } catch {
            XCTFail("Incorrect error type")
        }
        
    }
}
