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
    
    var inverted = false
    
    init(from:String){
        self.allowedCharacters = from
        super.init()
    }
    
    init(except:String){
        self.inverted = true
        self.allowedCharacters = except
        super.init()
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
    
    override class func convertFromStringLiteral(value: String) -> Char {
        var parsedState = OysterKit.parseState(value)
        if parsedState is Char {
            return parsedState as Char
        }
        return Char(from:"")
    }
    
    override class func convertFromExtendedGraphemeClusterLiteral(value: String) -> Char {
        return Char.convertFromStringLiteral(value)
    }
    
    
    override func couldEnterWithCharacter(character: UnicodeScalar, controller: TokenizationController) -> Bool {
        return isAllowed(character)
    }
    
    override func consume(character: UnicodeScalar, controller: TokenizationController) -> TokenizationStateChange {
        if isAllowed(character){
            return selfSatisfiedBranchOutOfStateTransition(true, controller: controller, withToken: createToken(controller, useCurrentCharacter: true))
        } else {
            return selfSatisfiedBranchOutOfStateTransition(false, controller: controller, withToken: nil)
        }
    }
    
    override func serialize(indentation: String) -> String {
        var output = ""
        if inverted {
            output+="!"
        }
        
        output+="\""
        for character in allowedCharacters{
            switch character {
            case "\\":
                output+="\\\\"
            case "\"":
                output+="\\\""
            case "\x04":
                output+="\\x04"
            case "\r":
                output+="\\r"
            case "\n":
                output+="\\n"
            case "\t":
                    output+="\\t"
            default:
                output+=character
            }
        }
        output+="\""
        

        output+=serializeBranches(indentation+"\t")

        return output
    }

}