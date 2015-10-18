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
    let tokenizer = Tokenizer()

    func testRepeat2HexDigits(){
        //Test for 2
        tokenizer.branch(
            Repeat(state:OKStandard.hexDigit, min:2,max:2).token("xx"),
            OKStandard.eot
        )
                
        XCTAssert(tokenizer.tokenize("AF") == [token("xx",chars:"AF")])
        XCTAssert(tokenizer.tokenize("A") != [token("xx",chars:"A")])
        XCTAssert(tokenizer.tokenize("AF00") == [token("xx",chars:"AF"),token("xx",chars:"00")])
    }

    func testRepeat4HexDigits(){
        tokenizer.branch(
            Repeat(state:OKStandard.hexDigit, min:4,max:4).token("xx"),
            OKStandard.eot
        )
        
        XCTAssert(tokenizer.tokenize("AF00") == [token("xx",chars:"AF00")])
    }

    func testRepeatXYFixed1() {
        let x = char("x").sequence(char("y").token("xy"))
        tokenizer.branch(Repeat(state: x, min: 3, max: 3).token("xyxyxy"))
        XCTAssert(tokenizer.tokenize("xyxyxy") == [token("xyxyxy")])
    }

    func testRepeatXYFixed2(){
        let branch = Branch().branch(sequence(char("x"),char("y").token("xy")))
        tokenizer.branch(
            Repeat(state:branch,min:3,max:3).token("xyxyxy"),
            OKStandard.eot
        )
        
        XCTAssert(tokenizer.tokenize("xyxyxy") == [token("xyxyxy")])
    }

    func testSentance(){
        tokenizer.branch(
            OKStandard.word,
            OKStandard.whiteSpaces,
            OKStandard.eot
        )
        
        XCTAssert(tokenizer.tokenize("Quick fox") == [token("word",chars: "Quick"), token("whitespace",chars: " "),token("word",chars: "fox")])
    }
    
}
