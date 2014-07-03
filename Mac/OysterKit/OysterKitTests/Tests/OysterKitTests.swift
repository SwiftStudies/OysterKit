/*
Copyright (c) 2014, RED When Excited
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import XCTest
import OysterKit

class OysterKitTests: XCTestCase {
    
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
    
    func dump(izer:Tokenizer,with:String){
        println("\nTokenizing "+with)
        izer.tokenize(with){(token:Token)->Bool in
            println("\t"+token.description())
            return true
        }
        println("\n")
    }
    

    
    //Tests basic chaining
    func testXY(){
        tokenizer.sequence(char("x"),char("y").token("xy"))
        tokenizer.branch(OysterKit.eot)
        
        XCTAssert(tokenizer.tokenize("xy") == [token("xy")], "Chained results do not match")
    }
    
    func testChar(){
        tokenizer.branch(
            char("xyz1").token("character"),
            OysterKit.eot
        )
        
        XCTAssert(tokenizer.tokenize("x1z") == [token("character",chars: "x"), token("character",chars: "1"),token("character",chars: "z"),])
    }
    
    func testSentance(){
        tokenizer.branch(
            OysterKit.word,
            OysterKit.whiteSpaces,
            OysterKit.eot
        )
        
        XCTAssert(tokenizer.tokenize("Quick fox") == [token("word",chars: "Quick"), token("whitespace",chars: " "),token("word",chars: "fox")])
    }
    
    
    func testBranch(){
        tokenizer.branch(
            char("x").branch(
                char("y").token("xy"),
                char("z").token("xz")
            ),
            OysterKit.eot
        )

        println(tokenizer.description())
        
        XCTAssert(tokenizer.tokenize("xyxz") == [token("xy"),token("xz")])
    }
    
    func testNestedBranch(){
        tokenizer.branch(
            Branch(states: [
                char("x").branch(
                    char("y").token("xy"),
                    char("z").token("xz")
                )
            ])
        )
        
        tokenizer.tokenize("xyxz")
        
        XCTAssert(tokenizer.tokenize("xyxz") == [token("xy"),token("xz")])
    }
    
    
    
    func testSequence1(){
        let expectedResults = [token("done",chars:"xyz")]
        
        tokenizer.branch(
            sequence(char("x"),char("y"),char("z").token("done")),
            OysterKit.eot
        )
        
        XCTAssert(tokenizer.tokenize("xyz") == expectedResults)
    }

    func testSequence2(){
        let expectedResults = [token("done",chars:"xyz")]
        
        tokenizer.branch(
            char("x").sequence(char("y"),char("z").token("done")),
            OysterKit.eot
        )
        
        XCTAssert(tokenizer.tokenize("xyz") == expectedResults)
    }
    
    
    func testRepeat2HexDigits(){
        //Test for 2
        tokenizer.branch(
            Repeat(state:OysterKit.hexDigit, min:2,max:2).token("xx"),
            OysterKit.eot
        )
        
        XCTAssert(tokenizer.tokenize("AF") == [token("xx",chars:"AF")])
        XCTAssert(tokenizer.tokenize("A") != [token("xx",chars:"A")])
        XCTAssert(tokenizer.tokenize("AF00") == [token("xx",chars:"AF"),token("xx",chars:"00")])
    }
    
    func testRepeat4HexDigits(){
        tokenizer.branch(
            Repeat(state:OysterKit.hexDigit, min:4,max:4).token("xx"),
            OysterKit.eot
        )
        
        XCTAssert(tokenizer.tokenize("AF00") == [token("xx",chars:"AF00")])
    }
    
    func testRepeatXYFixed1(){
        
        println("\n\n\n BEGIN FIXED REPEAT TEST")
        
        tokenizer.branch(
            Repeat(state:char("x").sequence(char("y").token("xy")),min:3,max:3).token("xyxyxy")
        )
        
        println("\n"+tokenizer.description())
        dump(tokenizer, with: "xyxyxy")
        
        XCTAssert(tokenizer.tokenize("xyxyxy") == [token("xyxyxy")])
        println("END FIXED REPEAT TEST\n\n\n")
    }
    
    func testRepeatXYFixed2(){
        tokenizer.branch(
            Repeat(state:Branch().branch(
                sequence(char("x"),char("y").token("xyxyxy"))
                ),min:3,max:3),
            OysterKit.eot
        )
        
        dump(tokenizer, with: "xyxyxy")
        
        XCTAssert(tokenizer.tokenize("xyxyxy") == [token("xyxyxy")])        
    }
    
    
    func testSimpleString(){
        tokenizer.branch(
            OysterKit.blanks,
            OysterKit.number,
            OysterKit.word,
            OysterKit.eot
        )

        let parsingTest = "Short 10 string"
        
        XCTAssert(tokenizer.tokenize(parsingTest) == [token("word",chars:"Short"), token("blank",chars:" "), token("integer",chars:"10"), token("blank",chars:" "), token("word",chars:"string"), ])
    }
    
    func testQuotedString(){
        let tougherTest = "1.5 Nasty example with -10 or 10.5 maybe even 1.0e-10 \"Great \\(variableName) \\t 🐨 \\\"Nested\\\" quote\"!"
        
        tokenizer.branch(
            Delimited(delimiter:"\"",states:
                char("\\").branch(
                    char("t\"").token("character"),
                    Delimited(open:"(",close:")",states:OysterKit.word).token("inline")
                ),
                Char(except:"\"").token("character")
                ).token("quoted-string"),
            OysterKit.blanks,
            OysterKit.number,
            OysterKit.word,
            OysterKit.punctuation,
            OysterKit.eot
        )
        
        XCTAssert(tokenizer.tokenize(tougherTest) == [token("float",chars:"1.5"), token("blank",chars:" "), token("word",chars:"Nasty"), token("blank",chars:" "), token("word",chars:"example"), token("blank",chars:" "), token("word",chars:"with"), token("blank",chars:" "), token("integer",chars:"-10"), token("blank",chars:" "), token("word",chars:"or"), token("blank",chars:" "), token("float",chars:"10.5"), token("blank",chars:" "), token("word",chars:"maybe"), token("blank",chars:" "), token("word",chars:"even"), token("blank",chars:" "), token("float",chars:"1.0e-10"), token("blank",chars:" "), token("quoted-string",chars:"\""), token("character",chars:"G"), token("character",chars:"r"), token("character",chars:"e"), token("character",chars:"a"), token("character",chars:"t"), token("character",chars:" "), token("inline",chars:"\\("), token("word",chars:"variableName"), token("inline",chars:")"), token("character",chars:" "), token("character",chars:"\\t"), token("character",chars:" "), token("character",chars:"🐨"), token("character",chars:" "), token("character",chars:"\\\""), token("character",chars:"N"), token("character",chars:"e"), token("character",chars:"s"), token("character",chars:"t"), token("character",chars:"e"), token("character",chars:"d"), token("character",chars:"\\\""), token("character",chars:" "), token("character",chars:"q"), token("character",chars:"u"), token("character",chars:"o"), token("character",chars:"t"), token("character",chars:"e"), token("quoted-string",chars:"\""), token("punct",chars:"!"), ])
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
                
                //Finally fail
                return TokenizationStateChange.Error(errorToken: Token.ErrorToken(forString: controller.describeCaptureState(), problemDescription: "Expected FF for ASCII or for unicode {FFFF} (F represents any hex digit)"))
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
