//
//  DynamicGeneratorTest.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import XCTest
@testable import OysterKit
import STLR

private enum Tokens : Int, Token {
    case tokenA = 1
}

private enum TestError : Error {
    case expected(String)
}

class DynamicGeneratorTest: XCTestCase {

    private enum TT : Int, Token {
        case character = 1
        case xyz
        case whitespace
        case newline
        case whitespaceOrNewline
        case decimalDigits
        case letters
        case alphaNumeric
        case quote
        case comment
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        STLRIntermediateRepresentation.removeAllOptimizations()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        STLRIntermediateRepresentation.removeAllOptimizations()
    }

    func testSimpleChoice(){
        guard let rule = "\"x\" | \"y\" | \"z\"".dynamicRule(token: TT.xyz) else {
            XCTFail("Could not compile")
            return
        }
        
        let stream = TestableStream<HomogenousNode>(source: "xyz", [rule])
        let iterator = stream.makeIterator()
        
        var count = 0
        while let token = iterator.next() {
            XCTAssert(token.token == TT.xyz, "Unexpected token \(token)")
            count += 1
        }
        
        XCTAssert(count == 3, "Incorrect number of tokens \(count)")
        
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors)")
    }
    
    
    func testSimpleSequence(){
        guard let rule = "\"x\" \"y\" \"z\"".dynamicRule(token: TT.xyz) else {
            XCTFail("Could not compile")
            return
        }
        
        let stream  = TestableStream<HomogenousNode>(source: "xyz", [rule])
        
        let iterator = stream.makeIterator()
        
        while let token = iterator.next() {
            XCTAssert(token.token == TT.xyz, "Unexpected token \(token)")
        }
        
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors)")
        
    }
    
    func testGroupAtRootOfExpression(){
        guard let rule = "(\"x\" \"y\" \"z\")".dynamicRule(token: TT.xyz) else {
            XCTFail("Could not compile")
            return
        }
        
        let stream  = TestableStream<HomogenousNode>(source: "xyzxyz", [rule])
        
        let iterator = stream.makeIterator()
        
        var count = 0
        while let token = iterator.next() {
            XCTAssert(token.token == TT.xyz, "Unexpected token \(token)")
            count += 1
        }
        
        XCTAssert(count == 2, "Incorrect tokens count \(count)")
        
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors)")
    }
    
    func testNestedGroups(){
        guard let rule = "(\"x\" (\"y\") \"z\")".dynamicRule(token: TT.xyz) else {
            XCTFail("Could not compile")
            return
        }
        
        let stream = TestableStream<HomogenousNode>(source: "xyzxyz", [rule])
        
        let iterator = stream.makeIterator()
        
        var count = 0
        while let token = iterator.next() {
            XCTAssert(token.token == TT.xyz, "Unexpected token \(token)")
            count += 1
        }
        
        XCTAssert(count == 2, "Incorrect tokens count \(count)")
        
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors)")
    }
    
    func testZeroOrOne() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        guard let rule = "(\"x\"? (\"y\")? \"z\")".dynamicRule(token: TT.xyz) else {
            XCTFail("Could not compile")
            return
        }
        
        let stream = TestableStream<HomogenousNode>(source: "xyzxzyz", [rule])
        
        let iterator = stream.makeIterator()
        
        var count = 0
        while let token = iterator.next() {
            XCTAssert(token.token == TT.xyz, "Unexpected token \(token)")
            count += 1
        }
        
        XCTAssert(count == 3, "Incorrect tokens count \(count)")
        
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors)")
    }

    func testOneOrMore() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        guard let rule = "\"xy\" \"z\"+".dynamicRule(token: TT.xyz) else {
            XCTFail("Could not compile")
            return
        }
        
        let stream = TestableStream<HomogenousNode>(source: "xyzzzzzzzzzxyzxy", [rule])
        
        let iterator = stream.makeIterator()
        
        var count = 0
        while let token = iterator.next() {
            XCTAssert(token.token == TT.xyz, "Unexpected token \(token)")
            count += 1
        }
        
        XCTAssert(count == 2, "Incorrect tokens count \(count)")
        
        XCTAssert(iterator.parsingErrors.count == 1, "\(iterator.parsingErrors)")
    }

    func testEscapedQuotedString() {
        // "\"" ("\""!)+ "\""
        guard let rule = "\"\\\"\" (!\"\\\"\")+ \"\\\"\"".dynamicRule(token: TT.quote) else {
            XCTFail("Could not compile")
            return
        }
        
        let stream = TestableStream<HomogenousNode>(source: "\"hello\"", [rule])
        
        let iterator = stream.makeIterator()
        
        var count = 0
        while let token = iterator.next() {
            XCTAssert(token.token == TT.quote, "Unexpected token \(token)")
            
            count += 1
        }
        
        XCTAssert(count == 1, "Incorrect tokens count \(count)")
        
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors)")
    }
    
    func testNotEscapedQuote() {
        // "\""!
        guard let rule = "!\"\\\"\"".dynamicRule(token: TT.letters) else {
            XCTFail("Could not compile")
            return
        }
        
        let stream = TestableStream<HomogenousNode>(source: "ab\"c", [rule])
        
        let iterator = stream.makeIterator()
        
        var count = 0
        while let _ = iterator.next() {
            count += 1
        }
        
        XCTAssert(count == 2, "Incorrect tokens count \(count)")
        
        XCTAssert(iterator.parsingErrors.count == 1, "\(iterator.parsingErrors)")
    }
    
    func testEscapedQuote() {
        // "\""
        guard let rule = "\"\\\"\"".dynamicRule(token: TT.quote) else {
            XCTFail("Could not compile")
            return
        }
        
        // \"
        let stream = TestableStream<HomogenousNode>(source: "\"", [rule])
        
        let iterator = stream.makeIterator()
        
        var count = 0
        while let token = iterator.next() {
            XCTAssert(token.token == TT.quote, "Unexpected token \(token)")
            count += 1
        }
        
        XCTAssert(count == 1, "Incorrect tokens count \(count)")
        
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors)")
    }
    
    func testComment(){
        let stlrSource = "\"\\\\\\\\\" (!.newlines)* .newlines"
        
        guard let rule = stlrSource.dynamicRule(token: TT.comment) else {
            XCTFail("Could not compile")
            return
        }
        
        let source = "\\\\ Wibble\n"
        
        var count = 0
        
        for node in TestableStream<HomogenousNode>(source: source,[rule]){
            count += 1
            XCTAssert(node.token == TT.comment, "Got unexpected token \(node.token)")
        }
        
        XCTAssert(count == 1, "Incorrect tokens count \(count)")
    }
    
    func testZeroOrMore() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        guard let rule = "\"xy\" \"z\"*".dynamicRule(token: TT.xyz) else {
            XCTFail("Could not compile")
            return
        }
        
        let stream = TestableStream<HomogenousNode>(source: "xyzzzzzzzzzxyzxy", [rule])
        
        let iterator = stream.makeIterator()
        
        var count = 0
        while let token = iterator.next() {
            XCTAssert(token.token == TT.xyz, "Unexpected token \(token)")
            count += 1
        }
        
        XCTAssert(count == 3, "Incorrect tokens count \(count)")
        
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors)")
    }
    
    
    func testSimpleGroup() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        guard let rule = "( \"x\" \"y\" ) (\"z\" | \"Z\")".dynamicRule(token: TT.xyz) else {
            XCTFail("Could not compile")
            return
        }
        
        let stream = TestableStream<HomogenousNode>(source: "xyzxyZ", [rule])
        
        let iterator = stream.makeIterator()
        
        var count = 0
        while let token = iterator.next() {
            XCTAssert(token.token == TT.xyz, "Unexpected token \(token)")
            count += 1
        }
        
        XCTAssert(count == 2, "Incorrect tokens count \(count)")
        
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors)")
    }
    
    func testNot() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        guard let rule = "!\"x\"".dynamicRule(token: TT.character) else {
            XCTFail("Could not compile")
            return
        }
        
        let testSource = "ykfxd"
        
        let stream = TestableStream<HomogenousNode>(source: testSource, [rule])
        
        let iterator = stream.makeIterator()
        var count = 0
        while let node = iterator.next() {
            let captured = "\(testSource.unicodeScalars[node.range])"
            XCTAssert(node.token == TT.character, "Unexpected token \(node) \(captured)")
            XCTAssert(captured != "x", "Unexpected capture \(captured)")
            if node.token == TT.character {
                count+=1
            }
        }

        XCTAssert(count == 3, "Expected 3 tokens but got \(count)")
        XCTAssert(iterator.parsingErrors.count == 1, "\(iterator.parsingErrors)")
    }

    func testCheckDirectLeftHandRecursion(){
        let source = "rhs =  rhs \"|\" rhs ; "
        let stlr = STLRParser(source: source)
        
        for rule in stlr.ast.rules {
            XCTAssert(rule.directLeftHandRecursive)
        }
    }
    
    
    func testCheckLeftHandRecursion(){
        // rhs = "|" expr \n expr = ">" rhs
        let source = "rhs = \"|\" expr \nexpr= \">\" rhs "
        let stlr = STLRParser(source: source)
        
        for rule in stlr.ast.rules {
            XCTAssert(rule.leftHandRecursive)
            XCTAssert(!rule.directLeftHandRecursive)
        }
    }
    
    func testIllegalLeftHandRecursionDetection(){
        let source = "rhs = rhs; expr = lhs; lhs = (expr \" \");"
        let stlr = STLRParser(source: source)
        
        for _ in stlr.ast.rules {
            for rule in stlr.ast.rules {
                do {
                    try rule.validate()
                    XCTFail("Validation should have failed")
                } catch {
                    
                }
            }
        }
    }
    
    func testDirectLeftHandRecursion(){
        let source = "rhs = (\">\" rhs) | (\"<\" rhs) ;"
        let stlr = STLRParser(source: source)
        
        //To stop the stack overflow for now, but it's the right line
        XCTAssert(stlr.ast.runtimeLanguage != nil)
        var rules = [Rule]()
        for rule in stlr.ast.rules {
            if let identifier = rule.identifier, let parserRule = rule.rule(from:stlr.ast, creating: identifier.token) {
                rules.append(parserRule)
                print("\(parserRule)")
            } else {
                XCTFail("Rule has missing identifier or rule")
            }
            
            do {
                try rule.validate()
            } catch {
                XCTFail("Rule should failed to validate")
            }
        }
        
        XCTAssert(rules.count == 1, "Got \(rules.count) rules")
    }
    
    func testConsume() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        guard let rule = "(\" \"*)- \"x\"".dynamicRule(token: TT.character) else {
            XCTFail("Could not compile")
            return
        }
        
        let testSource = "    x"
        
        let stream = TestableStream<HomogenousNode>(source: testSource, [rule])
        
        let iterator = stream.makeIterator()
        var count = 0
        while let node = iterator.next() {
            let captured = "\(testSource.unicodeScalars[node.range])"
            XCTAssert(node.token == TT.character, "Unexpected token \(node) \(captured)")
            XCTAssert(captured != "x", "Unexpected capture \(captured)")
            if node.token == TT.character {
                count+=1
            }
        }
        
        XCTAssert(count == 1, "Expected 1 tokens but got \(count)")
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors)")
    }
    
    
    func testEscapedTerminal() {
        guard let rule = "\"\\\"\"".dynamicRule(token: TT.character) else {
            XCTFail("Could not compile")
            return
        }
        
        let stream = TestableStream<HomogenousNode>(source: "\"", [rule])
        
        let iterator = stream.makeIterator()
        
        while let token = iterator.next() {
            XCTAssert(token.token == TT.character, "Unexpected token \(token)")
        }
        
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors)")
    }
    
    func testSimpleLookahead() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        guard let rule = "\"x\"".dynamicRule(token: TT.character) else {
            XCTFail("Could not compile")
            return
        }
        let stream = TestableStream<HomogenousNode>(source: "x", [rule])
        
        let iterator = stream.makeIterator()
        
        while let token = iterator.next() {
            XCTAssert(token.token == TT.character, "Unexpected token \(token)")
        }
        
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors)")
    }
    
    func testSimpleTerminal() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        guard let rule = "\"x\"".dynamicRule(token: TT.character) else {
            XCTFail("Could not compile")
            return
        }
        let stream = TestableStream<HomogenousNode>(source: "x", [rule])

        let iterator = stream.makeIterator()
        
        while let token = iterator.next() {
            XCTAssert(token.token == TT.character, "Unexpected token \(token)")
        }
        
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors)")
    }
    
    func testCharacterSets() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        guard let rule = ".whitespaces+".dynamicRule(token: TT.whitespace) else {
            XCTFail("Could not compile")
            return
        }
        
        let stream = TestableStream<HomogenousNode>(source: "    \t    ", [rule])
        
        let iterator = stream.makeIterator()
        
        var count = 0
        while let node = iterator.next() {
            XCTAssert(node.token == TT.whitespace, "Unexpected token \(node.token)[\(node.token.rawValue)]")
            count += 1
        }
        
        XCTAssert(count == 1)
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors)")
    }
    
    func testCharacterRange() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        guard let rule = "\"0\"...\"9\"".dynamicRule(token: TT.decimalDigits) else {
            XCTFail("Could not compile")
            return
        }
        
        let stream = TestableStream<HomogenousNode>(source: "0123456789x", [rule])
        
        let iterator = stream.makeIterator()
        
        var count = 0
        while let token = iterator.next() {
            XCTAssert(token.token == TT.decimalDigits, "Unexpected token \(token)")
            count += 1
        }
        
        XCTAssert(count == 10)
        XCTAssert(iterator.parsingErrors.count == 1, "\(iterator.parsingErrors)")
    }

    func generatedStringSerialization(for source:String, desiredIdentifier identifierName:String)throws ->String {
        let ast = STLRParser(source: source).ast
        
        guard let identifier = ast.identifiers[identifierName] else {
            throw TestError.expected("Missing identifier \(identifierName)")
        }
        
        guard let rule = identifier.rule(from: ast, creating: Tokens.tokenA) else {
            return "Could not create rule"
        }
        
        let swift = "\(rule)".trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")
        
        return swift
    }
    
    func generatedStringSerialization(for source:String, desiredRule rule: Int = 0)throws ->String {
        let ast = STLRParser(source: source).ast
        
        if ast.rules.count <= rule {
            throw TestError.expected("at least \(rule + 1) rule, but got \(ast.rules.count)")
        }
        
        guard let rule = ast.rules[rule].rule(from: ast, creating: Tokens.tokenA) else {
            return "Could not create rule"
        }
        
        let swift = "\(rule)".trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")
        
        return swift
    }
    
    func testPredefinedCharacterSet() {
        do {
            let result = try generatedStringSerialization(for: "letter = @error(\"error\").whitespaces")
            
            XCTAssert(result == "tokenA = @error(\"error\") .characterSet", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testCustomCharacterSet() {
        do {
            let result = try generatedStringSerialization(for: "letter = @error(\"error\") \"a\"...\"z\"")
            
            XCTAssert(result == "tokenA = @error(\"error\") .characterSet", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testSimplestPossibleGrammar(){
        do {
            let result = try generatedStringSerialization(for: "a=\"a\"")
            
            XCTAssert(result == "tokenA =  \"a\"", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testTerminal(){
        do {
            let result = try generatedStringSerialization(for: "letter = @error(\"error\") \"hello\"")
            
            XCTAssert(result == "tokenA = @error(\"error\") \"hello\"", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testSingleCharacterTerminal(){
        do {
            let result = try generatedStringSerialization(for: "letter = @error(\"error\") \"h\"")
            
            XCTAssert(result == "tokenA = @error(\"error\") \"h\"", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testTerminalChoiceWithIndividualAnnotations(){
        do {
            let reference = "tokenA =  (@error(\"error a\") \"a\"|@error(\"error b\") \"b\"|@error(\"error c\") \"c\")"
            let result = try generatedStringSerialization(for: "letter = @error(\"error a\") \"a\"| @error(\"error b\")\"b\"| @error(\"error c\") \"c\"").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")
            
            XCTAssertEqual(reference, result)
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testTerminalChoiceWithIndividualAnnotationsOptimized(){
        STLRIntermediateRepresentation.register(optimizer: InlineIdentifierOptimization())
        STLRIntermediateRepresentation.register(optimizer: CharacterSetOnlyChoiceOptimizer())
        do {
            let reference = "tokenA =  (@error(\"error a\") \"a\"|@error(\"error b\") \"b\"|@error(\"error c\") \"c\")"
            let result = try generatedStringSerialization(for: "letter = @error(\"error a\") \"a\"| @error(\"error b\")\"b\"| @error(\"error c\") \"c\"").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")
            
            
            XCTAssertEqual(reference, result)
            
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testTerminalChoice(){
        do {
            let result = try generatedStringSerialization(for: "letter = @error(\"error\") (\"a\"|\"b\"|\"c\")")
            
            XCTAssertEqual("@error(\"error\")(\"a\" | \"b\" | \"c\")", result)
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testTerminalSequence(){
        do {
            let result = try generatedStringSerialization(for: "letter = @error(\"error\") (\"a\" \"b\" \"c\")")
            let reference = "tokenA = @error(\"error\") ( \"a\"  \"b\"  \"c\")"
            XCTAssertEqual(result, reference)
            
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testTerminalSequenceWithIndividualAnnotations(){
        do {
            let result = try generatedStringSerialization(for: "letter = @error(\"error a\") \"a\"  @error(\"error b\")\"b\"  @error(\"error c\") \"c\"").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")
            
            XCTAssert(result == "tokenA =  (@error(\"error a\") \"a\" @error(\"error b\") \"b\" @error(\"error c\") \"c\")", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testAnnotatedNestedIdentifiers(){
        do {
            let aRule = try generatedStringSerialization(for: "a = @error(\"a internal\")\"a\"\naa = @error(\"error a1\") a @error(\"error a2\") a", desiredRule: 0)
            let result = try generatedStringSerialization(for: "a = @error(\"a internal\")\"a\"\naa = @error(\"error a1\") a @error(\"error a2\") a", desiredRule: 1)
            
            XCTAssert(aRule == "tokenA = @error(\"a internal\") \"a\"", "Bad generated output '\(aRule)'")
            XCTAssert(result == "tokenA =  (a = @error(\"error a1\") \"a\" a = @error(\"error a2\") \"a\")", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testMergedAnnotationOnIdentifierReference(){
        do {
            let result = try generatedStringSerialization(for: "@error(\"expected a\")a = @error(\"inner a\") \"a\"\naa = a @error(\"error a2\") a", desiredRule: 1)
            
            XCTAssert(result == "tokenA =  (a = @error(\"expected a\") \"a\" a = @error(\"error a2\") \"a\")", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testAnnotationOnQuantifier(){
        do {
            let result = try generatedStringSerialization(for: "word = @error(\"Expected a letter\") .letters+", desiredRule: 0)
            
            XCTAssert(result == "tokenA = @error(\"Expected a letter\")  .characterSet+", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testMergedAnnotationOnIdentifierReferenceWithQuantifiers(){
        do {
            let result = try generatedStringSerialization(for: "@error(\"expected a\")a = @error(\"inner a\") \"a\"\naa = a+ \" \" @error(\"error a2\") a+", desiredRule: 1)
            
            XCTAssert(result == "tokenA =  (@error(\"expected a\") a = @error(\"expected a\") \"a\"+  \" \" @error(\"error a2\") a = @error(\"expected a\") \"a\"+)", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testRepeatedReference(){
        do {
            let result = try generatedStringSerialization(for: "@error(\"Expected a1\") a1 = \"a\" @error(\"Expected 1\") \"1\"\ndoubleA1 = a1 @error(\"Expected second a1\") a1", desiredRule: 1)
            
            XCTAssert(result == "tokenA =  (a1 = @error(\"Expected a1\") ( \"a\" @error(\"Expected 1\") \"1\") a1 = @error(\"Expected second a1\") ( \"a\" @error(\"Expected 1\") \"1\"))", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
}
