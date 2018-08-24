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
    
    func isSkipping(_ rule:BehaviouralRule)->Bool{
        if case .skipping = rule.behaviour.kind {
            return true
        }
        return false
    }

    func isScanning(_ rule:BehaviouralRule)->Bool{
        if case .scanning = rule.behaviour.kind {
            return true
        }
        return false
    }

    func testLookaheadOperator() {
        let hello = LabelledToken(withLabel: "hello")
        let singleCardinalityRule = "hello".parse(as: hello)
        let multipleCardinalityRule = "hello".parse(as: hello).require(.oneOrMore)
        
        let singleLookahead = >>singleCardinalityRule
        XCTAssertNil(singleLookahead.behaviour.token, "Lookahead should mean no token is created")
        XCTAssertEqual(singleLookahead.behaviour.lookahead, true)
        XCTAssertFalse(matchSucceeds(for: singleLookahead, with: "hullo"))
        do {
            let index = try applyMatch(for: singleLookahead, with: "hello")
            XCTAssertEqual(0, index, "Scanner should not be advanced")
        } catch {
            XCTFail("Match should succeed")
        }

        let multipleLookahead = >>multipleCardinalityRule
        XCTAssertNil(multipleLookahead.behaviour.token, "Lookahead should mean no token is created")
        XCTAssertEqual(multipleLookahead.behaviour.lookahead, true)
        XCTAssertEqual(multipleLookahead.behaviour.cardinality, .oneOrMore)
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
        let singleCardinalityRule = "hello".parse(as: hello)
        let multipleCardinalityRule = "hello".parse(as: hello).require(.oneOrMore)
        
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
        XCTAssertEqual(multipleNegated.behaviour.negate, true, "Rule correctly appears to be negated")
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
    
    func testSkipOperator(){
        let hello = LabelledToken(withLabel: "hello")
        let singleCardinalityRule = "hello".parse(as: hello)
        let multipleCardinalityRule = "hello".parse(as: hello).require(.oneOrMore)
        
        let single = -singleCardinalityRule
        XCTAssertNil(single.behaviour.token, "No token should be produced")
        XCTAssertTrue(matchSucceeds(for: single, with: "hello"))
        XCTAssertTrue(isSkipping(single))
        do {
            let index = try applyMatch(for: single, with: "hello")
            XCTAssertEqual(5, index, "Scanner should be advanced")
        } catch {
            XCTFail("Match should succeed \(error)")
        }
        
        let multiple = -multipleCardinalityRule
        XCTAssertNil(multiple.behaviour.token, "No token should be produced")
        XCTAssertTrue(matchSucceeds(for: multiple, with: "hello"))
        XCTAssertFalse(matchSucceeds(for: multiple, with: "hullo"))
        XCTAssertTrue(isSkipping(multiple))
        do {
            let index = try applyMatch(for: multiple, with: "hello")
            XCTAssertEqual(5, index, "Scanner should be advanced to the end")
        } catch {
            XCTFail("Match should succeed \(error)")
        }
    }
    
    func testScanOperator(){
        let hello = LabelledToken(withLabel: "hello")
        let singleCardinalityRule = "hello".parse(as: hello)
        let multipleCardinalityRule = "hello".parse(as: hello).require(.oneOrMore)

        let single = ~singleCardinalityRule
        XCTAssertNil(single.behaviour.token, "No token should be produced")
        XCTAssertTrue(matchSucceeds(for: single, with: "hello"))
        XCTAssertTrue(isScanning(single))

        do {
            let index = try applyMatch(for: single, with: "hello")
            XCTAssertEqual(5, index, "Scanner should be advanced")
        } catch {
            XCTFail("Match should succeed \(error)")
        }
        
        let multiple = ~multipleCardinalityRule
        XCTAssertNil(multiple.behaviour.token, "No token should be produced")
        XCTAssertTrue(matchSucceeds(for: multiple, with: "hello"))
        XCTAssertFalse(matchSucceeds(for: multiple, with: "hullo"))
        XCTAssertTrue(isScanning(multiple))
        do {
            let index = try applyMatch(for: multiple, with: "hello")
            XCTAssertEqual(5, index, "Scanner should be advanced to the end")
        } catch {
            XCTFail("Match should succeed \(error)")
        }
    }
    
    func testOneOf(){
        let hello = ["h","e","l","o"].choice.require(.oneOrMore)
        
        XCTAssertTrue(matchSucceeds(for: hello, with: "hello"))
        XCTAssertFalse(matchSucceeds(for: hello, with: "dello"))
    }
    
    func testSequence(){
        let hello = ["h","e","l".require(.oneOrMore),"o"].sequence
        
        XCTAssertTrue(matchSucceeds(for: hello, with: "hello"))
        XCTAssertFalse(matchSucceeds(for: hello, with: "hell0"))
    }
    
    
    func testFromOperator(){
        let hello = LabelledToken(withLabel: "hello")
        let greeting = LabelledToken(withLabel: "greeting")
        let singleCardinalityRule = "hello".parse(as: hello)
        let multipleCardinalityRule = "hello".parse(as: hello).require(.oneOrMore)

        let single = greeting.from(singleCardinalityRule)
        XCTAssertEqual("\(single.behaviour.token!)","\(greeting)")
        XCTAssertTrue(matchSucceeds(for: single, with: "hello"))
        do {
            let index = try applyMatch(for: single, with: "hello")
            XCTAssertEqual(5, index, "Scanner should be advanced")
        } catch {
            XCTFail("Match should succeed \(error)")
        }
        
        let multiple = greeting.from(multipleCardinalityRule)
        XCTAssertEqual("\(multiple.behaviour.token!)","\(greeting)")
        XCTAssertTrue(matchSucceeds(for: multiple, with: "hello"))
        XCTAssertFalse(matchSucceeds(for: multiple, with: "hullo"))
        do {
            let index = try applyMatch(for: multiple, with: "hellohello")
            XCTAssertEqual(10, index, "Scanner should be advanced to the end")
        } catch {
            XCTFail("Match should succeed \(error)")
        }
    }
    
    func testAnnotationOperator(){
        let hello = LabelledToken(withLabel: "hello")
        let single = "hello".parse(as: hello).annotatedWith([.custom(label: "test") : .string("set")])
        let multiple = "hello".parse(as: hello).require(.oneOrMore).annotatedWith([.custom(label: "test") : .string("set")])

        XCTAssertNotNil(single.annotations[.custom(label:"test")], "Annotation not set")
        XCTAssertNotNil(multiple.annotations[.custom(label:"test")], "Annotation not set")
    }
    
    func testCardinalityChanges(){
        
        XCTAssertEqual(Cardinality(1...1),  "hello".behaviour.cardinality)
        XCTAssertEqual(Cardinality(0...1),  "hello".require(.optionally).behaviour.cardinality)
        XCTAssertEqual(Cardinality(0...),   "hello".require(.noneOrMore).behaviour.cardinality)
        XCTAssertEqual(Cardinality(1...),   "hello".require(.oneOrMore).behaviour.cardinality)
        XCTAssertEqual(Cardinality(1...1),  "hello".require(.one).behaviour.cardinality)
    }
}
