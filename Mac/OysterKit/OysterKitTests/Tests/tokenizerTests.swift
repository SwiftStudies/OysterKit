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
        class HexCharacterStart : Branch{
            init(){
                super.init()
                branch(
                    Repeat(state: OysterKit.hexDigit, min:2,max:2).token("character"),
                    Char(from: "{").sequence(
                        Repeat(state: OysterKit.hexDigit, min: 4, max: 4),
                        Char(from: "}").token("character")
                    )
                )
            }
            
            override func consume(character: UnicodeScalar, controller: TokenizationController) -> TokenizationStateChange {
                if controller.capturedCharacters()+"\(character)" == "\\x"{
                    //If the current state + the new character is \x we should enter this state
                    return TokenizationStateChange.None
                } else if controller.capturedCharacters() == "\\x"{
                    //Otherwise if we already have the prefix see if we can transition to another state
                    return super.consume(character, controller: controller)
                }
                
                return TokenizationStateChange.Exit(consumedCharacter: false)
                
                //Finally fail
//                return TokenizationStateChange.Error(errorToken: Token.ErrorToken(forString: controller.describeCaptureState(), problemDescription: "Expected FF for ASCII or for unicode {FFFF} (F represents any hex digit)"))
            }
            
        }
        
        let escapedControlCodes = "\\vrnt"
        let escapedAnchorCharacters = "AzZbB"
        let escapedRegexSyntax = "[]()|?.*+{}"
        let escapedCharacterClasses = "sSdDwW"
        
        var regexCharacterTokenizer = Tokenizer()
        
        let singleAnchors = Branch().branch(
            Char(from:"^").token("character"),
            Char(from:"$").token("character")
        )
        
        let escapedAnchors = Char(from:"\\").branch(
            Char(from:escapedControlCodes+escapedAnchorCharacters+escapedRegexSyntax+escapedCharacterClasses).token("character"),
            Char(from:"x").branch(
                HexCharacterStart()
            )
        )
        
        tokenizer.branch(
            OysterKit.eot,
            singleAnchors,
            escapedAnchors
        )
        
        let regexTest = "$^\\b\\B\\A\\z\\Z\\t\\n\\r\\\\\\[\\s\\x0a\\x{acd3}$^$"
        
        XCTAssert(tokenizer.tokenize(regexTest).count == 18)
    }
    

    


}
