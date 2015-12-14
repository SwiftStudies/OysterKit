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

import Foundation

let __okDebug = false

//Should be private and class variables
public let decimalDigitString = "0123456789"
public let hexDigitString = decimalDigitString+"ABCDEFabcdef"
public let puncuationString = "!\"#$%&'()*+,\\-./:;<=>?@[]^_`{|}~"
public let blankString = " \t"
public let whiteSpaceString = " \t\r\n"
public let lowerCaseLetterString = "abcdefghijklmnopqrstuvwxyz"
public let upperCaseLetterString = lowerCaseLetterString.uppercaseString
public let eotString = "\u{0004}"

public class OKStandard{
    //Public
    public class var decimalDigit:TokenizationState{
        return Characters(from: decimalDigitString).token("digit")
    }
    
    public class var hexDigit:TokenizationState{
        return Characters(from: hexDigitString).token("xdigit")
    }
    
    public class var punctuation:TokenizationState{
        return Characters(from: puncuationString).token("punct")
    }
    
    public class var eot:TokenizationState{
        class EOTState : TokenizationState{
            override func scan(operation: TokenizeOperation) {
                operation.debug("Entered EOTState")
                
                if operation.current == "\u{04}" {
                    //Emit a token, branch on
                    emitToken(operation)
                }
            }
        }

        return EOTState().token(){ (state:TokenizationState, capturedCharacters:String, startIndex:Int)->Token in
            let token = Token.EndOfTransmissionToken()
            token.originalStringIndex = startIndex
            return token
        }
    }
    
    public class var blank:TokenizationState{
        return Characters(from: blankString).token("blank")
    }
    
    public class var whiteSpace:TokenizationState{
        return Characters(from: whiteSpaceString).token("space")
    }
    
    public class var lowercaseLetter:TokenizationState{
        return Characters(from: lowerCaseLetterString).token("lower")
    }
    
    public class var uppercaseLetter:TokenizationState{
        return Characters(from:upperCaseLetterString).token("upper")
    }
    
    public class var letter:TokenizationState{
        return Characters(from: lowerCaseLetterString+upperCaseLetterString).token("alpha")
    }
    
    public class var letterOrDigit:TokenizationState{
        return Characters(from: lowerCaseLetterString+upperCaseLetterString+decimalDigitString).token("alnum")
    }
    
    public class var wordCharacter:TokenizationState{
        return Characters(from: lowerCaseLetterString+upperCaseLetterString+decimalDigitString+"_").token("word")
    }
    
    
    public class var number:TokenizationState{
        let decimalDigits = LoopingCharacters(from:decimalDigitString)
        let sign = Characters(from:"+-")
        let exponentCharacter = Characters(from:"eE")
            
        let floatExit = Exit().token("float")
        let integerExit = Exit().token("integer")
        
        let exponent = exponentCharacter.branch(
            sign.clone().branch(decimalDigits.clone().token("float")),
            decimalDigits.clone().token("float")
        )
        
            
        let digitsBeforeDecimalPoint = decimalDigits.clone().branch(
            Characters(from:".").branch(
                decimalDigits.clone().branch(
                    exponent,
                    floatExit   //If there's no eE then it's just a normal float
                )
            ),
            integerExit     //If there's no . then it's an int
        )
            
        let number = Branch().branch(
            sign.clone().branch(
                digitsBeforeDecimalPoint,
                Exit().token("operator")    //If there are no numbers then it's just an operator
            ),
            digitsBeforeDecimalPoint
        )

        return number
    }
    
    public class var word:TokenizationState{
        return LoopingCharacters(from: lowerCaseLetterString+upperCaseLetterString+decimalDigitString+"_").token("word")
    }
    

    
    public class var blanks:TokenizationState{
        return LoopingCharacters(from:blankString).token("blank")
    }
    
    public class var whiteSpaces:TokenizationState{
        return LoopingCharacters(from: whiteSpaceString).token(WhiteSpaceToken.createToken)
    }

    public class func parseState(stateDefinition:String)->TokenizationState?{
        return OKScriptParser().parseState(stateDefinition)
    }
    
    public class func parseTokenizer(tokenizerDefinition:String)->Tokenizer?{
        return OKScriptParser().parse(tokenizerDefinition)
    }
    
    public class Code {
        public class var quotedString:TokenizationState{
        return Delimited(delimiter: "\"", states:
            Repeat(state:Branch().branch(
                Characters(from:"\\").branch(
                    Characters(from:"trn\"\\").token("char")
                ),
                LoopingCharacters(except: "\"\\").token("char")
                ), min: 1, max: nil).token("quoted-string")
            )
        }
        
        public class var quotedStringIncludingQuotes:TokenizationState{
            return quotedString.token("double-quote")
        }
        
        public class var quotedCharacter:TokenizationState{
        return Delimited(delimiter: "'", states:
            Repeat(state:Branch().branch(
                Characters(from:"\\").branch(
                    Characters(from:"trn'\\").token("char")
                ),
                LoopingCharacters(except: "'\\").token("char")
                ), min: 1, max: 1).token("char")
            )
        }
        
        public class var quotedCharacterIncludingQuotes:TokenizationState{
        return quotedCharacter.token("quote")
        }
    
        
        public class var variableName:TokenizationState{
        return Characters(from:lowerCaseLetterString+upperCaseLetterString).sequence(
                LoopingCharacters(from:lowerCaseLetterString+upperCaseLetterString+decimalDigitString+"_-").token("variable")
            )
        }
    }
}