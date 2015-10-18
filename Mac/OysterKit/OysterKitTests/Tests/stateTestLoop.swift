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
    let tokenizer = Tokenizer()

    func testLoopingCharDelimitedString(){
        let x =  OysterKit.Branch().branch(
                            Characters(from:"\\").branch(
                                Characters(from:"trn\"\\").token("character")
                            ),
                            LoopingCharacters(except: "\"\\").token("character")
                            )
        tokenizer.branch(
            Delimited(delimiter: "\"", states:
                Repeat(state: x, min: 1, max: nil).token("Char")
                ).token("quote"),
            LoopingCharacters(except: "\u{04}\"").token("otherStuff")
        )

        let testString = "The \"quick \\\"brown\" fox jumps over the lazy dog"

        assertTokenListsEqual(tokenizer.tokenize(testString), reference: [token("otherStuff",chars:"The "), token("quote",chars:"\""), token("Char",chars:"quick \\\"brown"), token("quote",chars:"\""), token("otherStuff",chars:" fox jumps over the lazy dog")])
    }

    func testLoopingChar() {
        
        tokenizer.branch(
            OKStandard.whiteSpaces,
            LoopingCharacters(from: lowerCaseLetterString+upperCaseLetterString).token("word"),
            OKStandard.eot
        )
        
        let testString = "The quick brown fox jumps over the lazy dog"

        XCTAssert(tokenizer.tokenize(testString) == [token("word",chars:"The"), token("whitespace",chars:" "), token("word",chars:"quick"), token("whitespace",chars:" "), token("word",chars:"brown"), token("whitespace",chars:" "), token("word",chars:"fox"), token("whitespace",chars:" "), token("word",chars:"jumps"), token("whitespace",chars:" "), token("word",chars:"over"), token("whitespace",chars:" "), token("word",chars:"the"), token("whitespace",chars:" "), token("word",chars:"lazy"), token("whitespace",chars:" "), token("word",chars:"dog"), ])    }
}
