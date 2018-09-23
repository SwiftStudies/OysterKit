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
@testable import TestingSupport

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
            
            let stlr = try ProductionSTLR.build(testGrammarName+source)
            
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
            
            let stlr = try ProductionSTLR.build(testGrammarName+source)
            
            let ast = stlr.grammar
            
            XCTAssert(ast.rules.count == 1, "Found \(ast.rules.count) rules when there should be 1")
            
            if ast.rules.count < 1 {
                return
            }
            
            XCTAssert(ast.rules[0].identifier == "animal")
            XCTAssertEqual(ast.rules[0].description, "animal = /Cat|Dog/")
        }
    }

    func checkGeneratedLanguage(language:Grammar?, on source:String, expecting: [String]) throws {
        let debugOutput = false
        guard let language = language else {
            throw CheckError.checkFailed(reason: "Grammar did not compile")
        }
        
        defer {
            if debugOutput {
                print("Debugging:")
                print("\tSource: \(source)")
                print("\tLanguage: \(language.rules)")
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
        
        var acquiredTokens = [TokenType]()
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
        let language = try ProductionSTLR.build(testGrammarName+grammar)
        let ast = language.grammar
        
        let parser = ast.dynamicRules
    
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
    
    func testInlineError(){
        net(){
            source.add(line: "xy = \"x\" @error(\"expected y\")@custom\"y\"")
            
            let parser = try ProductionSTLR.build(testGrammarName+source)
            
            guard parser.grammar.rules.count == 1 else {
                XCTFail("Expected just one rule but got \(parser.grammar.rules.count): \(parser.grammar.rules)")
                return
            }
            
            let language = parser.grammar.dynamicRules
            
            do {
                let _ = try AbstractSyntaxTreeConstructor().build("xx", using: language)
                return
            } catch let error as ProcessingError {
                XCTAssertEqual(error.causedBy?.count ?? 0, 1)
                
                XCTAssert(error.hasCause(description: "Parsing Error: expected y"), "Did not find expected cause in \(error)")
            } catch {
                XCTFail("Expected a single error")
                return
            }
        }
    
    }
    
    func testRecursiveRule(){
        net(){
            source.add(line: "x = \"x\"")
            source.add(line: "xy = x \"y\"")
            source.add(line: "justX = x")
            
            let stlr = try ProductionSTLR.build(testGrammarName+source)
            
            let ast = stlr.grammar
            
            XCTAssertEqual(3,ast.rules.count)
            XCTAssertEqual(ast.rules[0].identifier,"x")
            XCTAssertEqual(ast.rules[2].identifier,"justX")
            XCTAssertEqual(ast.rules[1].identifier,"xy")
            
            do {
                try checkGeneratedLanguage(language: ast.dynamicRules, on: "xyx", expecting: ["xy","justX"])
            } catch (let error) {
                XCTFail("\(error)")
            }
        }
    }
    
    func testSimpleLookahead(){
        net(){
            source.add(line: "x  = \"x\" >>!\"y\" ")
            source.add(line: "xy = \"x\" \"y\" ")
            
            let stlr = try ProductionSTLR.build(testGrammarName+source)
            
            let ast = stlr.grammar
            guard ast.rules.count == 2 else {
                XCTFail("Found \(ast.rules.count) rules when there should be 2")
                return
            }
            
            XCTAssert(ast.rules[0].identifier == "x")
            XCTAssert(ast.rules[1].identifier == "xy")
            
            do {
                try checkGeneratedLanguage(language: ast.dynamicRules, on: "xxyx", expecting: ["x","xy","x"])
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
            
            let stlr = try ProductionSTLR.build(testGrammarName+source)
            
            let ast = stlr.grammar
            
            XCTAssert(ast.rules.count == 3, "Found \(ast.rules.count) rules when there should be 1")
            XCTAssert(ast.rules[0].identifier == "ws")
            XCTAssert(ast.rules[1].identifier  == "whitespace")
            XCTAssert(ast.rules[2].identifier == "word")
            
            do {
                try checkGeneratedLanguage(language: ast.dynamicRules, on: "hello world", expecting: ["word","whitespace","word"])
            } catch (let error) {
                XCTFail("\(error)")
            }

        }
    }
    
    func testRuleWithIdentifier(){
        net(){
            source.add(line: "x = y")
            
            let stlr = try ProductionSTLR.build(testGrammarName+source)
            
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
            space = .whitespace
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
        let source = "capitalLetter = \"A\"...\"Z\"\nlowercaseLetter = \"a\"...\"z\"\nlowercaseWord = lowercaseLetter+\ncapitalizedWord = capitalLetter lowercaseLetter*\nword = capitalizedWord | lowercaseWord\nspace = .whitespace \nspaces = space+\n"
        
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
            
            let stlr = try ProductionSTLR.build(testGrammarName+source)
            
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
        //FIXME: Add .endOfFile and update STLR.stlr to end with rule+ ows @error("Unable to finish parsing because of previous errors") .endOfFile
        do{
            source.add(line: "hello = \"hello\" .whiteSpacesAndNewlines")
            
            _ = try TestSTLR.build(testGrammarName+source)
            
            XCTFail("Expected an error")
        } catch let error as ProcessingError {
            #warning("We need to do something much smarter here")
//            guard causes.count == 4 else {
//                XCTFail("Expected 4 errors but got \(causes.count)\n\(causes)")
//                return
//            }
//
//            XCTAssert("\(causes[0])".hasPrefix("Unknown character set"),"Incorrect error \(causes[0])")
//            XCTAssert("\(causes[1])".hasPrefix("Expected expression"),"Incorrect error \(causes[1])")
        } catch {
            XCTFail("Incorrect error type")
        }
    }
    
    func testUnterminatedString(){
        do {
            source.add(line: "hello = \"hello")
            
            _ = try ProductionSTLR.build(testGrammarName+source)

            XCTFail("Expected an error")
        } catch let error as ProcessingError {
            #warning("We need to do something much smarter here")
//            guard errors.count == 4 else {
//                XCTFail("Expected 4 errors but got \(errors.count)\n\(errors)")
//                return
//            }
//            
//            XCTAssert("\(errors[0])".hasPrefix("Missing terminating quote"),"Incorrect error \(errors[0])")
//            XCTAssert("\(errors[1])".hasPrefix("Expected expression"),"Incorrect error \(errors[0])")
        } catch {
            XCTFail("Incorrect error type")
        }
        
    }
    
    
    func testAnnotationsOnIdentifiers(){
        let parser : ProductionSTLR
        do {
            source.add(line: "x = \"x\"")
            source.add(line: "xyz = @error(\"Expected X\")\nx \"y\" \"z\"")
            
            parser = try ProductionSTLR.build(testGrammarName+source)
            
            let compiledLanguage = parser.grammar.dynamicRules
            
            _ = try AbstractSyntaxTreeConstructor().build("yz", using: compiledLanguage)

            XCTFail("Expected an error \(parser.grammar.rules[1])")
        } catch let error as ProcessingError {
            let desired = error.filtered { (error) -> Bool in
                return (error as? ProcessingError)?.message ?? "" == "Parsing Error: Expected X at 0"
            }
            XCTAssertNotNil(desired)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
    
    func testAnnotationsOnGroups(){
        net(){
            source.add(line: "x = \"x\"")
            source.add(line: "xyz = @error(\"Expected xy\")(@error(\"Expected x\")x \"y\") \"z\"")
            
            let parser = try ProductionSTLR.build(testGrammarName+source)
            
            do {
                let _ = try AbstractSyntaxTreeConstructor().build("yz", using: parser.grammar.dynamicRules)
                XCTFail("Expected an error \(parser.grammar.rules[rangeChecked: 1]?.description ?? "but the rule is missing")")
            } catch let error as ProcessingError {
                let desired = error.filtered { (error) -> Bool in
                    return (error as? ProcessingError)?.message ?? "" == "Parsing Error: Expected x at 0"
                }
                XCTAssertNotNil(desired)
            } catch {
                XCTFail("Unexpected error \(error)")
            }
        }
    }
    
    func testFatalError(){
        #warning("This demonstrates a bug in referenced rules. The annotation is lost (although exists in the generated Swift) for error (not captured by any match) on expression. ")
        do {
            
            _ = try ProductionSTLR.build(
                    """
                        grammar Test

                        whitespace = .whitespace
                        newline = .newLine
                    """)
            
            XCTFail("Should have had a fatal error")
        } catch let error as ProcessingError {
            let desired = error.filtered(including: [.fatal])?.filtered { (error) -> Bool in
                return (error as? ProcessingError)?.message ?? "" == "Fatal Error: Expected expression"
            }
            XCTAssertNotNil(desired)
        } catch {
            XCTFail("Incorrect error \(error)")
        }
    }
}
