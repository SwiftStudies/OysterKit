//
//  stateTestDelimeter.swift
//  OysterKit Mac
//
//  Created by Nigel Hughes on 03/07/2014.
//  Copyright (c) 2014 RED When Excited Limited. All rights reserved.
//

import XCTest
import OysterKit

class stateTestDelimeter: XCTestCase {
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

    func testSimple() {
        tokenizer.branch(
            Delimited(delimiter: "\"", states:OKStandard.letter).token("quoted-string"),
            OKStandard.eot
        )
        
        // This is an example of a functional test case.
        let testString = "\"Hello\""
        XCTAssert(tokenizer.tokenize(testString).count == testString.characters.count)
    }
    
    
    func testNestedQuotedString(){
        let tougherTest = "1.5 Nasty example with -10 or 10.5 maybe even 1.0e-10 \"Great \\(variableName) \\t 🐨 \\\"Nested\\\" quote\"!"
        
        tokenizer.branch(
            Delimited(delimiter:"\"",states:
                char("\\").branch(
                    char("t\"").token("character"),
                    Delimited(open:"(",close:")",states:OKStandard.word).token("inline")
                ),
                Characters(except:"\"").token("character")
                ).token("quoted-string"),
            OKStandard.blanks,
            OKStandard.number,
            OKStandard.word,
            OKStandard.punctuation,
            OKStandard.eot
        )
        
        
        assertTokenListsEqual(tokenizer.tokenize(tougherTest), reference: [token("float",chars:"1.5"), token("blank",chars:" "), token("word",chars:"Nasty"), token("blank",chars:" "), token("word",chars:"example"), token("blank",chars:" "), token("word",chars:"with"), token("blank",chars:" "), token("integer",chars:"-10"), token("blank",chars:" "), token("word",chars:"or"), token("blank",chars:" "), token("float",chars:"10.5"), token("blank",chars:" "), token("word",chars:"maybe"), token("blank",chars:" "), token("word",chars:"even"), token("blank",chars:" "), token("float",chars:"1.0e-10"), token("blank",chars:" "), token("quoted-string",chars:"\""), token("character",chars:"G"), token("character",chars:"r"), token("character",chars:"e"), token("character",chars:"a"), token("character",chars:"t"), token("character",chars:" "), token("inline",chars:"\\("), token("word",chars:"variableName"), token("inline",chars:")"), token("character",chars:" "), token("character",chars:"\\t"), token("character",chars:" "), token("character",chars:"🐨"), token("character",chars:" "), token("character",chars:"\\\""), token("character",chars:"N"), token("character",chars:"e"), token("character",chars:"s"), token("character",chars:"t"), token("character",chars:"e"), token("character",chars:"d"), token("character",chars:"\\\""), token("character",chars:" "), token("character",chars:"q"), token("character",chars:"u"), token("character",chars:"o"), token("character",chars:"t"), token("character",chars:"e"), token("quoted-string",chars:"\""), token("punct",chars:"!"), ])        
    }

}
