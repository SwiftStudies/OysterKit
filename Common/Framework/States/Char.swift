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

class Char : Branch{
    let allowedCharacters : String
    
    var firstCharacter = true
    var inverted = false
    
    init(from:String){
        self.allowedCharacters = from
    }
    
    init(except:String){
        self.inverted = true
        self.allowedCharacters = except
    }
        
    func newSetByMergingWith(otherCharacterSet:Char)->Char{
        return Char(from: self.allowedCharacters+otherCharacterSet.allowedCharacters)
    }
    
    func isAllowed(character:UnicodeScalar)->Bool{
        for allowedCharacter in allowedCharacters.unicodeScalars{
            if allowedCharacter == character {
                return !inverted
            }
        }
        return inverted
    }
    
    override func reset() {
        firstCharacter = true
        super.reset()
    }
    
    override func couldEnterWithCharacter(character: UnicodeScalar, controller: TokenizationController) -> Bool {
        return isAllowed(character)
    }
    
    override func consume(character: UnicodeScalar, controller: TokenizationController) -> TokenizationStateChange {
        if firstCharacter{
            if isAllowed(character){
                firstCharacter = false
                //We will exit or branch next time
                return TokenizationStateChange.None
            } else {
                return TokenizationStateChange.Error(errorToken: Token.ErrorToken(forString: controller.describeCaptureState(),problemDescription: "Expected one of "+allowedCharacters))
            }
        } else {
            //If we have other transitions, continue so we can fall through next time
            if branches.count == 0{
                //If we are token creating, create one
                if let token = generateToken(controller){
                    controller.processToken(token)
                    return TokenizationStateChange.Exit
                }
                //We can't branch, we can't create a token, all we can do is exit
                return TokenizationStateChange.Exit
            }
            
            let branchTransition = super.consume(character,controller: controller)
            switch branchTransition{
            case .Error:
                if let token = generateToken(controller){
                    controller.processToken(token)
                    return TokenizationStateChange.Exit
                } else {
                    return branchTransition
                }
            default:
                return branchTransition
            }
        }
    }
    
    override func description()->String {
        var invertString:String = inverted ? "excluding" : "from"
        return "Character \(invertString) '\(allowedCharacters)'"
    }

}