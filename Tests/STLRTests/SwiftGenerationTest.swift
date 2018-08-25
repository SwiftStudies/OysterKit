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

fileprivate enum Tokens : Int, Token {
    case tokenA = 1
}

fileprivate enum TestError : Error {
    case expected(String)
}

fileprivate enum TestTokens : Int, Token {
    case testToken
}

class SwiftGenerationTest: XCTestCase {
    

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
        let ast = try _STLR.build("grammar SwiftGenerationTest\n"+source).grammar
        
        let identifier = ast[identifierName]
    
        let file = TextFile("Test")
        let swift = identifier.swift(in: file, grammar: ast).content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")
        
        return swift
    }
    
    func swift(for source:String, desiredRule rule: Int = 0)throws ->String {
        let ast = try _STLR.build("grammar SwiftGenerationTest\n"+source).grammar
        
        if ast.rules.count <= rule {
            throw TestError.expected("at least \(rule + 1) rule, but got \(ast.rules.count)")
        }
        
        let file = TextFile("Test")
        let swift = ast.rules[rule].swift(in: file, grammar: ast).content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")
        
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

//        print(withAnnotations)
//        print(withoutAnnotations)
        
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
            let result = try swift(for: "letter = @error(\"error\").whitespace")
            
            XCTAssertEqual(result,"CharacterSet.whitespaces.annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string(\"error\")]).reference(.structural(token: self))")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testCustomCharacterSet() {
        do {
            let result = try swift(for: "letter = @error(\"error\") \"a\"...\"z\"")
            
            XCTAssertEqual(result,"CharacterSet(charactersIn: \"a\".unicodeScalars.first!...\"z\".unicodeScalars.first!).annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string(\"error\")]).reference(.structural(token: self))")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testTerminal(){
        do {
            let result = try swift(for: "letter = @error(\"error\") \"hello\"")
            
            XCTAssertEqual(result,"\"hello\".annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string(\"error\")]).reference(.structural(token: self))")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testRegularExpression(){
        do {
            let result = try swift(for: "letter = @error(\"error\") /hello/ ")
            
            XCTAssertEqual(result,"T.regularExpression(\"^hello\").annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string(\"error\")]).reference(.structural(token: self))")
        } catch (let error){
            XCTFail("\(error)")
        }
    }

    func testSingleCharacterTerminal(){
        do {
            let result = try swift(for: "letter = @error(\"error\") \"h\"")
            
            XCTAssertEqual(result,"\"h\".annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string(\"error\")]).reference(.structural(token: self))")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testTerminalChoiceWithIndividualAnnotations(){
        do {
            let result = try swift(for: "letter = @error(\"error a\") \"a\"| @error(\"error b\")\"b\"| @error(\"error c\") \"c\"").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")
            
            XCTAssertEqual(result, "[    \"a\".annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string(\"error a\")]),    \"b\".annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string(\"error b\")]),    \"c\".annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string(\"error c\")])].choice.reference(.structural(token: self))")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    #warning("This needs to be changed when optimizers have been re-implemented")
    func testTerminalChoiceWithIndividualAnnotationsOptimized(){
        STLRScope.register(optimizer: InlineIdentifierOptimization())
        STLRScope.register(optimizer: CharacterSetOnlyChoiceOptimizer())
        do {
            let result = try swift(for: "letter = @error(\"error a\") \"a\"| @error(\"error b\")\"b\"| @error(\"error c\") \"c\"").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")
            
            XCTAssertEqual(result, "[    \"a\".annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string(\"error a\")]),    \"b\".annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string(\"error b\")]),    \"c\".annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string(\"error c\")])].choice.reference(.structural(token: self))")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testTerminalChoice(){
        do {
            let result = try swift(for: "letter = @error(\"error\") (\"a\"|\"b\"|\"c\")")
            
            XCTAssert(result == "[    \"a\",    \"b\",    \"c\"].choice.annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string(\"error\")]).reference(.structural(token: self))")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testTerminalSequence(){
        do {
            let result = try swift(for: "letter = @error(\"error\") (\"a\" \"b\" \"c\")")
            
            XCTAssert(result == "[    \"a\",    \"b\",    \"c\"].sequence.annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string(\"error\")]).reference(.structural(token: self))", "Bad Swift output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testTerminalSequenceWithIndividualAnnotations(){
        do {
            let result = try swift(for: "letter = @error(\"error a\") \"a\"  @error(\"error b\")\"b\"  @error(\"error c\") \"c\"").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")
            
            XCTAssert(result == "[    \"a\".annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string(\"error a\")]),    \"b\".annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string(\"error b\")]),    \"c\".annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string(\"error c\")])].sequence.reference(.structural(token: self))", "Bad Swift output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testScannerRuleWithInjectedAnnotations(){
        do {
            let characterSetRule = try swift(for: "characterSet = \".\" @error(\"Invalid CharacterSet name\") characterSetName\ncharacterSetName = \"whitespaces\" | \"whiteSpacesAndNewlines\"").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")

            let characterSetNameRule = try swift(for: "characterSet = \".\" @error(\"Invalid CharacterSet name\") characterSetName\ncharacterSetName = \"whitespaces\" | \"whiteSpacesAndNewlines\"", desiredRule: 1).replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")
            
            
            XCTAssert(characterSetRule == "[    \".\",    T.characterSetName.rule.annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string(\"Invalid CharacterSet name\")])].sequence.reference(.structural(token: self))", "Bad Swift output '\(characterSetRule)'")
            XCTAssert(characterSetNameRule == "[    \"whitespaces\",    \"whiteSpacesAndNewlines\"].choice.reference(.structural(token: self))", "Bad Swift output '\(characterSetNameRule)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testAnnotatedNestedIdentifiers(){
        do {
            let result = try swift(for: "a = @error(\"a internal\")\"a\"\naa = @error(\"error a1\") a @error(\"error a2\") a", desiredRule: 1)
            
            XCTAssert(result == "[    T.a.rule.annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string(\"error a1\")]),    T.a.rule.annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string(\"error a2\")])].sequence.reference(.structural(token: self))", "Bad Swift output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testMergedAnnotationOnIdentifierReference(){
        do {
            let result = try swift(for: "@error(\"expected a\")a = @error(\"inner a\") \"a\"\naa = a @error(\"error a2\") a", desiredRule: 1)
            
            XCTAssert(result == "[    T.a.rule,    T.a.rule.annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string(\"error a2\")])].sequence.reference(.structural(token: self))", "Bad Swift output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testMergedAnnotationOnIdentifierReferenceWithQuantifiers(){
        do {
            let result = try swift(for: "@error(\"expected a\")a = @error(\"inner a\") \"a\"\naa = a+ \" \" @error(\"error a2\") a+", desiredRule: 1)
            
            XCTAssertEqual(result,"[    T.a.rule.require(.oneOrMore),    \" \",    T.a.rule.require(.oneOrMore).annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string(\"error a2\")])].sequence.reference(.structural(token: self))")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testIdentifierAndReference(){
        do {
            let stlrSource = """
            grammar SwiftGenerationTest
            @void id    = @error("Expected id") "id"
            declaration = @error("Declaration requires id") id
"""
            
            let ast = try _STLR.build(stlrSource).grammar
            
            var file = TextFile("Test")
            let idSwift = ast["id"].swift(in: file, grammar: ast).content
            
            file = TextFile("Test")
            let declarationSwift = ast["declaration"].swift(in: file, grammar: ast).content
            
            XCTAssertEqual(idSwift, "\"id\".annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string(\"Expected id\")]).reference(.skipping, annotations: [RuleAnnotation.void:RuleAnnotationValue.set])\n")
            XCTAssertEqual(declarationSwift, "T.id.rule.annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string(\"Declaration requires id\")]).reference(.structural(token: self))\n")

        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testIdentifierAndReferenceInSequence(){
        do {
            let stlrSource = """
            grammar SwiftGenerationTest
            @void id    = @error("Expected id") "id"
            declaration = @error("Declaration requires id") id .letter
"""
            
            let ast = try _STLR.build(stlrSource).grammar
            
            let idSwift = ast["id"].swift(in: TextFile("Test"), grammar: ast).content
            let declarationSwift = ast["declaration"].swift(in: TextFile(""), grammar: ast).content
            
            XCTAssertEqual(idSwift, "\"id\".annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string(\"Expected id\")]).reference(.skipping, annotations: [RuleAnnotation.void:RuleAnnotationValue.set])\n")
            XCTAssertEqual(declarationSwift, "[    T.id.rule.annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string(\"Declaration requires id\")]),    CharacterSet.letters].sequence.reference(.structural(token: self))\n")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testIdentifierAndReferenceInGroupedSequence(){
        do {
            let stlrSource = """
            grammar SwiftGenerationTest
            @void id    = @error("Expected id") "id"
            declaration = (@error("Declaration requires id") id .letter) .letter+
"""
            
            let ast = try _STLR.build(stlrSource).grammar
            
            let idSwift = ast["id"].swift(in:TextFile(""), grammar: ast).content
            let declarationSwift = ast["declaration"].swift(in: TextFile(""), grammar: ast).content
            
            XCTAssertEqual(idSwift, "\"id\".annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string(\"Expected id\")]).reference(.skipping, annotations: [RuleAnnotation.void:RuleAnnotationValue.set])\n")
            XCTAssertEqual(declarationSwift, "[    [        T.id.rule.annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string(\"Declaration requires id\")]),        CharacterSet.letters].sequence,    CharacterSet.letters.require(.oneOrMore)].sequence.reference(.structural(token: self))\n")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
}
