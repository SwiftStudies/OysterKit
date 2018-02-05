//
//  SwiftGenerationTest.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import XCTest
@testable import OysterKit
@testable import STLR

private enum Tokens : Int, Token {
    case tokenA = 1
}

private enum TestError : Error {
    case expected(String)
}

class SwiftGenerationTest: XCTestCase {
    
    enum TestTokens : Int, Token {
        case testToken
    }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        STLRScope.removeAllOptimizations()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func swift(for source:String, desiredIdentifier identifierName:String)throws ->String {
        let ast = STLRParser(source: source).ast
        
        guard let identifier = ast.identifiers[identifierName] else {
            throw TestError.expected("Missing identifier \(identifierName)")
        }

        let swift = identifier.swift(from: ast, creating: Tokens.tokenA).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")
        
        return swift
    }
    
    func swift(for source:String, desiredRule rule: Int = 0)throws ->String {
        let ast = STLRParser(source: source).ast
        
        if ast.rules.count <= rule {
            throw TestError.expected("at least \(rule + 1) rule, but got \(ast.rules.count)")
        }
        
        let swift = ast.rules[rule].swift(depth: 0, from: ast, creating: Tokens.tokenA , annotations: []).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")
        
        return swift
    }

    func testIdentifierElementGenerationWithAnnotations(){
        
        let stlrIr = STLRScope()
        
        let terminalElement = STLRScope.Element.terminal(
            STLRScope.Terminal(
                with: "T"
            ),
            STLRScope.Modifier.one,
            false,
            [])
        
        let terminalExpression = STLRScope.Expression.element(terminalElement)
        
        let annotations : STLRScope.ElementAnnotations = [
            STLRScope.ElementAnnotationInstance(STLRScope.ElementAnnotation.error, value: STLRScope.ElementAnnotationValue.string("ERRORVALUE"))
        ]
        
        let withoutAnnotations = terminalExpression.swift(depth: 0, from: stlrIr, creating: TestTokens.testToken, annotations: [])
        let withAnnotations    = terminalExpression.swift(depth: 0, from: stlrIr, creating: TestTokens.testToken, annotations: annotations)

        print(withAnnotations)
        print(withoutAnnotations)
        
        XCTAssertEqual(withoutAnnotations, "\t\t\t\"T\".terminal(token: T.testToken, annotations: annotations)\n\n")
        XCTAssertEqual(withAnnotations, "\t\t\t\"T\".terminal(token: T.testToken, annotations: annotations.isEmpty ? [RuleAnnotation.error : RuleAnnotationValue.string(\"ERRORVALUE\")] : annotations)\n\n")
    }
    
    func testOneOfRuleGeneration(){
        let stlrIr = STLRScope()
        
        let embeddedChoice = STLRScope.Expression.choice([
            STLRScope.Element.identifier(STLRScope.Identifier.init(name: "id", rawValue: 1), STLRScope.Modifier.one, false, []),
            STLRScope.Element.terminal(STLRScope.Terminal.init(with: "c"), STLRScope.Modifier.one, false, [])
            ])

        
        let choiceExpression = STLRScope.Expression.choice([
                STLRScope.Element.identifier(STLRScope.Identifier.init(name: "id", rawValue: 1), STLRScope.Modifier.one, false, []),
                STLRScope.Element.terminal(STLRScope.Terminal.init(with: "a"), STLRScope.Modifier.one, false, []),
                STLRScope.Element.terminal(STLRScope.Terminal.init(with: "b"), STLRScope.Modifier.one, false, []),
                STLRScope.Element.group(embeddedChoice, STLRScope.Modifier.one, false, [])
            ])
        
        let swift = choiceExpression.swift(from: stlrIr, creating: TestTokens.testToken, annotations: [])
        
        XCTAssertEqual(swift, "\t[\n\tT.id._rule(),\n\t\"a\".terminal(token: T._transient),\n\t\"b\".terminal(token: T._transient),\n\t[\n\t\t\t\t\tT.id._rule(),\n\t\t\t\t\t\"c\".terminal(token: T._transient),\n\t\t\t\t\t].oneOf(token: T._transient),\n\t].oneOf(token: T.testToken, annotations: annotations)\n")
    }
    
    func testSequenceRuleGeneration(){
        let stlrIr = STLRScope()
        
        let embeddedSequence = STLRScope.Expression.sequence([
            STLRScope.Element.identifier(STLRScope.Identifier.init(name: "id", rawValue: 1), STLRScope.Modifier.one, false, []),
            STLRScope.Element.terminal(STLRScope.Terminal.init(with: "c"), STLRScope.Modifier.one, false, [])
            ])
        
        
        let sequenceExpression = STLRScope.Expression.sequence([
            STLRScope.Element.identifier(STLRScope.Identifier.init(name: "id", rawValue: 1), STLRScope.Modifier.one, false, []),
            STLRScope.Element.terminal(STLRScope.Terminal.init(with: "a"), STLRScope.Modifier.one, false, []),
            STLRScope.Element.terminal(STLRScope.Terminal.init(with: "b"), STLRScope.Modifier.one, false, []),
            STLRScope.Element.group(embeddedSequence, STLRScope.Modifier.one, false, [])
            ])
        
        let swift = sequenceExpression.swift(from: stlrIr, creating: TestTokens.testToken, annotations: [])
        
        XCTAssertEqual(swift, "\t[\n\tT.id._rule(),\n\t\"a\".terminal(token: T._transient),\n\t\"b\".terminal(token: T._transient),\n\t[\n\t\t\t\t\tT.id._rule(),\n\t\t\t\t\t\"c\".terminal(token: T._transient),\n\t\t\t\t\t].sequence(token: T._transient),\n\t].sequence(token: T.testToken, annotations: annotations.isEmpty ? [ : ] : annotations)\n")
    }

    func testSequenceRuleGenerationWithEmbeddedQuantifiers(){
        let stlrIr = STLRScope()
        
        let embeddedSequence = STLRScope.Expression.sequence([
            STLRScope.Element.identifier(STLRScope.Identifier.init(name: "id", rawValue: 1), STLRScope.Modifier.one, false, []),
            STLRScope.Element.terminal(STLRScope.Terminal.init(with: "c"), STLRScope.Modifier.one, false, [])
            ])
        
        
        let sequenceExpression = STLRScope.Expression.sequence([
            STLRScope.Element.identifier(STLRScope.Identifier.init(name: "id", rawValue: 1), STLRScope.Modifier.oneOrMore, false, []),
            STLRScope.Element.terminal(STLRScope.Terminal.init(with: "a"), STLRScope.Modifier.oneOrMore, false, []),
            STLRScope.Element.terminal(STLRScope.Terminal.init(with: "b"), STLRScope.Modifier.one, false, []),
            STLRScope.Element.group(embeddedSequence, STLRScope.Modifier.oneOrMore, false, [])
            ])
        
        let swift = sequenceExpression.swift(from: stlrIr, creating: TestTokens.testToken, annotations: [])
        
        XCTAssertEqual(swift, "\t[\n\tT.id._rule().repeated(min: 1, producing: T._transient),\n\t\"a\".terminal(token: T._transient).repeated(min: 1, producing: T._transient),\n\t\"b\".terminal(token: T._transient),\n\t[\n\t\t\t\t\tT.id._rule(),\n\t\t\t\t\t\"c\".terminal(token: T._transient),\n\t\t\t\t\t].sequence(token: T._transient).repeated(min: 1, producing: T._transient),\n\t].sequence(token: T.testToken, annotations: annotations.isEmpty ? [ : ] : annotations)\n")
    }
    
    func testPredefinedCharacterSet() {
        do {
            let result = try swift(for: "letter = @error(\"error\").whitespaces")
            
            XCTAssertEqual(result,"CharacterSet.whitespaces.terminal(token: T.tokenA, annotations: annotations.isEmpty ? [RuleAnnotation.error : RuleAnnotationValue.string(\"error\")] : annotations)")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testCustomCharacterSet() {
        do {
            let result = try swift(for: "letter = @error(\"error\") \"a\"...\"z\"")
            
            XCTAssertEqual(result,"CharacterSet(charactersIn: \"a\".unicodeScalars.first!...\"z\".unicodeScalars.first!).terminal(token: T.tokenA, annotations: annotations.isEmpty ? [RuleAnnotation.error : RuleAnnotationValue.string(\"error\")] : annotations)")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testTerminal(){
        do {
            let result = try swift(for: "letter = @error(\"error\") \"hello\"")
            
            XCTAssertEqual(result,"\"hello\".terminal(token: T.tokenA, annotations: annotations.isEmpty ? [RuleAnnotation.error : RuleAnnotationValue.string(\"error\")] : annotations)")
        } catch (let error){
            XCTFail("\(error)")
        }
    }

    func testSingleCharacterTerminal(){
        do {
            let result = try swift(for: "letter = @error(\"error\") \"h\"")
            
            XCTAssertEqual(result,"\"h\".terminal(token: T.tokenA, annotations: annotations.isEmpty ? [RuleAnnotation.error : RuleAnnotationValue.string(\"error\")] : annotations)")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testTerminalChoiceWithIndividualAnnotations(){
        do {
            let result = try swift(for: "letter = @error(\"error a\") \"a\"| @error(\"error b\")\"b\"| @error(\"error c\") \"c\"").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")
            
            XCTAssertEqual(result, "[\"a\".terminal(token: T._transient, annotations: [RuleAnnotation.error : RuleAnnotationValue.string(\"error a\")]),\"b\".terminal(token: T._transient, annotations: [RuleAnnotation.error : RuleAnnotationValue.string(\"error b\")]),\"c\".terminal(token: T._transient, annotations: [RuleAnnotation.error : RuleAnnotationValue.string(\"error c\")]),].oneOf(token: T.tokenA, annotations: annotations)")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testTerminalChoiceWithIndividualAnnotationsOptimized(){
        STLRScope.register(optimizer: InlineIdentifierOptimization())
        STLRScope.register(optimizer: CharacterSetOnlyChoiceOptimizer())
        do {
            let result = try swift(for: "letter = @error(\"error a\") \"a\"| @error(\"error b\")\"b\"| @error(\"error c\") \"c\"").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")
            
            XCTAssertEqual(result, "[\"a\".terminal(token: T._transient, annotations: [RuleAnnotation.error : RuleAnnotationValue.string(\"error a\")]),\"b\".terminal(token: T._transient, annotations: [RuleAnnotation.error : RuleAnnotationValue.string(\"error b\")]),\"c\".terminal(token: T._transient, annotations: [RuleAnnotation.error : RuleAnnotationValue.string(\"error c\")]),].oneOf(token: T.tokenA, annotations: annotations)")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testTerminalChoice(){
        do {
            let result = try swift(for: "letter = @error(\"error\") (\"a\"|\"b\"|\"c\")")
            
            XCTAssert(result == "ScannerRule.oneOf(token: T.tokenA, [\"a\", \"b\", \"c\"],[RuleAnnotation.error : RuleAnnotationValue.string(\"error\")].merge(with: annotations))", "Bad Swift output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testTerminalSequence(){
        do {
            let result = try swift(for: "letter = @error(\"error\") (\"a\" \"b\" \"c\")")
            
            XCTAssert(result == "[\"a\".terminal(token: T._transient),\"b\".terminal(token: T._transient),\"c\".terminal(token: T._transient),].sequence(token: T.tokenA, annotations: annotations.isEmpty ? [RuleAnnotation.error : RuleAnnotationValue.string(\"error\")] : annotations)", "Bad Swift output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testTerminalSequenceWithIndividualAnnotations(){
        do {
            let result = try swift(for: "letter = @error(\"error a\") \"a\"  @error(\"error b\")\"b\"  @error(\"error c\") \"c\"").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")
            
            XCTAssert(result == "[\"a\".terminal(token: T._transient, annotations: [RuleAnnotation.error : RuleAnnotationValue.string(\"error a\")]),\"b\".terminal(token: T._transient, annotations: [RuleAnnotation.error : RuleAnnotationValue.string(\"error b\")]),\"c\".terminal(token: T._transient, annotations: [RuleAnnotation.error : RuleAnnotationValue.string(\"error c\")]),].sequence(token: T.tokenA, annotations: annotations.isEmpty ? [ : ] : annotations)", "Bad Swift output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testScannerRuleWithInjectedAnnotations(){
        do {
            let characterSetRule = try swift(for: "characterSet = \".\" @error(\"Invalid CharacterSet name\") characterSetName\ncharacterSetName = \"whitespaces\" | \"whiteSpacesAndNewlines\"").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")

            let characterSetNameRule = try swift(for: "characterSet = \".\" @error(\"Invalid CharacterSet name\") characterSetName\ncharacterSetName = \"whitespaces\" | \"whiteSpacesAndNewlines\"", desiredRule: 1).replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")
            
            
            XCTAssert(characterSetRule == "[\".\".terminal(token: T._transient),T.characterSetName._rule([RuleAnnotation.error : RuleAnnotationValue.string(\"Invalid CharacterSet name\")]),].sequence(token: T.tokenA, annotations: annotations.isEmpty ? [ : ] : annotations)", "Bad Swift output '\(characterSetRule)'")
            XCTAssert(characterSetNameRule == "ScannerRule.oneOf(token: T.tokenA, [\"whitespaces\", \"whiteSpacesAndNewlines\"],[ : ].merge(with: annotations))", "Bad Swift output '\(characterSetNameRule)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testAnnotatedNestedIdentifiers(){
        do {
            let result = try swift(for: "a = @error(\"a internal\")\"a\"\naa = @error(\"error a1\") a @error(\"error a2\") a", desiredRule: 1)
            
            XCTAssert(result == "[T.a._rule([RuleAnnotation.error : RuleAnnotationValue.string(\"error a1\")]),T.a._rule([RuleAnnotation.error : RuleAnnotationValue.string(\"error a2\")]),].sequence(token: T.tokenA, annotations: annotations.isEmpty ? [ : ] : annotations)", "Bad Swift output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testMergedAnnotationOnIdentifierReference(){
        do {
            let result = try swift(for: "@error(\"expected a\")a = @error(\"inner a\") \"a\"\naa = a @error(\"error a2\") a", desiredRule: 1)
            
            XCTAssert(result == "[T.a._rule([RuleAnnotation.error : RuleAnnotationValue.string(\"expected a\")]),T.a._rule([RuleAnnotation.error : RuleAnnotationValue.string(\"error a2\")]),].sequence(token: T.tokenA, annotations: annotations.isEmpty ? [ : ] : annotations)", "Bad Swift output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testMergedAnnotationOnIdentifierReferenceWithQuantifiers(){
        do {
            let result = try swift(for: "@error(\"expected a\")a = @error(\"inner a\") \"a\"\naa = a+ \" \" @error(\"error a2\") a+", desiredRule: 1)
            
            XCTAssertEqual(result,"[T.a._rule([RuleAnnotation.error : RuleAnnotationValue.string(\"expected a\")]).repeated(min: 1, producing: T._transient),\" \".terminal(token: T._transient),T.a._rule([RuleAnnotation.error : RuleAnnotationValue.string(\"expected a\")]).repeated(min: 1, producing: T._transient),].sequence(token: T.tokenA, annotations: annotations.isEmpty ? [ : ] : annotations)")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testIdentifierAndReference(){
        let stlrSource = """
            @void id    = @error("Expected id") "id"
            declaration = @error("Declaration requires id") id
"""
        
        let ast = STLRParser.init(source: stlrSource).ast
        
        let idSwift = ast.identifiers["id"]?.swift(from: ast, creating: TestTokens.testToken) ?? "nil"
        let declarationSwift = ast.identifiers["declaration"]?.swift(from: ast, creating: TestTokens.testToken) ?? "nil"
        
        XCTAssertEqual(idSwift, "\t\t\t\t\t\t\t\t\t\"id\".terminal(token: T.testToken, annotations: annotations.isEmpty ? [RuleAnnotation.error : RuleAnnotationValue.string(\"Expected id\"),RuleAnnotation.void : RuleAnnotationValue.set] : annotations)\n\n\n")
        XCTAssertEqual(declarationSwift, "\t\t\t\t\t[T.id._rule([RuleAnnotation.void : RuleAnnotationValue.set,RuleAnnotation.error : RuleAnnotationValue.string(\"Declaration requires id\")])].sequence(token: self)\n\n")
    }
    
    func testIdentifierAndReferenceInSequence(){
        let stlrSource = """
            @void id    = @error("Expected id") "id"
            declaration = @error("Declaration requires id") id .letters
"""
        
        let ast = STLRParser.init(source: stlrSource).ast
        
        let idSwift = ast.identifiers["id"]?.swift(from: ast, creating: TestTokens.testToken) ?? "nil"
        let declarationSwift = ast.identifiers["declaration"]?.swift(from: ast, creating: TestTokens.testToken) ?? "nil"
        
        XCTAssertEqual(idSwift, "\t\t\t\t\t\t\t\t\t\"id\".terminal(token: T.testToken, annotations: annotations.isEmpty ? [RuleAnnotation.error : RuleAnnotationValue.string(\"Expected id\"),RuleAnnotation.void : RuleAnnotationValue.set] : annotations)\n\n\n")
        XCTAssertEqual(declarationSwift, "\t\t\t\t\t[\n\t\t\tT.id._rule([RuleAnnotation.void : RuleAnnotationValue.set,RuleAnnotation.error : RuleAnnotationValue.string(\"Declaration requires id\")]),\n\t\t\tCharacterSet.letters.terminal(token: T._transient),\n\t\t\t].sequence(token: T.testToken, annotations: annotations.isEmpty ? [ : ] : annotations)\n\n")
    }
    
    func testIdentifierAndReferenceInGroupedSequence(){
        let stlrSource = """
            @void id    = @error("Expected id") "id"
            declaration = (@error("Declaration requires id") id .letters) .letters+
"""
        
        let ast = STLRParser.init(source: stlrSource).ast
        
        let idSwift = ast.identifiers["id"]?.swift(from: ast, creating: TestTokens.testToken) ?? "nil"
        let declarationSwift = ast.identifiers["declaration"]?.swift(from: ast, creating: TestTokens.testToken) ?? "nil"
        
        XCTAssertEqual(idSwift, "\t\t\t\t\t\t\t\t\t\"id\".terminal(token: T.testToken, annotations: annotations.isEmpty ? [RuleAnnotation.error : RuleAnnotationValue.string(\"Expected id\"),RuleAnnotation.void : RuleAnnotationValue.set] : annotations)\n\n\n")
        XCTAssertEqual(declarationSwift, "\t\t\t\t\t[\n\t\t\t[\n\t\t\t\t\t\t\tT.id._rule([RuleAnnotation.void : RuleAnnotationValue.set,RuleAnnotation.error : RuleAnnotationValue.string(\"Declaration requires id\")]),\n\t\t\t\t\t\t\tCharacterSet.letters.terminal(token: T._transient),\n\t\t\t\t\t\t\t].sequence(token: T._transient),\n\t\t\tCharacterSet.letters.terminal(token: T._transient).repeated(min: 1, producing: T._transient),\n\t\t\t].sequence(token: T.testToken, annotations: annotations.isEmpty ? [ : ] : annotations)\n\n")
    }
    
}
