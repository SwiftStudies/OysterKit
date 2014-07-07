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


class Tokenizer : BranchingController {
    
    //Implementation specific
    func tokenize(character:UnicodeScalar)->Bool{
        let branchingControllerResult = consume(character, controller: self)
        switch branchingControllerResult {
        case .Exit:
            return false
        default:
            return true
        }
    }
    
    func tokenize(string: String, newToken: TokenHandler) {
        //Initialize
        var terminatedString = string+"\u0004"
        handler = newToken
        currentState = self
        error = false
        elementIndex = 0
        
        //Iterate through the characters
        for character in terminatedString.unicodeScalars{
            if error{
                return
            }
            tokenizing = character
            if !tokenize(character){
                return
            }
        }
    }
    
    func tokenize(string:String) -> Array<Token>{
        var tokens = Array<Token>()
        
        tokenize(string, newToken: {(token:Token)->Bool in
            tokens.append(token)
            return true
        })

        return tokens
    }
}





