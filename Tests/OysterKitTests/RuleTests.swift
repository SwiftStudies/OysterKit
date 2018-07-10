//    Copyright (c) 2014, RED When Excited
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
@testable import OysterKit

class TestIR : IntermediateRepresentation {
    
    var results = [MatchResult]()
    
    required init(){
        
    }
    func willEvaluate(rule: Rule, at position: String.UnicodeScalarView.Index) -> MatchResult? {
        return nil
    }
    func didEvaluate(rule: Rule, matchResult: MatchResult) {
        results.append(matchResult)
    }
    func willBuildFrom(source: String, with: Language) {
    }
    func didBuild() {
    }
    func resetState() {
    }
}

class RuleTests: XCTestCase {

    func makeLexicalContext(source:String, mark: String.UnicodeScalarView.Index, current: String.UnicodeScalarView.Index)->LexicalContext{
        return LexerContext(mark: Mark(uniPosition: mark), endLocation: current, source: source)
    }
    
    func makeMatchResults(source:String)->(success:MatchResult, consume:MatchResult, fail:MatchResult, ignoreFail:MatchResult){
        let context = LexerContext(mark: Mark(uniPosition: source.unicodeScalars.startIndex), endLocation: source.unicodeScalars.endIndex, source: source)
        let success = MatchResult.success(context: context)
        let consume = MatchResult.consume(context: context)
        let failure = MatchResult.failure(atIndex: source.unicodeScalars.startIndex)
        let ignorableFailure = MatchResult.ignoreFailure(atIndex: source.unicodeScalars.startIndex)

        return (success, consume, failure, ignorableFailure)
    }

    func testMatchResultDescriptions() {
        let helloWorld = "Hello World"
        let matchResults = makeMatchResults(source: helloWorld)
        
        XCTAssertEqual("Success (Hello World)", matchResults.success.description)
        XCTAssertEqual("Consumed (Hello World)", matchResults.consume.description)
        XCTAssertEqual("Failed at 0", matchResults.fail.description)
        XCTAssertEqual("Ignore Failure", matchResults.ignoreFail.description)
    }
    
    func testMatchResultRange() {
        let helloWorld = "Hello World"
        let matchResults = makeMatchResults(source: helloWorld)

        XCTAssertEqual(helloWorld.unicodeScalars.startIndex, matchResults.success.range)
        XCTAssertEqual(helloWorld.unicodeScalars.startIndex, matchResults.consume.range)
        XCTAssertEqual(helloWorld.unicodeScalars.startIndex, matchResults.fail.range)
        XCTAssertEqual(helloWorld.unicodeScalars.startIndex, matchResults.ignoreFail.range)
    }

    func testMatchResultString() {
        let helloWorld = "Hello World"
        let matchResults = makeMatchResults(source: helloWorld)
        
        XCTAssertNil(matchResults.consume.matchedString)
        XCTAssertNil(matchResults.fail.matchedString)
        XCTAssertNil(matchResults.ignoreFail.matchedString)
        XCTAssertEqual("Hello World", matchResults.success.matchedString)
    }
    
    func testTransientTokenValue(){
        XCTAssertEqual(-1, LabelledToken.transientToken.rawValue)
    }
    
    func testTransientTokenDescriptions(){
        let unlabelledTransientToken = TransientToken.anonymous
        let labelledTransientToken = TransientToken.labelled("label")
        
        XCTAssertEqual("transient", unlabelledTransientToken.description)
        XCTAssertEqual("label", labelledTransientToken.description)
    }
    
    func testStringTokenExtension(){
        XCTAssertEqual("hello".rawValue, "hello".hash)
    }

    func testIntTokenExtension(){
        XCTAssertEqual(1.rawValue, 1)
    }
    
    func testOneFromCharacterSetToken(){
        let source = "Hello World"
        let rule = LabelledToken(withLabel: "letter").from(oneOf: CharacterSet.letters)
        let lexer = Lexer(source: source)
        let testIR = TestIR()
        
        do {
            switch try rule.match(with: lexer, for: testIR){
            case .success(let context):
                //Test stuff
                XCTAssertEqual("H", context.matchedString)
            default:
                XCTFail("Should have succeeded")
            }
        } catch {
            XCTFail("Unexpected error from match")
        }
    }
    
    func testOneOrMoreFromCharacterSetToken(){
        let source = "Hello World"
        let rule = LabelledToken(withLabel: "letter").oneOrMore(of: CharacterSet.letters)
        let lexer = Lexer(source: source)
        let testIR = TestIR()
        
        do {
            switch try rule.match(with: lexer, for: testIR){
            case .success(let context):
                //Test stuff
                XCTAssertEqual("Hello", context.matchedString)
            default:
                XCTFail("Should have succeeded")
            }
        } catch {
            XCTFail("Unexpected error from match")
        }
    }
    
    func testLazyConsumeCharacterSetToken(){
        let source = "Hello World"
        let rule = LabelledToken(withLabel: "letter").consume(CharacterSet.letters)
        let lexer = Lexer(source: source)
        let testIR = TestIR()
        
        do {
            switch try rule.match(with: lexer, for: testIR){
            case .consume(let context):
                //Test stuff
                XCTAssertEqual("H", context.matchedString)
            default:
                XCTFail("Should have succeeded")
            }
        } catch {
            XCTFail("Unexpected error from match")
        }
    }

    func testGreedilyConsumeCharacterSetToken(){
        let source = "Hello World"
        let rule = LabelledToken(withLabel: "letter").consumeGreedily(CharacterSet.letters)
        let lexer = Lexer(source: source)
        let testIR = TestIR()
        
        do {
            switch try rule.match(with: lexer, for: testIR){
            case .consume(let context):
                //Test stuff
                XCTAssertEqual("Hello", context.matchedString)
            default:
                XCTFail("Should have succeeded")
            }
        } catch {
            XCTFail("Unexpected error from match")
        }
    }
    
    func testAnnotationComparison(){
        let baseAnnotations = [
            RuleAnnotation.error : RuleAnnotationValue.string("Result"),
            RuleAnnotation.pinned : RuleAnnotationValue.set,
            RuleAnnotation.token : RuleAnnotationValue.int(10)
        ]
        let shorter = [
            RuleAnnotation.error : RuleAnnotationValue.string("Result"),
            RuleAnnotation.token : RuleAnnotationValue.int(10)
        ]

        let longer = [
            RuleAnnotation.pinned : RuleAnnotationValue.set,
            RuleAnnotation.error : RuleAnnotationValue.string("Result"),
            RuleAnnotation.token : RuleAnnotationValue.int(10),
            RuleAnnotation.transient : RuleAnnotationValue.set,
        ]
        
        let outOfOrder = [
            RuleAnnotation.pinned : RuleAnnotationValue.set,
            RuleAnnotation.error : RuleAnnotationValue.string("Result"),
            RuleAnnotation.token : RuleAnnotationValue.int(10)
            ]

        let differentValue = [
            RuleAnnotation.error : RuleAnnotationValue.string("Nothing"),
            RuleAnnotation.pinned : RuleAnnotationValue.set,
            RuleAnnotation.token : RuleAnnotationValue.int(10)
        ]

        
        XCTAssertTrue(areEqual(lhs: baseAnnotations, rhs: baseAnnotations))
        XCTAssertTrue(areEqual(lhs: baseAnnotations, rhs: outOfOrder))
        XCTAssertFalse(areEqual(lhs: baseAnnotations, rhs: shorter))
        XCTAssertFalse(areEqual(lhs: baseAnnotations, rhs: longer))
        XCTAssertFalse(areEqual(lhs: baseAnnotations, rhs: differentValue))

        // Test that it works in both direcitons
        XCTAssertTrue(areEqual(lhs: baseAnnotations, rhs: baseAnnotations))
        XCTAssertTrue(areEqual(lhs: outOfOrder, rhs: baseAnnotations))
        XCTAssertFalse(areEqual(lhs: shorter, rhs: baseAnnotations))
        XCTAssertFalse(areEqual(lhs: longer, rhs: baseAnnotations))
        XCTAssertFalse(areEqual(lhs: differentValue, rhs: baseAnnotations))

    }
    
    func testInstanceTokenModification(){
        let rule = LabelledToken(withLabel: "letter").oneOrMore(of: CharacterSet.letters)
        let newRule = rule.instance(with: transientTokenValue.token)
        
        XCTAssertEqual(newRule.produces.rawValue, transientTokenValue)
    }
    
    func testScannerRuleForRegularExpression(){
        let catRegex = try! NSRegularExpression(pattern: "Cat", options: [])
        
        let catRule = ScannerRule.regularExpression(token: LabelledToken(withLabel: "Cat"), pattern: catRegex, [:])
        XCTAssertEqual(catRule.description, "Cat = /Cat/")
        let commaRule = ScannerRule.oneOf(token: transientTokenValue.token, [","], [:])
        
        let source = "Cat,Dog"
        
        let lexer = Lexer(source: source)
        let ir = TokenStreamIterator(with: lexer, and: [catRule, commaRule].language)
        
        do {
            _ = try catRule.match(with: lexer, for: ir)
            _ = try commaRule.match(with: lexer, for: ir)
        } catch {
            XCTAssert(false, "Failed to match rules")
            return
        }
        
        do {
            _ = try catRule.match(with: lexer, for: ir)
            XCTAssert(false, "Should not have matched")
            return
        } catch {
            
        }
        
        let felineRule = catRule.instance(with: LabelledToken(withLabel: "Feline"), andAnnotations: [RuleAnnotation.pinned : RuleAnnotationValue.set])
        
        XCTAssertEqual("\(felineRule)", "Feline = @pin /Cat/")
        XCTAssertNotEqual(catRule.produces.rawValue, felineRule.produces.rawValue)
    }
    
    
    func testKnownAnnotations(){
        let error = "Valid error"
        let rule = LabelledToken(withLabel: "test").oneOrMore(of: CharacterSet.letters)
        let validError = rule.instance(with: [
            RuleAnnotation.error : RuleAnnotationValue.string(error),
            RuleAnnotation.void  : RuleAnnotationValue.set,
            ])
        let invalidError = rule.instance(with: [
            RuleAnnotation.error : RuleAnnotationValue.int(19),
            RuleAnnotation.void  : RuleAnnotationValue.bool(true)
            ])
        let invalidVoidWithInt = rule.instance(with: [
            RuleAnnotation.void  : RuleAnnotationValue.int(10)
            ])
        let invalid3 = rule.instance(with: [
            RuleAnnotation.void  : RuleAnnotationValue.string("true")
            ])
        let invalid4 = rule.instance(with: [
            RuleAnnotation.transient  : RuleAnnotationValue.set
            ])
        let invalid5 = rule.instance(with: [
            RuleAnnotation.transient  : RuleAnnotationValue.bool(true)
            ])
        let invalid6 = rule.instance(with: [
            RuleAnnotation.transient  : RuleAnnotationValue.int(10)
            ])

        XCTAssertEqual(error,validError.error ?? "Nil")
        XCTAssertEqual("Unexpected annotation value: 19",invalidError.error ?? "Nil")
        XCTAssertTrue(validError.void)
        XCTAssertTrue(invalidError.void)
        XCTAssertFalse(invalidVoidWithInt.void)
        XCTAssertFalse(invalid3.void)
        XCTAssertFalse(invalid4.void)
        
        let transientRule = LabelledToken.transientToken
        XCTAssertTrue(transientRule.transient)
        XCTAssertFalse(rule.transient)
        XCTAssertTrue(invalid4.transient)
        XCTAssertTrue(invalid5.transient)
        XCTAssertFalse(invalid6.transient)

    }
    
    func testHumanConsumableError(){
        let text = "Hello\nworld my friend"
        
        let pointError = LanguageError.parsingError(at: text.range(of: "world")!, message: "Expected to find World not world")
        
        XCTAssertEqual("Expected to find World not world at line 1, column 1: \nworld my friend\n                                                       ^", pointError.formattedErrorMessage(in: text))
    }
}
