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
        if let intValue = usingString.toInt() {
            self.init(value:intValue,characters: usingString)
        } else {
            let string:NSString = usingString
            self.init(value: string.doubleValue,characters:usingString)
        }
    }
    
    convenience init(usingToken:Token){
        switch usingToken.name{
        case "integer":
            return self.init(value:usingToken.characters.toInt()!,characters:usingToken.characters)
        case "float":
            let string : NSString = usingToken.characters
            return self.init(value: string.doubleValue, characters: usingToken.characters)
        default:
            return self.init(value:Double.NaN,characters:usingToken.characters)
        }
    }
    
    override var description:String {
        return "number = \(numericValue)"
    }
    
    class func createToken(state:TokenizationState,capturedCharacters:String)->Token{
        return NumberToken(usingString:capturedCharacters)
    }
}
