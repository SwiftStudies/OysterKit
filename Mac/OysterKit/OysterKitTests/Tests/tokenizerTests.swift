//
//  tokenizerTests.swift
//  OysterKit Mac
//
//  Created by Nigel Hughes on 03/07/2014.
//  Copyright (c) 2014 RED When Excited Limited. All rights reserved.
//

import XCTest
import OysterKit

class tokenizerTests: XCTestCase {
    var tokenizer = Tokenizer()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        tokenizer = Tokenizer()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testRegexCharacter(){        
        let escapedControlCodes = "\\vrnt"
        let escapedAnchorCharacters = "AzZbB"
        let escapedRegexSyntax = "[]()|?.*+{}"
        let escapedCharacterClasses = "sSdDwW"

        let singleAnchors = Branch().branch(
            Characters(from:"^").token("character"),
            Characters(from:"$").token("character")
        )
        
        let escapedAnchors = Characters(from:"\\").branch(
            Characters(from:escapedControlCodes+escapedAnchorCharacters+escapedRegexSyntax+escapedCharacterClasses).token("character"),
            Characters(from:"x").branch(
                Repeat(state: OKStandard.hexDigit, min:2,max:2).token("character"),
                Characters(from: "{").sequence(
                    Repeat(state: OKStandard.hexDigit, min: 4, max: 4),
                    Characters(from: "}").token("character")
                )
            )
        )
        
        tokenizer.branch(
            OKStandard.eot,
            singleAnchors,
            escapedAnchors
        )
        
        let regexTest = "$^\\b\\B\\A\\z\\Z\\t\\n\\r\\\\\\[\\s\\x0a\\x{acd3}$^$"
        
        XCTAssert(tokenizer.tokenize(regexTest).count == 18)
    }
    
    func testTokenizerFileChar(){
        let tokenizer = OKScriptParser().parse("{\"0123456789\"->digit}")
        
        var tokens = tokenizer.tokenize("0123456789")
        
        XCTAssert(tokens.count == 10)
        
        tokens = tokenizer.tokenize("324")
        
        XCTAssert(tokens.count == 3)
        
        tokens = tokenizer.tokenize("343A")
        
        XCTAssert(tokens.count == 3)
    }
    
    func testTokenizerFileBranch(){
        let tokenizer = OKScriptParser().parse("{\"0123456789\"->digit,\"ABCDEFGHIJKLMNOPQRSTUVWXYZ\"->capital}")
        
        let tokens = tokenizer.tokenize("123ABC")
        
        XCTAssert(tokens.count == 6)
    }
    
    func testTokenizerFileRepeat(){
        var tokenizer = OKScriptParser().parse("{(\"0123456789\"->digit)->positiveInteger}")
        var tokens = tokenizer.tokenize("123")
        
        XCTAssert(tokens.count == 1)
        
        tokenizer = OKScriptParser().parse("{(\"0123456789\"->digit,1,2)->positiveInteger}")
        tokens = tokenizer.tokenize("123")
        
        XCTAssert(tokens.count == 2)
    }
    
    func testTokenizerChain(){
        //No real pressure on the branches
        var tokenizer = OKScriptParser().parse("{\"i\".\"O\".\"S\"->iOS}")
        var tokens = tokenizer.tokenize("iOS")
        XCTAssert(tokens.count == 1)
        
        //Branch to one of two tokens
        tokenizer = OKScriptParser().parse("{\"i\".\"O\".\"S\"->iOS,\"O\".\"S\".\"-\".\"X\"->OSX}")
        tokens = tokenizer.tokenize("OS-X")
        XCTAssert(tokens.count == 1)

        //Check we can get both from same string
        tokens = tokenizer.tokenize("OS-XiOS")
        XCTAssert(tokens.count == 2)
    }
    
    func testTokenizerDelimited(){
        let testString = "{<'(',')',{({!\")\"->delimitedChar})->bracketedString}>->delimiterCharacters}"
        let tokenizer = OKScriptParser().parse(testString)
        
        let tokens = tokenizer.tokenize("(abcdefghij)")
        
        XCTAssert(tokens.count == 3)
    }
    
    func testRecursiveChar(){
        print(OKStandard.parseState(Characters(from:"hello").token("hi").description)!.description)
    }
    

    func testOKScriptParserPerformance() {
//        let tokFileTokDef = TokenizerFile().description
        let tokFileTokDef = readBundleFile("referenceOKScriptDefinition", ext: "txt")

        if (tokFileTokDef == nil) {
            return
        }
        
        self.measureBlock() {
            let generatedTokenizer = OKStandard.parseTokenizer(tokFileTokDef!)
            _ = generatedTokenizer?.tokenize(tokFileTokDef!)
        }
    }

    func testOKScriptTokenizerPerformance() {
        //        let tokFileTokDef = TokenizerFile().description
        if let loadedTokFile : String = readBundleFile("referenceOKScriptDefinition", ext: "txt") {
            
            var tokFileTokDef = loadedTokFile as String
            
            tokFileTokDef = tokFileTokDef + tokFileTokDef
            tokFileTokDef += tokFileTokDef
            tokFileTokDef += tokFileTokDef
            tokFileTokDef += tokFileTokDef
            
            self.measureBlock() {
                OKScriptTokenizer().tokenize(tokFileTokDef)
            }
        }
        
        
    }
}
