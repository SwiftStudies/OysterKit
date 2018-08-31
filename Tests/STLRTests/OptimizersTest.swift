//
//  OptimizersTest.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import XCTest
import OysterKit
import STLR

class OptimizersTest: GrammarTest {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        _STLR.removeAllOptimizations()
    }
    
    func testAttributePreservationOnInline(){
        do {
            source += """
            grammar Test
            x = @error("Expected X") "x"
            xyz = x "y" "z"
            """
            
            _STLR.register(optimizer: InlineIdentifierOptimization())
            let parser = try _STLR.build(source)
            
            let compiledLanguage = Parser(grammar: parser.grammar.dynamicRules) 
            
            do {
                let _ = try AbstractSyntaxTreeConstructor().build("yz", using: compiledLanguage)
            } catch AbstractSyntaxTreeConstructor.ConstructionError.constructionFailed(let errors) {
                guard let error = errors.first else {
                    XCTFail("Expected an error \(parser.grammar.rules[1])")
                    return
                }
                XCTAssert("\(error)".contains("Expected X"),"Incorrect error \(error)")
            } catch {
                XCTFail("Unexpected error \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
}
