//
//  stateTestLoop.swift
//  OysterKit Mac
//
//  Created by Nigel Hughes on 09/07/2014.
//  Copyright (c) 2014 RED When Excited Limited. All rights reserved.
//

import XCTest
import OysterKit

class stateTestLoop: XCTestCase {
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

    func testLoop() {

        tokenizer.branch(
            OysterKit.whiteSpaces,
            __Loop(state: Char(from: lowerCaseLetterString+upperCaseLetterString)).token("word"),
            OysterKit.eot
        )
        
        let testString = "The quick brown fox jumps over the lazy dog"
        
        dump(tokenizer,testString)
        
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
    }
    
    func testLoopingChar() {
        
        tokenizer.branch(
            OysterKit.whiteSpaces,
            LoopingChar(from: lowerCaseLetterString+upperCaseLetterString).token("word"),
            OysterKit.eot
        )
        
        let testString = "The quick brown fox jumps over the lazy dog"

        XCTAssert(tokenizer.tokenize(testString) == [token("word",chars:"The"), token("whitespace",chars:" "), token("word",chars:"quick"), token("whitespace",chars:" "), token("word",chars:"brown"), token("whitespace",chars:" "), token("word",chars:"fox"), token("whitespace",chars:" "), token("word",chars:"jumps"), token("whitespace",chars:" "), token("word",chars:"over"), token("whitespace",chars:" "), token("word",chars:"the"), token("whitespace",chars:" "), token("word",chars:"lazy"), token("whitespace",chars:" "), token("word",chars:"dog"), ])    }


}
