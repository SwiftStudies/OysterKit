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

class RuleOperatorTests: XCTestCase {

    func applyMatch(for rule:BehaviouralRule, with source:String) throws -> Int {
        let lexer = Lexer(source: source)
        let ir = AbstractSyntaxTreeConstructor(with: source)
        
        try _ = rule.match(with: lexer, for: ir)
        
        return lexer.position
    }
    
    func matchSucceeds(for rule:BehaviouralRule, with source:String) -> Bool {
        do {
            _ = try applyMatch(for: rule, with: source)
            return true
        } catch {
            return false
        }
    }
    
    func testLookaheadOperator() {
        let hello = LabelledToken(withLabel: "hello")
        let singleCardinalityRule = "hello".token(hello, from: .one)
        let multipleCardinalityRule = "hello".token(hello, from: .oneOrMore)
        
        let singleLookahead = >>singleCardinalityRule
        XCTAssertNotNil(singleLookahead.behaviour.token, "Single cardinality should mean the rule is not wrapped")
        XCTAssertEqual(singleLookahead.behaviour.lookahead, true)
        XCTAssertFalse(matchSucceeds(for: singleLookahead, with: "hullo"))
        do {
            let index = try applyMatch(for: singleLookahead, with: "hello")
            XCTAssertEqual(0, index, "Scanner should not be advanced")
        } catch {
            XCTFail("Match should succeed")
        }

        let multipleLookahead = >>multipleCardinalityRule
        XCTAssertNil(multipleLookahead.behaviour.token, "Multiple cardinality should mean the rule is wrapped")
        XCTAssertEqual(multipleLookahead.behaviour.lookahead, true)
        XCTAssertEqual(multipleLookahead.behaviour.cardinality, .one)
        XCTAssertTrue(matchSucceeds(for: multipleLookahead, with: "hello"))
        XCTAssertFalse(matchSucceeds(for: multipleLookahead, with: "hullo"))
        do {
            let index = try applyMatch(for: multipleLookahead, with: "hello")
            XCTAssertEqual(0, index, "Scanner should not be advanced")
        } catch {
            XCTFail("Match should succeed")
        }
    }
    
    func testNotOperator(){
        let hello = LabelledToken(withLabel: "hello")
        let singleCardinalityRule = "hello".token(hello, from: .one)
        let multipleCardinalityRule = "hello".token(hello, from: .oneOrMore)
        
        let singleNegated = !singleCardinalityRule
        XCTAssertNotNil(singleNegated.behaviour.token, "Single cardinality should mean the rule is not wrapped")
        XCTAssertEqual(singleNegated.behaviour.negate, true)
        XCTAssertTrue(matchSucceeds(for: singleNegated, with: "hullo"))
        do {
            let index = try applyMatch(for: singleNegated, with: "hullo")
            XCTAssertEqual(1, index, "Scanner should not be advanced")
        } catch {
            XCTFail("Match should succeed")
        }
        
        let multipleNegated = !multipleCardinalityRule
        XCTAssertNotNil(multipleNegated.behaviour.token, "Token should be created by wrapping rule")
        XCTAssertEqual(multipleNegated.behaviour.negate, false, "Negation should occur inside the wrapping rule")
        XCTAssertEqual(multipleNegated.behaviour.cardinality, .oneOrMore, "Cardinality should be preserved on the outer rule")
        XCTAssertFalse(matchSucceeds(for: multipleNegated, with: "hello"))
        XCTAssertTrue(matchSucceeds(for: multipleNegated, with: "hullo"))
        do {
            let index = try applyMatch(for: multipleNegated, with: "hullo")
            XCTAssertEqual(5, index, "Scanner should be advanced to the end")
        } catch {
            XCTFail("Match should succeed")
        }

    }
}
