//
//  standardTokensTest.swift
//  OysterKit Mac
//
//  Created by Nigel Hughes on 03/07/2014.
//  Copyright (c) 2014 RED When Excited Limited. All rights reserved.
//

import XCTest
import OysterKit

class standardTokensTest: XCTestCase {

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

    func testNumber(){

        
        tokenizer.branch(
            OKStandard.number,
            OKStandard.eot
        )
        
        let testStrings = [
            "1.5" : "float",
            "1" : "integer",
            "-1" : "integer",
            "+1" : "integer",
            "+10" : "integer",
            "1.5e10" : "float",
            "-1.5e10": "float",
            "-1.5e-10": "float",
        ]

        let newTokenizer = Tokenizer(states: [
            OKStandard.number,
            OKStandard.eot
            ])
        
        
        for (number, token) in testStrings {
            var tokens:Array<Token> = newTokenizer.tokenize(number)
            
            XCTAssert(tokens.count == 1, "Failed to generate "+token+" from "+number+", exactly one token should have been created")

            if tokens.count > 0 {
                let actualToken:Token = tokens[0]
                
                XCTAssert(actualToken.name == token, "Failed to generate "+token+" from "+number+", instead received "+actualToken.description)                
            }
        }
    }
    
    func testSimpleString(){
        tokenizer.branch(
            OKStandard.blanks,
            OKStandard.number,
            OKStandard.word,
            OKStandard.eot
        )
        
        let parsingTest = "Short 10 string"
        
        
        XCTAssert(tokenizer.tokenize(parsingTest) == [token("word",chars:"Short"), token("blank",chars:" "), token("integer",chars:"10"), token("blank",chars:" "), token("word",chars:"string"), ])
    }
    
    func testWhiteSpaces(){
        tokenizer.branch(
            OKStandard.Code.quotedStringIncludingQuotes,
            OKStandard.whiteSpaces,
            OKStandard.number,
            OKStandard.word,
            OKStandard.punctuation,
            OKStandard.eot
        )

        let parsingTest = "Short\tlittle\nstring that\n tries \tto  break \n\tthings         up"
        
        __debugScanning = true
        let tokens = tokenizer.tokenize(parsingTest)
        assertTokenListsEqual(tokens, reference: [token("word",chars:"Short"), token("whitespace",chars:"\t"), token("word",chars:"little"), token("whitespace",chars:"\n"), token("word",chars:"string"), token("whitespace",chars:" "), token("word",chars:"that"), token("whitespace",chars:"\n "), token("word",chars:"tries"), token("whitespace",chars:" \t"), token("word",chars:"to"), token("whitespace",chars:"  "), token("word",chars:"break"), token("whitespace",chars:" \n\t"), token("word",chars:"things"), token("whitespace",chars:"         "), token("word",chars:"up"), ])
        __debugScanning = false
    }
    
    func testQuotedString(){
        tokenizer.branch(
            OKStandard.Code.quotedStringIncludingQuotes,
            OKStandard.blanks,
            OKStandard.number,
            OKStandard.word,
            OKStandard.punctuation,
            OKStandard.eot
        )

        let parsingTest = "A great man once said \"It is a far better thing that I do now than I have ever done\". "

        assertTokenListsEqual(tokenizer.tokenize(parsingTest), reference: [token("word",chars:"A"), token("blank",chars:" "), token("word",chars:"great"), token("blank",chars:" "), token("word",chars:"man"), token("blank",chars:" "), token("word",chars:"once"), token("blank",chars:" "), token("word",chars:"said"), token("blank",chars:" "), token("double-quote",chars:"\""), token("quoted-string",chars:"It is a far better thing that I do now than I have ever done"), token("double-quote",chars:"\""), token("punct",chars:"."), token("blank",chars:" "), ])
    }
}
