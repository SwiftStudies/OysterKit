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
    
    class func createToken(state:TokenizationState,controller:TokenizationController)->Token{
        return OperatorToken(characters: controller.capturedCharacters())
    }
}
