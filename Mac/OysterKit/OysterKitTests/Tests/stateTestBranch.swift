//
//  stateTestBranch.swift
//  OysterKit Mac
//
//  Created by Nigel Hughes on 03/07/2014.
//  Copyright (c) 2014 RED When Excited Limited. All rights reserved.
//

import XCTest
import OysterKit

class stateTestBranch: XCTestCase {
    var tokenizer = OysterKit.Tokenizer()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        tokenizer = Tokenizer()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testBranch(){
        
        tokenizer.branch(
            char("x").branch(
                char("y").token("xy"),
                char("z").token("xz")
            ),
            OKStandard.eot
        )
                
        XCTAssert(tokenizer.tokenize("xyxz") == [token("xy"),token("xz")])
    }
    
    func testRepeatLoopEquivalence(){
        
        let seperator = Characters(from: ",").token("sep")
        
        let lettersWithLoop = LoopingCharacters(from:"abcdef").token("easy")
        let lettersWithRepeat = Repeat(state: Characters(from:"abcdef").token("ignore")).token("easy")
        
        let space = Characters(from: " ")
        let bracketedWithRepeat = Delimited(open: "(", close: ")", states: lettersWithRepeat).token("bracket")
        let bracketedWithLoop = Delimited(open: "(", close: ")", states: lettersWithLoop).token("bracket")
        
        tokenizer.branch([
            bracketedWithLoop,
            seperator,
            space
        ])
        
        var underTest = Tokenizer()
        underTest.branch([
            bracketedWithRepeat,
            seperator,
            space])

        let testString = "(a),(b) (c)(e),(abc),(def) (fed)(aef)"
        
        let testTokens = underTest.tokenize(testString)
        let referenceTokens = tokenizer.tokenize(testString)
        
        assertTokenListsEqual(testTokens, reference: referenceTokens)
    }
    
    func testNestedBranch(){
        tokenizer.branch(
            Branch(states: [
                char("x").branch(
                    char("y").token("xy"),
                    char("z").token("xz")
                )
                ])
        )
        
        XCTAssert(tokenizer.tokenize("xyxz") == [token("xy"),token("xz")])
    }
    
    func testXY(){
        tokenizer.sequence(char("x"),char("y").token("xy"))
        tokenizer.branch(OKStandard.eot)
        
        XCTAssert(tokenizer.tokenize("xy") == [token("xy")], "Chained results do not match")
    }
    
    
    func testSequence1(){
        let expectedResults = [token("done",chars:"xyz")]
        
        tokenizer.branch(
            sequence(char("x"),char("y"),char("z").token("done")),
            OKStandard.eot
        )
        
        XCTAssert(tokenizer.tokenize("xyz") == expectedResults)
    }
    
    func testSequence2(){
        let expectedResults = [token("done",chars:"xyz")]
        
        tokenizer.branch(
            char("x").sequence(char("y"),char("z").token("done")),
            OKStandard.eot
        )
        
        XCTAssert(tokenizer.tokenize("xyz") == expectedResults)
    }


}
