//
//  FullSwiftGenerationTest.swift
//  OysterKitTests
//
//  Created on 15/07/2018.
//

import XCTest
@testable import OysterKit
@testable import STLR
@testable import ExampleLanguages

class FullSwiftGenerationTest: XCTestCase {
    var ast : HomogenousTree!
    
    static var testedTokens = Set<STLRTokens>()

    override class func setUp() {
        testedTokens.removeAll()
    }
    
    override class func tearDown() {
        // Assume that if only one token was tested then a single test was being run
        if testedTokens.count < 2 {
            return
        }
        
        let untestedTokens = STLRTokens.allCases.filter({!testedTokens.contains($0)})
        
        print("Not all tokens were tested:\n\t"+untestedTokens.map({"\($0)"}).joined(separator: "\n\t"))
        assert(untestedTokens.isEmpty)
    }
    
    func testGeneratedCode(){
        #warning("This should go")
        do {
            let source = try String(contentsOfFile: "/Users/nhughes/Documents/Code/SPM/OysterKit/Resources/STLR.stlr")
            let stlr = try _STLR.build(source)
            
            let operations = try SwiftStructure.generate(for: stlr, grammar: "Test", accessLevel: "public")
            
            let context = OperationContext(with: URL(fileURLWithPath: "/Users/nhughes/Documents/Code/SPM/OysterKit/Sources/ExampleLanguages")){
                print($0)
            }
            
            for operation in operations {
                try operation.perform(in: context)
            }
        } catch {
            print("Error: \(error)")
        }
    }

    func parse(source:String, with rule:Rule) throws{
        ast = nil
        ast = try AbstractSyntaxTreeConstructor().build(source, using: Parser(grammar:[rule]))
        
        print(ast.description)
    }
    
    func parse(source:String, with token:STLRTokens, ignoreNoNodes:Bool = true) throws {
        FullSwiftGenerationTest.testedTokens.insert(token)
        do {
            try parse(source: source, with: token.rule)
        } catch AbstractSyntaxTreeConstructor.ConstructionError.constructionFailed(let causes){
            if let primaryCause = causes.first {
                if "\(primaryCause)".hasPrefix("No nodes created") && ignoreNoNodes {
                    return
                }
            }
            throw TestError.parsingError(message: "Unexpected construction error", range: source.startIndex...source.endIndex, causes: causes)
        }
    }
    
    func checkSimplePassFail(for token:STLRTokens, passing:[String], failing:[String], expectNode:Bool, matches:[String] = []) throws {
        var count = 0
        for source in passing {
            try parse(source: source, with: token, ignoreNoNodes: !expectNode)
            if expectNode {
                if "\(token)" != "\(ast.token)" {
                    throw TestError.interpretationError(message: "\(ast.token) != \(token)", causes: [])
                }
                if matches.count > count {
                    if matches[count] != ast.matchedString {
                        throw TestError.interpretationError(message: "\(ast.token) expected to match \(matches[count]) but matched \(ast.matchedString)", causes: [])
                    }
                }
            }
            count += 1
        }
        
        for source in failing {
            do {
                try parse(source: "&", with: token)
                throw TestError.interpretationError(message: "\(source) should have failed to create \(token)", causes: [])
            } catch {}
        }
    }
    
    func testWhiteSpace(){
        XCTAssertNoThrow(
            try checkSimplePassFail(
                for: .whitespace,
                passing: [" ","\t\n","// Some comment\n","/*\nlsdkfjkldsjfdssfsd\n*/","// No need for a newline at the end"],
                failing: ["/*\nlsdkfjkldsjfdssfsd\n"], expectNode: false)
        )
    }
    
    func testOptionalWhiteSpace(){
        do {
            try parse(source: "ddd", with: ExampleLanguages.STLRTokens.ows, ignoreNoNodes: true)
            XCTAssertNil(ast)
        } catch TestError.parsingError(_, _, let causes){
            // It's OK that the lexer didn't advance
            if let primaryCause = causes.first {
                XCTAssert("\(primaryCause)".hasPrefix("Lexer not advanced"))
            } else {
                XCTFail("Unexpected error")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        do {
            try parse(source: " ", with: ExampleLanguages.STLRTokens.ows, ignoreNoNodes: true)
            XCTAssertNil(ast)
        } catch TestError.parsingError(_, _, let causes){
            // It's OK that the lexer didn't advance
            if let primaryCause = causes.first {
                XCTAssert("\(primaryCause)".hasPrefix("Lexer not advanced"))
            } else {
                XCTFail("Unexpected error")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }


    
    func testQuantifier(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .quantifier, passing: ["*","?","+"], failing: ["&"], expectNode: true))
    }
    
    func testNegated(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .negated, passing: ["!"], failing: ["&"], expectNode: true))
    }

    func testLookahead(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .lookahead, passing: [">>"], failing: [">&"], expectNode: true))
    }

    func testTransient(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .transient, passing: ["~"], failing: ["-","&"], expectNode: true))
    }
    
    func testVoid(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .void, passing: ["-"], failing: ["~","&"], expectNode: true))
    }

    func testStringQuote(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .stringQuote, passing: ["\""], failing: ["'","\\\""], expectNode: true))
    }
    
    func testTerminalBody(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .terminalBody, passing: ["lkjdslkf","\\\"escape quote should be ok"], failing: ["ddd","\""], expectNode: true))
    }

    func testStringBody(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .stringBody, passing: ["lkjdslkf","\\\"escape quote should be ok"], failing: ["ddd","\""], expectNode: true))
    }

    func testString(){
        let matches = [
            "ldkfjkldsjf",
            "lsdkfj\\\"lkdsjf",
            "\\\"",
            ""
        ]
        XCTAssertNoThrow(try checkSimplePassFail(for: .string, passing: matches.map({"\"\($0)\""}), failing: ["\"ddd","\"kdlsfj\n","dsfdsf"], expectNode: true, matches: matches))
    }
    
    func testTerminalString(){
        let matches = [
            "ldkfjkldsjf",
            "A",
            "\\\""
        ]
        XCTAssertNoThrow(try checkSimplePassFail(for: .terminalString, passing: matches.map({"\"\($0)\""}), failing: ["\"ddd","\"kdlsfj\n","dsfdsf","\"\""], expectNode: true, matches: matches))
    }

    fileprivate let characterSetNames = ["letter","uppercaseLetter","lowercaseLetter","alphaNumeric","decimalDigit","whitespaceOrNewline","whitespace","newline","backslash"]
    
    func testCharacterSetName(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .characterSetName, passing: characterSetNames, failing: ["sdfsdf",".anything"], expectNode: false))
    }
    
    func testCharacterSet(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .characterSet, passing: characterSetNames.map({".\($0)"}), failing: [".",".anything"], expectNode: true, matches: characterSetNames))
        #warning("Should check for the correct error here")
    }

    
    func testRangeOperator(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .rangeOperator, passing: ["..."], failing: [".","..","..<"], expectNode: false))
        #warning("Should check for the correct error here")
    }
    
    func testCharacterRange(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .characterRange, passing: ["\"a\"...\"b\""], failing: ["\"\"...\"b\"","\"a\"..","\"a\"...\"\",\"a\"..<\"b\""], expectNode: false))
        #warning("Should check for the correct error here")
    }
    
    func testNumber(){
        let passing = ["1","+1","-1","+1000","-1000","1000"]
        XCTAssertNoThrow(try checkSimplePassFail(for: .number, passing: passing, failing: ["a",".","+10.0"], expectNode: true, matches: passing))
        #warning("Should check for the correct error here")
    }

    func testBoolean(){
        let passing = ["true","false"]
        XCTAssertNoThrow(try checkSimplePassFail(for: .boolean, passing: passing, failing: ["trut","fal"], expectNode: true, matches: passing))
        #warning("Should check for the correct error here")
    }

    func testLiteral(){
        let passing = ["true","1","\"string\""]
        let matches = [passing[0],passing[1],"string"]
        XCTAssertNoThrow(try checkSimplePassFail(for: .literal, passing: passing, failing: ["trut"], expectNode: true, matches: matches))
        #warning("Should check for the correct error here")
    }

    func testDefinedLabel(){
        let passing = ["void",
                       "transient",
                       "error",
                       "token",
                       ]
        let failing = ["customLabel",
                       "voi",
                       ]
        XCTAssertNoThrow(try checkSimplePassFail(for: .definedLabel, passing: passing, failing: failing, expectNode: true))
        #warning("Should check for the correct errors")
    }

    
    func testCustomLabel(){
        let passing = ["_a",
                       "customLabel",
        ]
        let failing = ["_",
                       "3something",
                       ]
        XCTAssertNoThrow(try checkSimplePassFail(for: .customLabel, passing: passing, failing: failing, expectNode: true))
        #warning("Should check for the correct errors")
    }

    func testLabel(){
        let passing = ["void",
                       "customLabel",
                       "_customLabel",
                       ]
        let failing = [String]()
        XCTAssertNoThrow(try checkSimplePassFail(for: .label, passing: passing, failing: failing, expectNode: true, matches:passing))
        #warning("Should check for the correct errors")
        #warning("Should check for the correct node type")
    }
    
    func testRegexDelimeter(){
        let passing = ["/"
                       ]
        let failing = ["\\",
                       "d",
                       ]
        XCTAssertNoThrow(try checkSimplePassFail(for: .regexDelimeter, passing: passing, failing: failing, expectNode: false))
    }

    func testStartRegex(){
        let passing = ["/"
        ]
        let failing = ["/*",
                       ]
        XCTAssertNoThrow(try checkSimplePassFail(for: .startRegex, passing: passing, failing: failing, expectNode: false))
    }
    
    func testEndRegex(){
        let passing = ["/"
        ]
        let failing = [String]()
        XCTAssertNoThrow(try checkSimplePassFail(for: .endRegex, passing: passing, failing: failing, expectNode: false))
    }

    func testRegexBody(){
        let passing = ["[:space]",
                       "\\\""
        ]
        let failing = ["/"]
        XCTAssertNoThrow(try checkSimplePassFail(for: .regexBody, passing: passing, failing: failing, expectNode: false))
    }

    func testRegex(){
        let passing = ["something",
                       ".*"
        ]
        let failing = ["//"]
        
        XCTAssertNoThrow(try checkSimplePassFail(for: .regex, passing: passing.map({"/\($0)/ "}), failing: failing, expectNode: true, matches: passing))
    }
    
    func testTerminal(){
        XCTFail("This test in hanging")
        return
        let passing = [
            "\"something\"",
            ".letter",
            "/regex/",
            "\"a\"...\"b\"",
        ]
        let failing = [""]
        
        XCTAssertNoThrow(try checkSimplePassFail(for: .terminal, passing: passing, failing: failing, expectNode: true))
        #warning("Check strucure and errors")
    }
    
    func testAnnotation(){
        let passing = ["@void","@wibble(3)","@token(\"4\")"]
        XCTAssertNoThrow(try checkSimplePassFail(for: .annotation, passing: passing, failing: ["@","@3","@something(","@something(2"], expectNode: true))
        #warning("Should check for the correct errors")
        #warning("Should check for correct ast structure too")
    }
    
    func testAnnotations(){
        let passing = ["@void",
                       "@void @token(\"something\")",
                       "@void @transient @pin"
            ]
        let failing = ["void",
                       "token something",
        ]
        XCTAssertNoThrow(try checkSimplePassFail(for: .annotations, passing: passing, failing: failing, expectNode: true))
        #warning("Should check for the correct errors")
        #warning("Should check for correct ast structure too")
    }
    
    func testGroup(){
        let passing = [
            "(a)",
            "(a b c)",
            "(a | b | c)",
            ]
        let failing = [""]
        
        XCTAssertNoThrow(try checkSimplePassFail(for: .group, passing: passing, failing: failing, expectNode: true))
        #warning("Check strucure and errors")
    }
    
    func testIdentifier(){
        let passing = [
            "abc",
            "_abc",
            "_ABC",
            "ABc_d",
            ]
        let failing = ["2a"]
        
        XCTAssertNoThrow(try checkSimplePassFail(for: .identifier, passing: passing, failing: failing, expectNode: true))
        #warning("Check strucure and errors")
    }

    func testElement(){
        let passing = [
            "@void !abc+",
            "@void ~abc*",
            "@void >>abc?",
            "@void -abc?",
            "@void !(abc)+",
            "@void ~(abc)*",
            "@void >>(abc)?",
            "@void -(abc)?",
            "@void !\"abc\"+",
            "@void ~\"abc\"*",
            "@void >>\"abc\"?",
            "@void -\"abc\"?",
            ]
        let failing = ["2a"]
        
        XCTAssertNoThrow(try checkSimplePassFail(for: .element, passing: passing, failing: failing, expectNode: true))
        #warning("Check strucure and errors")
    }
    
    func testAssignmentOperators(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .assignmentOperators, passing: ["=","+=","|="], failing: [""], expectNode: true))
    }

    func testOr(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .or, passing: ["|"," |","| "," | ","  |    "], failing: [""], expectNode: false))
    }

    func testThen(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .then, passing: ["+"," +","+ "," + ","  +    "], failing: [""], expectNode: false))
    }

    func testChoice(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .choice, passing: ["a | b","a|b | c","a | b  //Comment\n|c"], failing: [""], expectNode: true))
        #warning("Test structure")
    }

    func testSequence(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .sequence, passing: ["a  b","a b   c","a   b\nc //Comment"], failing: [""], expectNode: true))
        #warning("Test structure")
    }
    
    func testNotNewRule(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .notNewRule, passing: ["a : something"], failing: ["a = b"], expectNode: true))
    }
    
    func testExpression(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .expression, passing: ["a","a | b","a b"], failing: [""], expectNode: true))
        #warning("Test structure")
    }
    
    func testStandardType(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .standardType, passing: ["Bool","Int","String","Double"], failing: [""], expectNode: true))
    }

    func testCustomType(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .customType, passing: ["Mine","_mine","Min_","Min3"], failing: ["3","min"], expectNode: true))
    }

    func testTokenType(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .tokenType, passing: ["Bool","Mine"], failing: ["bool","mine"], expectNode: true))
        #warning("Test structure")
    }

    func testLHS(){
        let passing = [
            "abc =",
            "@void abc =",
            "@pin ~abc=",
            "@pin ~abc:Double=",
            ]
        let failing = [""]
        
        XCTAssertNoThrow(try checkSimplePassFail(for: .lhs, passing: passing, failing: failing, expectNode: true))
        #warning("Check strucure and errors")
    }

    func testRule(){
        let passing = [
            "abc = a",
            "abc = a //Comment on the end",
            ]
        let failing = [""]
        
        XCTAssertNoThrow(try checkSimplePassFail(for: .rule, passing: passing, failing: failing, expectNode: true))
        #warning("Check strucure and errors")
    }
    
    func testModuleName(){
        let passing = [
            "abc",
            "_abC",
            "ab_C2",
            ]
        let failing = [""]
        
        XCTAssertNoThrow(try checkSimplePassFail(for: .moduleName, passing: passing, failing: failing, expectNode: false))
        #warning("Check strucure and errors")
    }

    func testModuleImport(){
        let passing = [
            "abc",
            ]
        let failing = [""]
        
        XCTAssertNoThrow(try checkSimplePassFail(for: .moduleImport, passing: passing.map({"import \($0)\n"}), failing: failing, expectNode: true, matches:passing))
        #warning("Check strucure and errors")
    }
    
    func testModules(){
        let passing = [
            """
            import module

            """,
            """
            import module1
            import module2
            import module3

            """,
            ]
        let failing = [""]
        
        XCTAssertNoThrow(try checkSimplePassFail(for: .modules, passing: passing, failing: failing, expectNode: true))
        #warning("Check strucure and errors")
    }
    
    func testRules(){
        let passing = [
            """
            a = b
            """,
            """
            a = b
            c = d | b
            d = e f g
            """,
            ]
        let failing = [""]
        
        XCTAssertNoThrow(try checkSimplePassFail(for: .rules, passing: passing, failing: failing, expectNode: true))
        #warning("Check strucure and errors")
    }
    
    func testGrammar(){
        let passing = [
            """
            /// Grammar
            grammar Test

            import = "import"
            """,
            """
            /// Grammar
            grammar Test

            import Module

            import = "import"
            """,
            ]
        let failing = [""]
        
        XCTAssertNoThrow(try checkSimplePassFail(for: .grammar, passing: passing, failing: failing, expectNode: true))
        #warning("Check strucure and errors")
    }
    
    func testGrammarDeclarationRule(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .scopeName, passing: ["grammar wibble\n"], failing: [""], expectNode: true, matches:["wibble"]))
    }

    
    func testGeneratedIR() {
        do {
            let rules = try STLR.build("grammar Test\nhello = .letter").grammar.rules
            
            guard rules.count == 1 else {
                XCTFail("Expected 1 rule")
                return
            }

            let helloRule = rules[0]
            
            if case let .element(element) = helloRule.expression {
                
                if case .characterSet(let characterSet) = element.terminal ?? STLR.Terminal.regex(regex: "") {
                    XCTAssertEqual(STLR.CharacterSetName.letter, characterSet.characterSetName)
                } else {
                    XCTAssertNotNil("Expected a character set terminal")
                }
            } else {
                XCTFail("Expected the hello rule to create an element expression")
            }
            
        } catch {
            XCTFail("Failed: \(error)")
        }
    }

}
