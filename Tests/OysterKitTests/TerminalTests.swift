//    Copyright (c) 2018, RED When Excited
//    All rights reserved.
//
//    Redistribution and use in source and binary forms, with or without
//    modification, are permitted provided that the following conditions are met:
//
//    * Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
//    * Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
//    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
//    FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//    SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import XCTest
import OysterKit


class TerminalTests: XCTestCase {

    func testStringTerminal() {
        let passSource = "Hello"
        let failSource = "Hullo"
        let helloToken = "Hello".parse(as: StringToken("hello"))
        
        if let tree = try? AbstractSyntaxTreeConstructor().build(passSource, using: Parser(grammar: [helloToken])){
            XCTAssertNotNil(tree.token)
            XCTAssertEqual(passSource, tree.matchedString )
        } else {
            XCTFail("Failed to create tree")
        }

        if (try? AbstractSyntaxTreeConstructor().build(failSource, using: Parser(grammar: [helloToken]))) != nil{
            XCTFail("Should have failed")
        }


        if (try? AbstractSyntaxTreeConstructor().build(failSource, using: Parser(grammar: [~"Hello"]))) != nil{
            XCTFail("Should have failed")
        }

    }
    
    func testRegularExpressionTerminal() {
        let passSource = "Hello"
        let failSource = "1.233"
        let helloRegex = try! NSRegularExpression(pattern: "[:alpha:]+", options: [])
        let helloToken = helloRegex.parse(as: StringToken("hello"))
        
        if let tree = try? AbstractSyntaxTreeConstructor().build(passSource, using: Parser(grammar: [helloToken])){
            XCTAssertNotNil(tree.token)
            XCTAssertEqual(passSource, tree.matchedString )
        } else {
            XCTFail("Failed to create tree")
        }
        
        if (try? AbstractSyntaxTreeConstructor().build(failSource, using: Parser(grammar: [helloToken]))) != nil{
            XCTFail("Should have failed")
        }
        
        
        if (try? AbstractSyntaxTreeConstructor().build(failSource, using: Parser(grammar: [~helloRegex]))) != nil{
            XCTFail("Should have failed")
        }
        
    }
    
    func testCharacterSetTerminal() {
        let passSource = "Hello"
        let failSource = "1.233"
        let letters = CharacterSet.letters
        let helloToken = letters.parse(as: StringToken("hello")).require(.oneOrMore)
        
        if let tree = try? AbstractSyntaxTreeConstructor().build(passSource, using: Parser(grammar: [helloToken])){
            XCTAssertNotNil(tree.token)
            XCTAssertEqual(passSource, tree.matchedString )
        } else {
            XCTFail("Failed to create tree")
        }
        
        if (try? AbstractSyntaxTreeConstructor().build(failSource, using: Parser(grammar: [helloToken]))) != nil{
            XCTFail("Should have failed")
        }
        
        
        if (try? AbstractSyntaxTreeConstructor().build(failSource, using: Parser(grammar: [~letters.require(.oneOrMore)]))) != nil{
            XCTFail("Should have failed")
        }
        
    }
    
    func testTerminalChoice() {
        let passSource = "Hello"
        let failSource = "Hullo"
        let choices = ["H","e","l", "o"].choice
        let choice = choices.parse(as:StringToken("hello")).require(.oneOrMore)
        
        if let tree = try? AbstractSyntaxTreeConstructor().build(passSource, using: Parser(grammar: [choice])){
            XCTAssertNotNil(tree.token)
            XCTAssertEqual(passSource, tree.matchedString )
        } else {
            XCTFail("Failed to create tree")
        }
        
        if (try? AbstractSyntaxTreeConstructor().build(failSource, using: Parser(grammar: [choice]))) != nil{
            XCTFail("Should have failed")
        }
        
        
        if (try? AbstractSyntaxTreeConstructor().build(failSource, using: Parser(grammar: [~choices.require(.oneOrMore)]))) != nil{
            XCTFail("Should have failed")
        }
        
    }
    
    func testTerminalSkip(){
        var rule = -"Hello"
        
        guard case .skipping = rule.behaviour.kind else {
            XCTFail("Generated rule was not a skip rule")
            return
        }
        
        rule = -"Hello".require(.zeroOrMore)
        
        guard rule.behaviour.cardinality.maximumMatches == nil && rule.behaviour.cardinality.minimumMatches == 0 else{
            XCTFail("Cardinality not passed on")
            return
        }
    }

}
