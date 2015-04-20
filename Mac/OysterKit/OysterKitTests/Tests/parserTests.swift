//
//  parserTests.swift
//  OysterKit Mac
//
//  Created by Nigel Hughes on 10/07/2014.
//  Copyright (c) 2014 RED When Excited Limited. All rights reserved.
//

import OysterKit
import XCTest

class parserTests: XCTestCase {
    var parser = OKScriptParser()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        parser = OKScriptParser()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func niceParserErrors(theParser:OKScriptParser)->String{
        var parserErrors = ""
        
        for error in theParser.errors {
            parserErrors+="\t\(error)\n"
        }
        
        return parserErrors
    }
    
    func parserTest(#script:String, thenTokenizing tokenize:String)->[Token]{
        var tokenizer = parser.parse(script)
        
        var parserErrors = ""
        for error in parser.errors {
            parserErrors+="\t\(error)\n"
        }
        
        if __debugScanning {
            println(tokenizer.description)
        }
        
        XCTAssert(count(parserErrors)==0, "\n\nParsing of \(script) failed with errors:\n\(parserErrors) after creating \n\(tokenizer) from token stream \(OKScriptTokenizer().tokenize(script))")
        
        return tokenizer.tokenize(tokenize)
    }

    func xxxxGenericParserTest(){
        let testScript = "\n" +
                         "\n"
        
        let testString = ""
        
        let tokens = parserTest(script: testScript, thenTokenizing: testString)
        
    }
    
    func testParseNamedStates(){
        let testString = "@oct = \"01234567\"->oct begin{ @oct }"
        
        var tokenizer = OKStandard.parseTokenizer(testString)!
        
        let octTest = "346738"
        
        let tokens = tokenizer.tokenize(octTest)
        
        XCTAssert(tokenizer.tokenize(octTest) == [token("oct",chars:"3"), token("oct",chars:"4"), token("oct",chars:"6"), token("oct",chars:"7"), token("oct",chars:"3"), ])
    }

    func testHexScriptWithNamedStates(){
        let testScript = "@hexPrefix = \"0\".\"x\"\n@hexDigits=*\"0123456789abcdefABCDEF\"\nbegin\n{@hexPrefix.@hexDigits->hexNumber}"
        
        let testData = [
            "0xAbcD93343" : 1
        ]
        
        for (testString,expectedTokens) in testData{
            let tokens = parserTest(script: testScript, thenTokenizing: testString)
            XCTAssert(tokens.count == expectedTokens,"Expected \(expectedTokens) tokens, but got \(tokens.count) from \(testString)")
        }
    }
    
    
    func testHexScript(){
        let testScript = "{\"0\".\"x\".*\"0123456789abcdefABCDEF\"->hexNumber}"
        
        let testData = [
                    "0xAbcD93343" : 1
                    ]

        for (testString,expectedTokens) in testData{
            let tokens = parserTest(script: testScript, thenTokenizing: testString)
            XCTAssert(tokens.count == expectedTokens,"Expected \(expectedTokens) tokens, but got \(tokens.count) from \(testString)")
        }
    }
    
    func testUnicode(){
        var testString = "{!\"\\x04\"->anything}"
        
        var tokenizer = OKStandard.parseTokenizer(testString)!
        
        
        assertTokenListsEqual(tokenizer.tokenize("823947283479238428348734"), reference: [token("anything",chars:"8"), token("anything",chars:"2"), token("anything",chars:"3"), token("anything",chars:"9"), token("anything",chars:"4"), token("anything",chars:"7"), token("anything",chars:"2"), token("anything",chars:"8"), token("anything",chars:"3"), token("anything",chars:"4"), token("anything",chars:"7"), token("anything",chars:"9"), token("anything",chars:"2"), token("anything",chars:"3"), token("anything",chars:"8"), token("anything",chars:"4"), token("anything",chars:"2"), token("anything",chars:"8"), token("anything",chars:"3"), token("anything",chars:"4"), token("anything",chars:"8"), token("anything",chars:"7"), token("anything",chars:"3"), token("anything",chars:"4"), ])
        
    }
    
    func testParseGeneratedOKScriptDefinition(){
        //Then create a definition for it from itself
        let tokFileTokDef = OKScriptTokenizer().description
        
        //Tokenizer my own serialized description
        let selfGeneratedTokens = OKScriptTokenizer().tokenize(tokFileTokDef)
        
        //Create a tokenizer from the generated description
        let generatedTokenizer = parser.parse(tokFileTokDef)
        var parserErrors = ""
        for error in parser.errors {
            parserErrors+="\t\(error)\n"
        }
        
        XCTAssert(count(parserErrors) == 0, "Self parsing generated an error:\n\(parserErrors) with \n\(tokFileTokDef)\n")

        //Tokenize original serialized description with the parsed tokenizer built from my own serialized description
        let parserGeneratedTokens = generatedTokenizer.tokenize(tokFileTokDef)

        //Do we get the same results?
        assertTokenListsEqual(parserGeneratedTokens, reference: selfGeneratedTokens)
    }

}
