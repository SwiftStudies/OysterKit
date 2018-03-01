//
//  FixValidations.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import XCTest
@testable import OysterKit
import STLR

class FixValidations: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        STLRScope.removeAllOptimizations()
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
        let grammarString = "number  = .decimalDigit*\n keyword = \"import\" | \"wibble\""
        
        let stlr = STLRParser(source: grammarString)
        
        let ast = stlr.ast
        
        guard ast.rules.count == 2 else {
            XCTFail("Only \(ast.rules.count) rules created, expected 2")
            return
        }
        
        XCTAssert("\(ast.rules[0])" == "number = .decimalDigits*", "Malformed rule: \(ast.rules[0])")
        XCTAssert("\(ast.rules[1])" == "keyword = \"import\" | \"wibble\"", "Malformed rule: '\(ast.rules[1])'")
    }

    //
    // Effect: When the CharacterSet optimization is applied to a choice of a single character string
    // and a character set, the single character set is lost.
    //
    func testCharacterSetOmmision() {
        let grammarString = "variableStart = .letter | \"_\""
        
        let stlr = STLRParser(source: grammarString)
        
        let ast = stlr.ast
        
        guard ast.rules.count == 1 else {
            XCTFail("Only \(ast.rules.count) rules created, expected 1")
            return
        }
        
        XCTAssert("\(ast.rules[0])" == "variableStart = .letters | \"_\"", "Malformed rule: \(ast.rules[0])")
        
        STLRScope.register(optimizer: CharacterSetOnlyChoiceOptimizer())
        ast.optimize()
        
        XCTAssert("\(ast.rules[0])" == "variableStart = (.letters|(\"_\"))", "Malformed rule: \(ast.rules[0])")
    }

    //
    // Effect: When the CharacterSet optimization is applied to a choice of a single character string
    // and a character set, the single character set is lost.
    //
    func testBadFolding() {
        let grammarString = "operators = \":=\" | \";\""
        
        let stlr = STLRParser(source: grammarString)
        
        let ast = stlr.ast
        
        guard ast.rules.count == 1 else {
            XCTFail("Only \(ast.rules.count) rules created, expected 1")
            return
        }
        
        XCTAssert("\(ast.rules[0])" == "operators = \":=\" | \";\"", "Malformed rule: \(ast.rules[0])")
        
        STLRScope.register(optimizer: CharacterSetOnlyChoiceOptimizer())
        ast.optimize()
        
        XCTAssert("\(ast.rules[0])" == "operators = \":=\" | \";\"", "Malformed rule: \(ast.rules[0])")
    }
}
