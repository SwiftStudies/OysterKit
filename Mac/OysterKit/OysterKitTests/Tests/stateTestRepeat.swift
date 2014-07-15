//
//  stateTestRepeat.swift
//  OysterKit Mac
//
//  Created by Nigel Hughes on 03/07/2014.
//  Copyright (c) 2014 RED When Excited Limited. All rights reserved.
//

import XCTest
import OysterKit

class stateTestRepeat: XCTestCase {
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

    func testRepeat2HexDigits(){
        //Test for 2
        tokenizer.branch(
            Repeat(state:OysterKit.hexDigit, min:2,max:2).token("xx"),
            OysterKit.eot
        )
        
        __debugScanning = true
        dump(tokenizer,"AF")
        __debugScanning = false
        
        XCTAssert(tokenizer.tokenize("AF") == [token("xx",chars:"AF")])
        XCTAssert(tokenizer.tokenize("A") != [token("xx",chars:"A")])
        XCTAssert(tokenizer.tokenize("AF00") == [token("xx",chars:"AF"),token("xx",chars:"00")])
    }
    
    func testRepeat4HexDigits(){
        tokenizer.branch(
            Repeat(state:OysterKit.hexDigit, min:4,max:4).token("xx"),
            OysterKit.eot
        )
        
        XCTAssert(tokenizer.tokenize("AF00") == [token("xx",chars:"AF00")])
    }
    
    func testRepeatXYFixed1(){
        tokenizer.branch(
            Repeat(state:char("x").sequence(char("y").token("xy")),min:3,max:3).token("xyxyxy")
        )
        
        XCTAssert(tokenizer.tokenize("xyxyxy") == [token("xyxyxy")])
    }
    
    func testRepeatXYFixed2(){
        
        tokenizer.branch(
            Repeat(state:Branch().branch(
                sequence(char("x"),char("y").token("xy"))
                ),min:3,max:3).token("xyxyxy"),
            OysterKit.eot
        )
        
        XCTAssert(tokenizer.tokenize("xyxyxy") == [token("xyxyxy")])
    }

    func testSentance(){
        tokenizer.branch(
            OysterKit.word,
            OysterKit.whiteSpaces,
            OysterKit.eot
        )
        
        XCTAssert(tokenizer.tokenize("Quick fox") == [token("word",chars: "Quick"), token("whitespace",chars: " "),token("word",chars: "fox")])
    }
    
}
