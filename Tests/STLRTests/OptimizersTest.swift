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
        source.add(line: "x = @error(\"Expected X\")\"x\"")
        source.add(line: "xyz = x \"y\" \"z\"")

        STLRIntermediateRepresentation.register(optimizer: InlineIdentifierOptimization())
        let parser = STLRParser(source: source)
        
        guard let compiledLanguage = parser.ast.runtimeLanguage else {
            XCTFail("Could not compile")
            return
        }
        
        let result : DefaultHomogenousAST<HomogenousNode> = compiledLanguage.build(source: "yz")
        
        guard let error = result.errors.first else {
            XCTFail("Expected an error \(parser.ast.rules[0])")
            return
        }
        
        
        XCTAssert("\(error)".hasPrefix("Expected X"),"Incorrect error \(error)")
    }
    
}
