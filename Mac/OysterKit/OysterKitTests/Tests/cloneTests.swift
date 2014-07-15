//
//  cloneTests.swift
//  OysterKit Mac
//
//  Created by Nigel Hughes on 14/07/2014.
//  Copyright (c) 2014 RED When Excited Limited. All rights reserved.
//

import OysterKit
import XCTest

class cloneTests: XCTestCase {
    var ot = Tokenizer()
    var ct = Tokenizer()
    
    let aToken = Char(from: "A").token("A")
    let bToken = Char(from: "B").token("B")

    let testABString = "AABBBAABA"
    
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.

        ot = Tokenizer()
        ct = Tokenizer()
    }
    
    func tokenizersProduceSameOutput(startState:TokenizationState, testString:String = "AABBBAABA"){
        ot.branch(startState)
        ct.branch(startState.clone())
        
        let originalTokens = ot.tokenize(testString)
        let clonedTokens = ct.tokenize(testString)
        
        XCTAssert(originalTokens.count > 0, "Original tokens array is empty, bad test: \(startState)")
        XCTAssert(originalTokens == clonedTokens, "Token arrays don't match \(originalTokens) vs. cloned \(clonedTokens)")
    }
    
    func testCloneChar(){
        tokenizersProduceSameOutput(aToken)
    }

    func testCloneBranchAndChar() {
        tokenizersProduceSameOutput(
            Branch(states: [aToken.clone(), bToken.clone()] )
        )
    }
    
    func testCloneRepeatAndChar() {
        tokenizersProduceSameOutput(
            Repeat(state:aToken.clone()).token("A's")
        )
    }

    
    func testCloneRepeatBranchWithChar() {
        tokenizersProduceSameOutput(
            Repeat(state:Branch().branch(aToken.clone(),bToken.clone())).token("A's and B's")
        )
    }

    func testChainedClone() {
        tokenizersProduceSameOutput(Branch().branch(
            aToken.clone().sequence(aToken.clone(),bToken.clone(),bToken.clone(),bToken.clone(),aToken.clone())
            )
        )
    }
    
    func testChainedRepeatClone() {
        let repeatB = Repeat(state: bToken.clone())
        let repeatAB = Repeat(state: aToken.clone()).branch(repeatB).token("AB")

        __debugScanning = true
        tokenizersProduceSameOutput(Repeat(state:repeatAB).token("AB's"))
        __debugScanning = false
    }
    
    func testDelimitedClone() {
        let sentance = Branch().branch(
            OysterKit.blanks,
            OysterKit.word,
            OysterKit.Code.quotedCharacterIncludingQuotes,
            OysterKit.eot
        )
        
        tokenizersProduceSameOutput(sentance, testString: "The 'quick' brown fox jumped over the 'lazy' dog")
    }
}
