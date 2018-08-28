//
//  FullSwiftGenerationTest.swift
//  OysterKitTests
//
//  Created on 15/07/2018.
//

import XCTest
@testable import OysterKit
import STLR
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
        return
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
    }
    
    func parse(source:String, with token:STLRTokens, ignoreNoNodes:Bool = true, appendMopUpRule mopup:Rule? = nil) throws {
        FullSwiftGenerationTest.testedTokens.insert(token)
        
        let rule : Rule
        if let mopup = mopup {
            rule = [token.rule,mopup].sequence
        } else {
            rule = token.rule
        }
        
        do {
            try parse(source: source, with: rule)
        } catch AbstractSyntaxTreeConstructor.ConstructionError.constructionFailed(let causes){
            if let primaryCause = causes.first {
                if "\(primaryCause)".hasPrefix("No nodes created") && ignoreNoNodes {
                    return
                }
            }
            throw TestError.parsingError(message: "Unexpected construction error", range: source.startIndex...source.endIndex, causes: causes)
        }
    }
    
    func checkSimplePassFail(for token:STLRTokens, passing:[String], failing:[String], expectNode:Bool, matches:[String] = [], appendMopUpRule mopup:Rule? = nil) throws {
        var count = 0
        for source in passing {
            try parse(source: source, with: token, ignoreNoNodes: !expectNode, appendMopUpRule: mopup)
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
        if let rule = STLRTokens.ows.rule as? ReferenceRule {
            if case Behaviour.Kind.skipping = rule.references.behaviour.kind {
            } else {
                XCTFail("ows should be skipping")
            }
        } else {
            XCTFail("Unable to check if ows is skipping")
        }
        
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

    func makeAST(for token:STLRTokens, from source:String, appendMopupRule mopup:Rule? = nil) throws -> HomogenousTree {
        var grammar = [token.rule]
        if let mopup = mopup {
            grammar = [[token.rule, -mopup].sequence]
        }
        return try AbstractSyntaxTreeConstructor(with: source).build(using: Parser(grammar: grammar))
    }
    
    func testQuantifier(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .quantifier, passing: ["*","?","+"], failing: ["&"], expectNode: true))
        
        do {
            let ast = try makeAST(for: .quantifier, from: "*")
            XCTAssertEqual(0, ast.children.count)
            XCTAssertEqual(STLRTokens.quantifier, ast.token as! STLRTokens)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testNegated(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .negated, passing: ["!"], failing: ["&"], expectNode: true))
        do {
            let token : STLRTokens = .negated
            let ast = try makeAST(for: token, from: "!")
            XCTAssertEqual(0, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testLookahead(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .lookahead, passing: [">>"], failing: [">&"], expectNode: true))
        do {
            let token : STLRTokens = .lookahead
            let ast = try makeAST(for: token, from: ">>")
            XCTAssertEqual(0, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
        } catch {
            XCTFail("\(error)")
        }    }

    func testTransient(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .transient, passing: ["~"], failing: ["-","&"], expectNode: true))
        do {
            let token = STLRTokens.transient
            let ast = try makeAST(for: token, from: "~")
            XCTAssertEqual(0, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testVoid(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .void, passing: ["-"], failing: ["~","&"], expectNode: true))
        do {
            let token = STLRTokens.void
            let ast = try makeAST(for: token, from: "-")
            XCTAssertEqual(0, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testStringQuote(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .stringQuote, passing: ["\""], failing: ["'","\\\""], expectNode: true))
        do {
            let token = STLRTokens.stringQuote
            let ast = try makeAST(for: token, from: "\"")
            XCTAssertEqual(0, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
        } catch {
            XCTFail("\(error)")
        }    }
    
    func testTerminalBody(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .terminalBody, passing: ["lkjdslkf","\\\"escape quote should be ok"], failing: ["ddd","\""], expectNode: true))
        do {
            let token = STLRTokens.terminalBody
            let source = "Terminal"
            let ast = try makeAST(for: token, from: source)
            XCTAssertEqual(0, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
            XCTAssertEqual(source, ast.matchedString)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testStringBody(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .stringBody, passing: ["lkjdslkf","\\\"escape quote should be ok"], failing: ["ddd","\""], expectNode: true))
        do {
            let token = STLRTokens.stringBody
            let source = "String"
            let ast = try makeAST(for: token, from: source)
            XCTAssertEqual(0, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
            XCTAssertEqual(source, ast.matchedString)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testString(){
        let matches = [
            "ldkfjkldsjf",
            "lsdkfj\\\"lkdsjf",
            "\\\"",
            ""
        ]
        XCTAssertNoThrow(try checkSimplePassFail(for: .string, passing: matches.map({"\"\($0)\""}), failing: ["\"ddd","\"kdlsfj\n","dsfdsf"], expectNode: true, matches: matches))
        do {
            let token = STLRTokens.string
            let source = "\"String\""
            let ast = try makeAST(for: token, from: source)
            XCTAssertEqual(1, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
            if let body = ast.children.first, ast.children.count == 1 {
                XCTAssertEqual(.stringBody, body.token as! STLRTokens)
                XCTAssertEqual(String(source.dropLast().dropFirst()), body.matchedString)
            } else {
                XCTFail("Expected exactly one child of type stringBody")
            }
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testTerminalString(){
        let matches = [
            "ldkfjkldsjf",
            "A",
            "\\\""
        ]
        XCTAssertNoThrow(try checkSimplePassFail(for: .terminalString, passing: matches.map({"\"\($0)\""}), failing: ["\"ddd","\"kdlsfj\n","dsfdsf","\"\""], expectNode: true, matches: matches))
        do {
            let token = STLRTokens.terminalString
            let source = "\"String\""
            let ast = try makeAST(for: token, from: source)
            XCTAssertEqual(1, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
            if let body = ast.children.first, ast.children.count == 1 {
                XCTAssertEqual(.terminalBody, body.token as! STLRTokens)
                XCTAssertEqual(String(source.dropLast().dropFirst()), body.matchedString)
            } else {
                XCTFail("Expected exactly one child of type stringBody")
            }
        } catch {
            XCTFail("\(error)")
        }
        
    }

    fileprivate let characterSetNames = ["letter","uppercaseLetter","lowercaseLetter","alphaNumeric","decimalDigit","whitespaceOrNewline","whitespace","newline","backslash"]
    
    func testCharacterSetName(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .characterSetName, passing: characterSetNames, failing: ["sdfsdf",".anything"], expectNode: false))
        XCTAssertEqual(STLR.CharacterSetName.allCases.map({"\($0)"}), characterSetNames,"Test is not exhaustive not all character set names are covered")
        do {
            let token = STLRTokens.characterSetName
            let ast = try makeAST(for: token, from: "letter")
            XCTAssertEqual(0, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
        } catch {
            XCTFail("\(error)")
        }

    }
    
    func testCharacterSet(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .characterSet, passing: characterSetNames.map({".\($0)"}), failing: [".",".anything"], expectNode: true, matches: characterSetNames))
        
        do {
            let token = STLRTokens.characterSet
            let ast = try makeAST(for: token, from: ".letter")
            XCTAssertEqual("letter", ast.matchedString)
            XCTAssertEqual(token, ast.token as! STLRTokens)
            XCTAssertEqual(1, ast.children.count)
            if let child = ast.children.first {
                XCTAssertEqual(.characterSetName, child.token as! STLRTokens)
                XCTAssertEqual("letter", child.matchedString)
            }
        } catch {
            XCTFail("\(error)")
        }
        #warning("Should check for the correct error here")
    }

    
    func testRangeOperator(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .rangeOperator, passing: ["..."], failing: [".","..","..<"], expectNode: false))
        do {
            let token = STLRTokens.rangeOperator
            _ = try makeAST(for: token, from: "...")
            XCTFail("No tokens should be created for the range operator")
        } catch {
            /// It should fail
        }
        #warning("Should check for the correct error here")
    }
    
    func testCharacterRange(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .characterRange, passing: ["\"a\"...\"b\""], failing: ["\"\"...\"b\"","\"a\"..","\"a\"...\"\",\"a\"..<\"b\""], expectNode: false))
        
        do {
            let token = STLRTokens.characterRange
            let ast = try makeAST(for: token, from: "\"a\"...\"b\"")
            XCTAssertEqual(token, ast.token as! STLRTokens)
            XCTAssertEqual(2, ast.children.count)
            var childMatches = ["a","b"]
            for child in ast.children {
                XCTAssertEqual(.terminalString, child.token as! STLRTokens)
                XCTAssertEqual(childMatches.removeFirst(), child.matchedString)
            }
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testNumber(){
        let passing = ["1","+1","-1","+1000","-1000","1000"]
        XCTAssertNoThrow(try checkSimplePassFail(for: .number, passing: passing, failing: ["a",".","+10.0"], expectNode: true, matches: passing))

        do {
            let token = STLRTokens.number
            let ast = try makeAST(for: token, from: "+1")
            XCTAssertEqual(0, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testBoolean(){
        let passing = ["true","false"]
        XCTAssertNoThrow(try checkSimplePassFail(for: .boolean, passing: passing, failing: ["trut","fal"], expectNode: true, matches: passing))

        do {
            let token = STLRTokens.boolean
            let ast = try makeAST(for: token, from: "true")
            XCTAssertEqual(0, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
        } catch {
            XCTFail("\(error)")
        }

    }

    func testLiteral(){
        let passing = ["true","1","\"string\""]
        let matches = [passing[0],passing[1],"string"]
        XCTAssertNoThrow(try checkSimplePassFail(for: .literal, passing: passing, failing: ["trut"], expectNode: true, matches: matches))

        do {
            let token = STLRTokens.literal
            let ast = try makeAST(for: token, from: "true1\"string\"")
            XCTAssertEqual(3, ast.children.count)
            var childMatches = [STLRTokens.boolean,STLRTokens.number, STLRTokens.string]
            for child in ast.children {
                XCTAssertEqual(token, child.token as! STLRTokens)
                for specificType in child.children{
                    XCTAssertEqual(childMatches.removeFirst(), specificType.token as! STLRTokens)
                }
            }
        } catch {
            XCTFail("\(error)")
        }
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
        do {
            let token = STLRTokens.definedLabel
            let ast = try makeAST(for: token, from: "error")
            XCTAssertEqual(0, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
            XCTAssertEqual("error", ast.matchedString)
        } catch {
            XCTFail("\(error)")
        }
    }

    
    func testCustomLabel(){
        let passing = ["_a",
                       "customLabel",
        ]
        let failing = ["_",
                       "3something",
                       ]
        XCTAssertNoThrow(try checkSimplePassFail(for: .customLabel, passing: passing, failing: failing, expectNode: true))
        do {
            let token = STLRTokens.customLabel
            let ast = try makeAST(for: token, from: "customLabel")
            XCTAssertEqual(0, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
            XCTAssertEqual("customLabel", ast.matchedString)
        } catch {
            XCTFail("\(error)")
        }
        #warning("Check for the correct error here")
    }

    func testLabel(){
        let passing = ["void",
                       "customLabel",
                       "_customLabel",
                       ]
        let failing = [String]()
        XCTAssertNoThrow(try checkSimplePassFail(for: .label, passing: passing, failing: failing, expectNode: true, matches:passing))

        do {
            let token = STLRTokens.label
            let ast = try makeAST(for: token, from: "error_MyLabel")
            var childMatches = [STLRTokens.definedLabel,STLRTokens.customLabel]
            XCTAssertEqual(childMatches.count, ast.children.count)
            for child in ast.children {
                XCTAssertEqual(token, child.token as! STLRTokens)
                for specificType in child.children{
                    XCTAssertEqual(childMatches.removeFirst(), specificType.token as! STLRTokens)
                }
            }
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testRegexDelimeter(){
        let passing = ["/"
                       ]
        let failing = ["\\",
                       "d",
                       ]
        XCTAssertNoThrow(try checkSimplePassFail(for: .regexDelimeter, passing: passing, failing: failing, expectNode: false))
        do {
            let token = STLRTokens.regexDelimeter
            _ = try makeAST(for: token, from: "/")
            XCTFail("Should have thrown no nodes")
        } catch {
        }
    }

    func testStartRegex(){
        let passing = ["/"
        ]
        let failing = ["/*",
                       ]
        XCTAssertNoThrow(try checkSimplePassFail(for: .startRegex, passing: passing, failing: failing, expectNode: false))
        do {
            let token = STLRTokens.startRegex
            _ = try makeAST(for: token, from: "/")
            XCTFail("Should have thrown no nodes")
        } catch {
        }
    }
    
    func testEndRegex(){
        let passing = ["/"
        ]
        let failing = [String]()
        XCTAssertNoThrow(try checkSimplePassFail(for: .endRegex, passing: passing, failing: failing, expectNode: false))
        do {
            let token = STLRTokens.endRegex
            _ = try makeAST(for: token, from: "/")
            XCTFail("Should have thrown no nodes")
        } catch {
        }
    }

    func testRegexBody(){
        let passing = ["[:space]",
                       "\\\""
        ]
        let failing = ["/"]
        XCTAssertNoThrow(try checkSimplePassFail(for: .regexBody, passing: passing, failing: failing, expectNode: false))
        do {
            let token = STLRTokens.endRegex
            _ = try makeAST(for: token, from: "/")
            XCTFail("Should have thrown no nodes")
        } catch {
        }
    }

    func testRegex(){
        let passing = ["something",
                       ".*"
        ]
        let failing = ["//"]
        
        XCTAssertNoThrow(try checkSimplePassFail(for: .regex, passing: passing.map({"/\($0)/ "}), failing: failing, expectNode: true, matches: passing,appendMopUpRule: " "))
        do {
            let token = STLRTokens.regex
            let ast = try makeAST(for: token, from: "/.*/ ",appendMopupRule: " ")
            XCTAssertEqual(0, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
            XCTAssertEqual(".*", ast.matchedString)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testTerminal(){
        let passing = [
            "\"something\"",
            ".letter",
            "\"a\"...\"b\"",
        ]
        let failing = [""]
        
        XCTAssertNoThrow(try checkSimplePassFail(for: .terminal, passing: passing, failing: failing, expectNode: true))

        XCTAssertNoThrow(try checkSimplePassFail(for: .terminal, passing: ["/regex/ "], failing: failing, expectNode: true, appendMopUpRule:" "))
        
        do {
            let token = STLRTokens.terminal
            let ast = try makeAST(for: token, from: ".letter\"something\"\"a\"...\"b\"")
            var childMatches = [STLRTokens.characterSet,STLRTokens.terminalString,STLRTokens.characterRange]
            XCTAssertEqual(childMatches.count, ast.children.count)
            for child in ast.children {
                XCTAssertEqual(token, child.token as! STLRTokens)
                for specificType in child.children{
                    XCTAssertEqual(childMatches.removeFirst(), specificType.token as! STLRTokens)
                }
            }
        } catch {
            XCTFail("\(error)")
        }

    }
    
    func testAnnotation(){
        let passing = ["@void","@wibble(3)","@token(\"4\")"]
        XCTAssertNoThrow(try checkSimplePassFail(for: .annotation, passing: passing, failing: ["@","@3","@something(","@something(2"], expectNode: true))
        do {
            let token = STLRTokens.annotation
            let ast = try makeAST(for: token, from: "@void(3)")
            var childMatches = [STLRTokens.label,STLRTokens.literal]
            XCTAssertEqual(childMatches.count, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)

            for child in ast.children {
                XCTAssertEqual(childMatches.removeFirst(), child.token as! STLRTokens)
            }
        } catch {
            XCTFail("\(error)")
        }
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
        do {
            let token = STLRTokens.annotations
            let ast = try makeAST(for: token, from: "@void @transient @color(\"#FF00FF\")")

            var childMatches = [STLRTokens.annotation,STLRTokens.annotation, STLRTokens.annotation]
            XCTAssertEqual(childMatches.count, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
            
            for child in ast.children {
                XCTAssertEqual(childMatches.removeFirst(), child.token as! STLRTokens)
            }
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testGroup(){
        let passing = [
            "(a)",
            "(a b c)",
            "(a | b | c)",
            ]
        let failing = [""]
        
        XCTAssertNoThrow(try checkSimplePassFail(for: .group, passing: passing, failing: failing, expectNode: true))
        do {
            let token = STLRTokens.group
            let ast = try makeAST(for: token, from: "(a | b | c)")
            print(ast.description)
            var childMatches = [STLRTokens.expression]
            XCTAssertEqual(childMatches.count, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
            
            for child in ast.children {
                XCTAssertEqual(childMatches.removeFirst(), child.token as! STLRTokens)
            }
        } catch {
            XCTFail("\(error)")
        }
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
        
        do {
            let token = STLRTokens.identifier
            let ast = try makeAST(for: token, from: "abc")

            XCTAssertEqual(0, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
        } catch {
            XCTFail("\(error)")
        }
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
        do {
            let token = STLRTokens.element
            let ast = try makeAST(for: token, from: "@void >>!.letter+")
            
            var childMatches = [STLRTokens.annotations, STLRTokens.lookahead, STLRTokens.negated, STLRTokens.terminal, STLRTokens.quantifier]
            XCTAssertEqual(childMatches.count, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
            
            for child in ast.children {
                XCTAssertEqual(childMatches.removeFirst(), child.token as! STLRTokens)
            }
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testAssignmentOperators(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .assignmentOperators, passing: ["=","+=","|="], failing: [""], expectNode: true))
        do {
            let token = STLRTokens.assignmentOperators
            let ast = try makeAST(for: token, from: "+=")
            
            XCTAssertEqual(0, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testOr(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .or, passing: ["|"," |","| "," | ","  |    "], failing: [""], expectNode: false))
        do {
            let token = STLRTokens.or
            _ = try makeAST(for: token, from: "|")
            XCTFail("Should have thrown no nodes")
        } catch {
        }
    }

    func testThen(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .then, passing: ["+"," +","+ "," + ","  +    "], failing: [""], expectNode: false))
        do {
            let token = STLRTokens.then
            _ = try makeAST(for: token, from: "|")
            XCTFail("Should have thrown no nodes")
        } catch {
        }
    }

    func testChoice(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .choice, passing: ["a | b","a|b | c","a | b  //Comment\n|c"], failing: [""], expectNode: true))
        do {
            let token = STLRTokens.choice
            let ast = try makeAST(for: token, from: "a | b |c")
            
            var childMatches = [STLRTokens.element, STLRTokens.element, STLRTokens.element]
            XCTAssertEqual(childMatches.count, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
            
            for child in ast.children {
                XCTAssertEqual(childMatches.removeFirst(), child.token as! STLRTokens)
            }
        } catch {
            XCTFail("\(error)")
        }
    }

    func testSequence(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .sequence, passing: ["a  b","a b   c","a   b\nc //Comment"], failing: [""], expectNode: true))
        do {
            let token = STLRTokens.sequence
            let ast = try makeAST(for: token, from: "a  b c")
            
            var childMatches = [STLRTokens.element, STLRTokens.element, STLRTokens.element]
            XCTAssertEqual(childMatches.count, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
            
            for child in ast.children {
                XCTAssertEqual(childMatches.removeFirst(), child.token as! STLRTokens)
            }
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testNotNewRule(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .notNewRule, passing: ["a : something"], failing: ["a = b"], expectNode: false))
        do {
            let token = STLRTokens.notNewRule
            _ = try makeAST(for: token, from: "a : something")
            XCTFail("Should have thrown no nodes")
        } catch {
        }
    }
    
    func testExpression(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .expression, passing: ["a","a | b","a b"], failing: [""], expectNode: true))
        do {
            let token = STLRTokens.expression
            let ast = try makeAST(for: token, from: "a  b c")
            
            var childMatches = [STLRTokens.sequence]
            XCTAssertEqual(childMatches.count, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
            
            for child in ast.children {
                XCTAssertEqual(childMatches.removeFirst(), child.token as! STLRTokens)
            }
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testStandardType(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .standardType, passing: ["Bool","Int","String","Double"], failing: [""], expectNode: true))
        do {
            let token = STLRTokens.standardType
            let ast = try makeAST(for: token, from: "Bool")
            
            XCTAssertEqual(0, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testCustomType(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .customType, passing: ["Mine","_mine","Min_","Min3"], failing: ["3","min"], expectNode: true))
        do {
            let token = STLRTokens.customType
            let ast = try makeAST(for: token, from: "Mine")
            
            XCTAssertEqual(0, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testTokenType(){
        XCTAssertNoThrow(try checkSimplePassFail(for: .tokenType, passing: ["Bool","Mine"], failing: ["bool","mine"], expectNode: true))
        do {
            let token = STLRTokens.tokenType
            let ast = try makeAST(for: token, from: "BoolMine")
            var childMatches = [STLRTokens.standardType,STLRTokens.customType]
            XCTAssertEqual(childMatches.count, ast.children.count)
            for child in ast.children {
                XCTAssertEqual(token, child.token as! STLRTokens)
                for specificType in child.children{
                    XCTAssertEqual(childMatches.removeFirst(), specificType.token as! STLRTokens)
                }
            }
        } catch {
            XCTFail("\(error)")
        }
    }

    func testLHS(){
        let passing = [
            "abc =",
            "@void abc =",
            "@pin ~abc=",
            "@pin ~abc:Double=",
            ]
        let failing = [""]
        
        XCTAssertNoThrow(try checkSimplePassFail(for: .lhs, passing: passing, failing: failing, expectNode: false))
        do {
            let token = STLRTokens.lhs
            let ast = try makeAST(for: token, from: "@pin ~abc:Double=")
            
            var childMatches = [STLRTokens.annotations,.transient,.identifier,.tokenType,.assignmentOperators]
            XCTAssertEqual(childMatches.count, ast.children.count)
            
            for child in ast.children {
                XCTAssertEqual(childMatches.removeFirst(), child.token as! STLRTokens)
            }
        } catch {
            XCTFail("\(error)")
        }
    }

    func testRule(){
        let passing = [
            "abc = a",
            "abc = a //Comment on the end",
            ]
        let failing = [""]
        
        XCTAssertNoThrow(try checkSimplePassFail(for: .rule, passing: passing, failing: failing, expectNode: true))
        do {
            let token = STLRTokens.rule
            let ast = try makeAST(for: token, from: "@pin ~abc:Double=x")
            
            var childMatches = [STLRTokens.annotations,.transient,.identifier,.tokenType,.assignmentOperators,.expression]
            XCTAssertEqual(childMatches.count, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
            
            for child in ast.children {
                XCTAssertEqual(childMatches.removeFirst(), child.token as! STLRTokens)
            }
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testModuleName(){
        let passing = [
            "abc",
            "_abC",
            "ab_C2",
            ]
        let failing = [""]
        
        XCTAssertNoThrow(try checkSimplePassFail(for: .moduleName, passing: passing, failing: failing, expectNode: false))
    }

    func testModuleImport(){
        let passing = [
            "abc",
            ]
        let failing = [""]
        
        XCTAssertNoThrow(try checkSimplePassFail(for: .moduleImport, passing: passing.map({"import \($0)\n"}), failing: failing, expectNode: true, matches:passing))
        
        do {
            let token = STLRTokens.moduleImport
            let ast = try makeAST(for: token, from: "import abc\n")
            
            var childMatches = [STLRTokens.moduleName]
            XCTAssertEqual(childMatches.count, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
            
            for child in ast.children {
                XCTAssertEqual(childMatches.removeFirst(), child.token as! STLRTokens)
            }
        } catch {
            XCTFail("\(error)")
        }
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
        do {
            let token = STLRTokens.modules
            let ast = try makeAST(for: token, from: passing[1])
            
            var childMatches = [STLRTokens.moduleImport, .moduleImport, .moduleImport]
            XCTAssertEqual(childMatches.count, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
            
            for child in ast.children {
                XCTAssertEqual(childMatches.removeFirst(), child.token as! STLRTokens)
            }
        } catch {
            XCTFail("\(error)")
        }
        
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
        do {
            let token = STLRTokens.rules
            let ast = try makeAST(for: token, from: passing[1])
            
            var childMatches = [STLRTokens.rule, .rule, .rule]
            XCTAssertEqual(childMatches.count, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
            
            for child in ast.children {
                XCTAssertEqual(childMatches.removeFirst(), child.token as! STLRTokens)
            }
        } catch {
            XCTFail("\(error)")
        }
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
        do {
            let token = STLRTokens.grammar
            let ast = try makeAST(for: token, from: passing[1])
            
            var childMatches = [STLRTokens.scopeName, .modules, .rules]
            XCTAssertEqual(childMatches.count, ast.children.count)
            XCTAssertEqual(token, ast.token as! STLRTokens)
            
            for child in ast.children {
                XCTAssertEqual(childMatches.removeFirst(), child.token as! STLRTokens)
            }
        } catch {
            XCTFail("\(error)")
        }
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
