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

public class Token : CustomStringConvertible{
    public let name:String
    public var characters:String = ""
    public var originalStringIndex:Int?
    public var originalStringLine:Int?
    
    init(name:String){
        self.name = name
    }

    public init(name:String, withCharacters:String){
        self.name = name
        self.characters = withCharacters
    }

    public init(name:String, withCharacters:String, index:Int){
        self.name = name
        self.characters = withCharacters
        self.originalStringIndex = index
    }
    
    
    public var description : String {
        if (originalStringIndex != nil) {
            return "\(name) '\(characters)' at \(originalStringIndex)"
        } else {
            return "\(name) '\(characters)'"
        }
    }
    
    public class func createToken(state:TokenizationState,capturedCharacters:String,startIndex:Int)->Token{
        let token = Token(name:"Token",withCharacters:capturedCharacters)
        token.originalStringIndex = startIndex
        return token
    }
    
    public class EndOfTransmissionToken : Token {
        init(){
            super.init(name: "End of Transmission",withCharacters: "")
        }
    }
    
    public class ErrorToken: Token{
        let problem : String
        
        init(forString:String, problemDescription:String){
            problem = problemDescription
            super.init(name: "Error", withCharacters: forString)
        }
        
        init(forCharacter:UnicodeScalar,problemDescription:String){
            problem = problemDescription
            super.init(name: "Error", withCharacters: "\(forCharacter)")
        }
        
        public override var description:String {
            return super.description+" - "+problem
        }
    }
}

class WhiteSpaceToken : Token{
    
    init(characters:String, startingAt:Int){
        super.init(name: "whitespace", withCharacters: characters)
        originalStringIndex = startingAt
    }
    
    override class func createToken(state:TokenizationState,capturedCharacters:String,startIndex:Int)->Token{
        return WhiteSpaceToken(characters:capturedCharacters, startingAt: startIndex)
    }
    
    override var description:String {
        return self.name
    }
}

class NumberToken : Token{
    var numericValue:Double
    
    init(value:Double,characters:String){
        numericValue = value
        super.init(name: "number", withCharacters: characters)
    }
    
    init(value:Int,characters:String){
        numericValue = Double(value)
        super.init(name: "number", withCharacters: characters)
    }
    
    convenience init(usingString:String){
        if let intValue = Int(usingString) {
            self.init(value:intValue,characters: usingString)
        } else {
            let string:NSString = usingString
            self.init(value: string.doubleValue,characters:usingString)
        }
    }
    
    convenience init(usingToken:Token){
        switch usingToken.name{
        case "integer":
            if let intValue = Int(usingToken.characters) {
                self.init(value:intValue,characters:usingToken.characters)
            } else {
                self.init(value:Double.NaN,characters:usingToken.characters)
            }
        case "float":
            let string : NSString = usingToken.characters
            self.init(value: string.doubleValue, characters: usingToken.characters)
        default:
            self.init(value:Double.NaN,characters:usingToken.characters)
        }
    }
    
    override var description:String {
    return "number = \(numericValue)"
    }
    
    override class func createToken(state:TokenizationState,capturedCharacters:String,startIndex:Int)->Token{
        let token = NumberToken(usingString:capturedCharacters)
        token.originalStringIndex = startIndex
        return token
    }
}

class OperatorToken : Token{
    func presidence()->Int{
        switch characters{
        case "^":
            return 4
        case "*","/":
            return 3
        case "+","-":
            return 2
        default:
            return 0
        }
    }
    
    init(characters: String) {
        super.init(name: "operator", withCharacters: characters)
    }
    
    func applyTo(left:NumberToken,right:NumberToken)->NumberToken{
        switch characters{
        case "+":
            return NumberToken(value: left.numericValue+right.numericValue, characters: left.characters+characters+right.characters)
        case "-":
            return NumberToken(value: left.numericValue-right.numericValue, characters: left.characters+characters+right.characters)
        case "*":
            return NumberToken(value: left.numericValue*right.numericValue, characters: left.characters+characters+right.characters)
        case "/":
            return NumberToken(value: left.numericValue/right.numericValue, characters: left.characters+characters+right.characters)
        default:
            return NumberToken(value: Double.NaN, characters: left.characters+characters+right.characters)
        }
    }
    
    override class func createToken(state:TokenizationState,capturedCharacters:String,startIndex:Int)->Token{
        let token = OperatorToken(characters:capturedCharacters)
        token.originalStringIndex = startIndex
        return token
    }
}


