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
        STLRIntermediateRepresentation.removeAllOptimizations()
    }
    
    func testAttributePreservationOnInline(){
        source += """
            x = @error("Expected X") "x"
            xyz = x "y" "z"
        """

        STLRIntermediateRepresentation.register(optimizer: InlineIdentifierOptimization())
        let parser = STLRParser(source: source)
        
        guard let compiledLanguage = parser.ast.runtimeLanguage else {
            XCTFail("Could not compile")
            return
        }
        
        do {
            let _ = try AbstractSyntaxTreeConstructor().build("yz", using: compiledLanguage)
        } catch AbstractSyntaxTreeConstructor.ConstructionError.parsingFailed(let errors) {
            guard let error = errors.first else {
                XCTFail("Expected an error \(parser.ast.rules[1])")
                return
            }
            XCTAssert("\(error)".hasPrefix("Expected X"),"Incorrect error \(error)")
        } catch {
            XCTFail("Unexpected error \(error)")
        }        
    }
    
}
