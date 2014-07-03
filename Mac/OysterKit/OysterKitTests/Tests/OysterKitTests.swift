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

func token(name:String,chars:String?=nil)->Token{
    var actualChars:String
    
    if chars{
        actualChars = chars!
    } else {
        actualChars = name
    }
    
    return Token(name: name, withCharacters: actualChars)
}

func char(chars:String)->TokenizationState{
    return Char(from:chars)
}

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
            Branch().branch(
                char("x").branch(
                    char("y").token("xy"),
                    char("z").token("xz")
                )
            )
        )
        
        println("\n"+tokenizer.description())
        
        tokenizer.tokenize("xyxz")
        
        XCTAssert(tokenizer.tokenize("xyxz") == [token("xy"),token("xz")])
    }
    
    func testRepeatFixed(){
        tokenizer.branch(
            Repeat(state:char("x").sequence(char("y").token("xy")),min:3,max:3).token("xyxyxy")
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
}
