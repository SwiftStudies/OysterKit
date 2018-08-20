//
//  GrammarTest.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import XCTest
@testable import OysterKit
@testable import STLR

extension String {
    mutating func add(line: String){
        self = self + line + "\n"
    }
}

class GrammarTest: XCTestCase {

    var source = ""
    
    override func setUp() {
        super.setUp()
        source = ""
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testString(){
        let testData = [
            (" ",true,1),
            ("\\\"",true,2),
            ("\"something longer",false,17),
            ]
        
        
        
        for test in testData{
            let parser = TestParser(source: "\"\(test.0)\"", grammar: [STLR.terminalString._rule()])
            
            guard let result = parser.makeIterator().next() else {
                XCTAssert(!test.1, "Tokenization failed when it should have succeeded for \(test.0)")
                continue
            }
            
            XCTAssert(test.1, "Tokenization succeeded when it should have failed for: "+test.0)
            XCTAssert(result.token == STLR.terminalString, "Incorrect token type \(result.token)")
        }
    }

    func testIdentifier(){
        let testIds = [
            ("x",true),
            ("xX",true),
            ("x2",true),
            ("2",false),
            ("x_2",true),
            ("_2",true),
        ]
        
        for test in testIds{
            let parser = TestParser(source: test.0, grammar: [STLR.identifier._rule()])
            
            guard let result = parser.makeIterator().next() else {
                XCTAssert(!test.1, "Tokenization failed when it should have succeeded for \(test.0)")
                continue
            }
            
            XCTAssert(test.1, "Tokenization succeeded when it should have failed")
            XCTAssert(result.token == STLR.identifier, "Incorrect token type \(result.token)")
            
//            XCTAssert(result[test.0] == test.0, "Incorrect token value \(result[source])")
            
        }
    }
    
    func net(_ block:() throws ->Void) {
        do {
            try block()
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testRuleWithTerminal(){
        net(){
            source.add(line: "x = \"x\"")
            
            let stlr = try _STLR.build(testGrammarName+source)
            
            let ast = stlr.grammar
            
            XCTAssert(ast.rules.count == 1, "Found \(ast.rules.count) rules when there should be 1")
            
            if ast.rules.count < 1 {
                return
            }
            
            XCTAssert(ast.rules[0].identifier == "x")
        }
    }
    
    func testRuleWithRegularExpression(){
        net(){
            source.add(line: "animal = /Cat|Dog/")
            
            let stlr = try _STLR.build(testGrammarName+source)
            
            let ast = stlr.grammar
            
            XCTAssert(ast.rules.count == 1, "Found \(ast.rules.count) rules when there should be 1")
            
            if ast.rules.count < 1 {
                return
            }
            
            XCTAssert(ast.rules[0].identifier == "animal")
            XCTAssertEqual(ast.rules[0].description, "animal = /Cat|Dog/")
        }
    }

    func checkGeneratedLanguage(language:Language?, on source:String, expecting: [String]) throws {
        let debugOutput = false
        guard let language = language else {
            throw CheckError.checkFailed(reason: "Language did not compile")
        }
        
        defer {
            if debugOutput {
                print("Debugging:")
                print("\tSource: \(source)")
                print("\tLanguage: \(language.grammar)")
                print("Output:")
                do {
                    print(try AbstractSyntaxTreeConstructor().build(source, using: language).description)
                } catch {
                    print("Errors: \(error)")
                }
            }
        }
        
        let stream = TokenStream(source, using: language)
        
        let iterator = stream.makeIterator()
        
        var acquiredTokens = [Token]()
        var count = 0
        while let node = iterator.next() {
            acquiredTokens.append(node.token)
            if expecting.count > count {
                if "\(node.token)" != expecting[count] {
                    throw CheckError.checkFailed(reason: "Token at position \(count) was \(node.token)[\(node.token.rawValue)] but expected \(expecting[count])")
                }
            } else {
                throw CheckError.checkFailed(reason: "Moved past of the end of the expected list")
            }
            count += 1
        }

        if count != expecting.count {
            throw CheckError.checkFailed(reason: "Incorrect tokens count \(expecting.count) but got \(count) in \(acquiredTokens)")
        }
    }
    
    enum CheckError : Error, CustomStringConvertible {
        case checkFailed(reason: String)

        var description: String{
            switch  self {
            case .checkFailed(let reason):
                return reason
            }
        }
    }
    
    func generateAndCheck(grammar:String, parsing testString:String, expecting: [String]) throws {
        net() {
            let language = try _STLR.build(testGrammarName+grammar)
            let ast = language.grammar
            
            let parser = Parser(grammar: ast.dynamicRules)
        
            var count = 0
            
            for node in TokenStream(testString, using: parser){
                if count >= expecting.count{
                    throw CheckError.checkFailed(reason: "Too many tokens")
                }
                
                if expecting[count] != "\(node.token)" {
                    throw CheckError.checkFailed(reason: "At position \(count) expected \(expecting[count]) but got \(node.token)")
                }
                
                count += 1
            }
        }
    }
    
    func testInlineError(){
        net(){
            source.add(line: "xy = \"x\" @error(\"expected y\")@custom\"y\"")
            
            let parser = try _STLR.build(testGrammarName+source)
            
            guard parser.grammar.rules.count == 1 else {
                XCTFail("Expected just one rule but got \(parser.grammar.rules.count): \(parser.grammar.rules)")
                return
            }
            
            let language = Parser(grammar: parser.grammar.dynamicRules)
            
            do {
                let _ = try AbstractSyntaxTreeConstructor().build("xx", using: language)
                return
            } catch AbstractSyntaxTreeConstructor.ConstructionError.constructionFailed(let errors) {
                XCTAssertEqual(errors.count, 1)
                let errorText = "\(errors[0])"
                
                XCTAssert(errorText.hasPrefix("expected y"), "Unexpected error \(errorText)")
            } catch {
                XCTFail("Expected a single error")
                return
            }
        }
    
    }
    
    func testRecursiveRule(){
        net(){
            source.add(line: "x = \"x\"")
            source.add(line: "justX = x")
            source.add(line: "xy = x \"y\"")
            
            let stlr = try _STLR.build(testGrammarName+source)
            
            let ast = stlr.grammar
            
            XCTAssert(ast.rules.count == 3, "Found \(ast.rules.count) rules when there should be 1")
            XCTAssert(ast.rules[0].identifier == "x")
            XCTAssert(ast.rules[1].identifier == "justX")
            XCTAssert(ast.rules[2].identifier == "xy")
            
            do {
                try checkGeneratedLanguage(language: Parser(grammar: ast.dynamicRules), on: "xyx", expecting: ["justX","xy"])
            } catch (let error) {
                XCTFail("\(error)")
            }
        }
    }
    
    func testSimpleLookahead(){
        net(){
            source.add(line: "x  = \"x\" >>!\"y\" ")
            source.add(line: "xy = \"x\" \"y\" ")
            
            let stlr = try _STLR.build(testGrammarName+source)
            
            let ast = stlr.grammar
            guard ast.rules.count == 2 else {
                XCTFail("Found \(ast.rules.count) rules when there should be 2")
                return
            }
            
            XCTAssert(ast.rules[0].identifier == "x")
            XCTAssert(ast.rules[1].identifier == "xy")
            
            do {
                try checkGeneratedLanguage(language: Parser(grammar: ast.dynamicRules), on: "xxyx", expecting: ["x","xy","x"])
            } catch (let error) {
                XCTFail("\(error)")
            }
        }
    }
    
    let testGrammarName = "grammar GrammarTest\n"
    
    func testQuantifiersNotAddedToIdentifierNames(){
        net(){
            source.add(line: "ws = .whitespace")
            source.add(line: "whitespace = ws+")
            source.add(line: "word = .letter+")
            
            let stlr = try _STLR.build(testGrammarName+source)
            
            let ast = stlr.grammar
            
            XCTAssert(ast.rules.count == 3, "Found \(ast.rules.count) rules when there should be 1")
            XCTAssert(ast.rules[0].identifier == "ws")
            XCTAssert(ast.rules[1].identifier  == "whitespace")
            XCTAssert(ast.rules[2].identifier == "word")
            
            do {
                try checkGeneratedLanguage(language: Parser(grammar: ast.dynamicRules), on: "hello world", expecting: ["word","whitespace","word"])
            } catch (let error) {
                XCTFail("\(error)")
            }

        }
    }
    
    func testRuleWithIdentifier(){
        net(){
            source.add(line: "x = y")
            
            let stlr = try _STLR.build(testGrammarName+source)
            
            let ast = stlr.grammar
            
            XCTAssert(ast.rules.count == 1, "Found \(ast.rules.count) rules when there should be 1")
            
            if ast.rules.count < 1 {
                return
            }
            
            XCTAssert(ast.rules[0].identifier == "x")
        }
    }
    

    

    
    func testShallowFolding(){
        let source = """
            space = .whitespaces
            spaces = space+
            """
        
        let testString = "    "
        
        do {
            try generateAndCheck(grammar: source, parsing: testString, expecting: ["spaces"])
        } catch (let error) {
            XCTFail("\(error)")
        }
    }
    
    func testWords(){
        let source = "capitalLetter = \"A\"...\"Z\"\nlowercaseLetter = \"a\"...\"z\"\nlowercaseWord = lowercaseLetter+\ncapitalizedWord = capitalLetter lowercaseLetter*\nword = capitalizedWord | lowercaseWord\nspace = .whitespaces \nspaces = space+\n"
        
        let testString = "Hello  world"
        
        do {
            try generateAndCheck(grammar: source, parsing: testString, expecting: ["word","spaces","word"])
        } catch (let error) {
            XCTFail("\(error)")
        }
    }
    
    
    func testTerminal() {
        net(){
            source.add(line: "x = \"x\"")
            source.add(line: "y = \"y\"")
            source.add(line: "z=\"z\"")
            
            let stlr = try _STLR.build(testGrammarName+source)
            
            let ast = stlr.grammar
            
            XCTAssert(ast.rules.count == 3, "Found \(ast.rules.count) rules when there should be 3")
            
            if ast.rules.count < 3 {
                return
            }
            
            XCTAssert(ast.rules[0].identifier == "x")
            XCTAssert(ast.rules[1].identifier == "y")
            XCTAssert(ast.rules[2].identifier == "z")
        }
    }
    
    func testUnknownCharacterSet(){
        do{
            source.add(line: "hello = \"hello\" .whiteSpacesAndNewlines")
            
            _ = try _STLR.build(testGrammarName+source)
            
            XCTFail("Expected an error")
        } catch AbstractSyntaxTreeConstructor.ConstructionError.constructionFailed(let causes) {
            
            guard causes.count == 4 else {
                XCTFail("Expected 4 errors but got \(causes.count)\n\(causes)")
                return
            }

            XCTAssert("\(causes[0])".hasPrefix("Unknown character set"),"Incorrect error \(causes[0])")
            XCTAssert("\(causes[1])".hasPrefix("Expected expression"),"Incorrect error \(causes[1])")
        } catch {
            XCTFail("Incorrect error type")
        }
    }
    
    func testUnterminatedString(){
        do {
            source.add(line: "hello = \"hello")
            
            _ = try _STLR.build(testGrammarName+source)

            XCTFail("Expected an error")
        } catch AbstractSyntaxTreeConstructor.ConstructionError.constructionFailed(let errors){
            guard errors.count == 4 else {
                XCTFail("Expected 4 errors but got \(errors.count)\n\(errors)")
                return
            }
            
            XCTAssert("\(errors[0])".hasPrefix("Missing terminating quote"),"Incorrect error \(errors[0])")
            XCTAssert("\(errors[1])".hasPrefix("Expected expression"),"Incorrect error \(errors[0])")
        } catch {
            XCTFail("Incorrect error type")
        }
        
    }
    
    
    func testAnnotationsOnIdentifiers(){
        let parser : _STLR
        do {
            source.add(line: "x = \"x\"")
            source.add(line: "xyz = @error(\"Expected X\")\nx \"y\" \"z\"")
            
            parser = try _STLR.build(testGrammarName+source)
            
            let compiledLanguage = Parser(grammar:parser.grammar.dynamicRules)
            
            _ = try AbstractSyntaxTreeConstructor().build("yz", using: compiledLanguage)

            XCTFail("Expected an error \(parser.grammar.rules[1])")
        } catch AbstractSyntaxTreeConstructor.ConstructionError.constructionFailed(let errors) {
            XCTAssert("\(errors[0])".hasPrefix("Expected X"),"Incorrect error \(errors)")
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
    
    func testAnnotationsOnGroups(){
        net(){
            source.add(line: "x = \"x\"")
            source.add(line: "xyz = @error(\"Expected xy\")(@error(\"Expected x\")x \"y\") \"z\"")
            
            let parser = try _STLR.build(testGrammarName+source)
            
            do {
                let _ = try AbstractSyntaxTreeConstructor().build("yz", using: Parser(grammar: parser.grammar.dynamicRules))
                XCTFail("Expected an error \(parser.grammar.rules[rangeChecked: 1]?.description ?? "but the rule is missing")")
            } catch AbstractSyntaxTreeConstructor.ConstructionError.constructionFailed(let errors) {
                guard let error = errors.first else {
                    XCTFail("Expected an error \(parser.grammar.rules[1])")
                    return
                }
                XCTAssert("\(error)".hasPrefix("Expected x"),"Incorrect error \(error)")
            } catch {
                XCTFail("Unexpected error \(error)")
            }
        }
        
    }
}
