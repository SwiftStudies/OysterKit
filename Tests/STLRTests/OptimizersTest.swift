//
//  OptimizersTest.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import XCTest
import OysterKit
@testable import STLR

class OptimizersTest: GrammarTest {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        ProductionSTLR.removeAllOptimizations()
    }

    func testAttributePreservationOnInlineReference(){
        do {
            source += """
            grammar Test
            x = "x"
            xyz = @error("Expected X") x "y" "z"
            """
            
            ProductionSTLR.register(optimizer: InlineIdentifierOptimization())
            let parser = try ProductionSTLR.build(source)
            
            let compiledLanguage = parser.grammar.dynamicRules
            
            do {
                let _ = try AbstractSyntaxTreeConstructor().build("yz", using: compiledLanguage)
            } catch let error as ProcessingError {
                XCTAssertNotNil(error.filtered(includingMessagesMatching: ".*Expected X.*"))
            } catch {
                XCTFail("Unexpected error \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testAttributePreservationOnInline(){
        do {
            source += """
            grammar Test
            x = @error("Expected X") "x"
            xyz = x "y" "z"
            """
            
            ProductionSTLR.register(optimizer: InlineIdentifierOptimization())
            let parser = try ProductionSTLR.build(source)
            
            let compiledLanguage = parser.grammar.dynamicRules 
            
            do {
                let _ = try AbstractSyntaxTreeConstructor().build("yz", using: compiledLanguage)
            } catch let error as ProcessingError {
                XCTAssertNotNil(error.filtered(includingMessagesMatching: ".*Expected X.*"))
            } catch {
                XCTFail("Unexpected error \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
}
