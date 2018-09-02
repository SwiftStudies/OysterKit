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

typealias TestIR = AbstractSyntaxTreeConstructor

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
    
    func testStringTokenExtension(){
        XCTAssertEqual("hello".rawValue, "hello".hash)
    }

    func testIntTokenExtension(){
        XCTAssertEqual(1.rawValue, 1)
    }
    
    func testOneFromCharacterSetToken(){
        let source = "Hello World"
        let rule = CharacterSet.letters.require(.one).parse(as: StringToken("letter"))
        let lexer = Lexer(source: source)
        let testIR = AbstractSyntaxTreeConstructor(with: source)
        
        do {
            try rule.match(with: lexer, for: testIR)
            let ast = try testIR.generate(HomogenousTree.self)
            XCTAssertEqual("H", ast.matchedString)
        } catch {
            XCTFail("Unexpected error from match")
        }
    }
    
    func testOneOrMoreFromCharacterSetToken(){
        let source = "Hello World"
        let rule = StringToken("letter").from(~CharacterSet.letters.require(.oneOrMore))
        let lexer = Lexer(source: source)
        let testIR = TestIR()
        
        do {
            try rule.match(with: lexer, for: testIR)
            let ast = try testIR.generate(HomogenousTree.self, source: source)
            XCTAssertEqual("Hello", ast.matchedString)
        } catch {
            XCTFail("Unexpected error from match")
        }
    }
    
    func testLazyConsumeCharacterSetToken(){
        let source = "Hello World"
        let rule : Rule = [-CharacterSet.letters].sequence.parse(as: StringToken("letter"))
        let lexer = Lexer(source: source)
        let testIR = TestIR()
        
        do {
            try rule.match(with: lexer, for: testIR)
            let ast = try testIR.generate(HomogenousTree.self, source: source)
            XCTAssertEqual("", ast.matchedString)
        } catch {
            XCTFail("Unexpected error from match")
        }
    }

    func testGreedilyConsumeCharacterSetToken(){
        let source = "Hello World"
        let rule : Rule = [-CharacterSet.letters.require(.oneOrMore)].sequence.parse(as: StringToken("letter"))
        let lexer = Lexer(source: source)
        let testIR = TestIR()
        
        lexer.mark()
        
        do {
            try rule.match(with: lexer, for: testIR)
            try " ".match(with: lexer, for: testIR)
            try rule.match(with: lexer, for: testIR)
            let ast = try testIR.generate(HomogenousTree.self, source: source)
            XCTAssertEqual("", ast.children.first?.matchedString ?? "error")
            XCTAssertEqual("", ast.children.last?.matchedString ?? "error")
            XCTAssertEqual("letter", "\(ast.children.first?.token ?? "error")")
            XCTAssertEqual("letter", "\(ast.children.last?.token ?? "error")")
            XCTAssertEqual(" World", ast.matchedString) //Not super intuitive but the sequence is scanning not skipping
        } catch {
            XCTFail("Unexpected error from match")
        }
    }
    
    func testGreedilyConsumeCharacterSetSkipStartAndEndToken(){
        let source = "Hello World"
        let rule : Rule = CharacterSet.letters.require(.oneOrMore).parse(as: "Anything").reference(.skipping)
        let lexer = Lexer(source: source)
        let testIR = TestIR()
        
        lexer.mark()
        
        do {
            try [rule, " ", rule].sequence.parse(as: StringToken("Greeting")).match(with: lexer, for: testIR)
            let ast = try testIR.generate(HomogenousTree.self, source: source)
            XCTAssertEqual(0, ast.children.count)
            XCTAssertEqual(" ", ast.matchedString)
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
    
    func testScannerRuleForRegularExpression(){
        let catRule = try! NSRegularExpression(pattern: "Cat", options: []).parse(as: StringToken("Cat"))
        
        XCTAssertEqual(catRule.description, "/Cat/►Cat")
        let commaRule = ","

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
        
        let felineRule = catRule.parse(as: StringToken("Feline"))
        
        XCTAssertEqual("\(felineRule)", "/Cat/►Feline")
        XCTAssertNotEqual(catRule.behaviour.token!.rawValue, felineRule.behaviour.token!.rawValue)
    }
    
    func testOptionalRepeatedNot(){
        let source = """
            //
            // Something
            //

            """
        let singleLineComment = [
            ~"//",
            (!CharacterSet.newlines).require(.zeroOrMore),
            ~CharacterSet.newlines
            ].sequence.parse(as:StringToken("singleLineComment"))
        
        let lexer = Lexer(source: source)
        let ir = AbstractSyntaxTreeConstructor(with: source)
        
        do {
            while !lexer.endOfInput {
                _ = try singleLineComment.match(with: lexer, for: ir)
            }
        } catch {
            XCTFail("Unexpected failure \(error)")
        }
    }
    
    
    func testKnownAnnotations(){
        let error = "Valid error"
        let rule = CharacterSet.letters.parse(as:StringToken("test")).require(.oneOrMore)
        let validError = rule.annotatedWith([
            RuleAnnotation.error : RuleAnnotationValue.string(error),
            RuleAnnotation.void  : RuleAnnotationValue.set,
            ])
        let invalidError = rule.annotatedWith([
            RuleAnnotation.error : RuleAnnotationValue.int(19),
            RuleAnnotation.void  : RuleAnnotationValue.bool(true)
            ])
        let invalidVoidWithInt = rule.annotatedWith([
            RuleAnnotation.void  : RuleAnnotationValue.int(10)
            ])
        let invalid3 = rule.annotatedWith([
            RuleAnnotation.void  : RuleAnnotationValue.string("true")
            ])
        let invalid4 = rule.annotatedWith([
            RuleAnnotation.transient  : RuleAnnotationValue.set
            ])
        let invalid5 = rule.annotatedWith([
            RuleAnnotation.transient  : RuleAnnotationValue.bool(true)
            ])
        let invalid6 = rule.annotatedWith([
            RuleAnnotation.transient  : RuleAnnotationValue.int(10)
            ])

        XCTAssertEqual(error,validError.error ?? "Nil")
        XCTAssertEqual("Unexpected annotation value: 19",invalidError.error ?? "Nil")
        XCTAssertTrue(validError.skipping)
        XCTAssertTrue(invalidError.skipping)
        XCTAssertFalse(invalidVoidWithInt.skipping)
        XCTAssertFalse(invalid3.skipping)
        XCTAssertFalse(invalid4.skipping)
        
        XCTAssertFalse(rule.scanning)
        XCTAssertTrue(invalid4.scanning)
        XCTAssertTrue(invalid5.scanning)
        XCTAssertFalse(invalid6.scanning)

    }
    
    func testHumanConsumableError(){
        let text = "Hello\nworld my friend"
        let range = text.range(of: "world")!
        let pointError = ProcessingError.parsing(message: "Expected to find World not world", range: range.lowerBound...range.upperBound, causes: [])
        
        XCTAssertEqual("Parsing Error: Expected to find World not world between 6 and 11", pointError.debugDescription)
    }
}
