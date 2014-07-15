//
//  stateTestKeywords.swift
//  OysterKit Mac
//
//  Created by Nigel Hughes on 09/07/2014.
//  Copyright (c) 2014 RED When Excited Limited. All rights reserved.
//

import XCTest
import OysterKit

class stateTestKeywords: XCTestCase {

    var tokenizer = Tokenizer()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        tokenizer = Tokenizer()
    }

    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testKeywords() {
        tokenizer.branch(
            Keywords(validStrings: ["let","var","func"]).branch(
                    OysterKit.word.token("variable"),
                    Exit().token("keyword")
                ),
            OysterKit.word.token("variable"),
            OysterKit.blanks.clearToken(),
            Char(from:"=").token("assign"),
            Char(from:"+-*/").token("operator"),
            Char(from:";\n"),
            OysterKit.eot
        )
        
        let testString = "let a = b; let lettings = rental + lease; var variable = function;"
                
        // This is an example of a functional test case.
        XCTAssert(tokenizer.tokenize(testString) == [token("keyword",chars:"let"), token("variable",chars:"a"), token("assign",chars:"="), token("variable",chars:"b"), token("keyword",chars:"let"), token("variable",chars:"lettings"), token("assign",chars:"="), token("variable",chars:"rental"), token("operator",chars:"+"), token("variable",chars:"lease"), token("keyword",chars:"var"), token("variable",chars:"variable"), token("assign",chars:"="), token("variable",chars:"function"), ])
    }

}
