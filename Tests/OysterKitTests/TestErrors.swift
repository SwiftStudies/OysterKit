//
//  TestErrors.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import XCTest
import OysterKit

class TestErrors: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testStringRanges(){
        let string = "x"
        
        let startIndex = string.unicodeScalars.startIndex
        let endIndex = string.unicodeScalars.index(after: startIndex)
        
 //       let beyondEndIndex = string.unicodeScalars.index(after: endIndex)
        
        XCTAssert(string == String(string[startIndex..<endIndex]))
        //Disabling this check because I would have expected it to _always_ fail, it is now
        //throwing a fatal error
//        XCTAssert(string == String(string.unicodeScalars[startIndex..<beyondEndIndex]))
    }

    func testDescriptions() {
        struct DummyToken : TokenType {
            var rawValue: Int = 1
            
            
        }
        
        
        XCTAssert(GrammarError.notImplemented.description == "Operation not implemented")
        XCTAssert(GrammarError.noTokenCreatedFromMatch.description == "No token created from a match")
        XCTAssert(GrammarError.matchFailed(token:DummyToken()).description == "Match failed")
    }
}
