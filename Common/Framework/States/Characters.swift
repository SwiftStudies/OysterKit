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

//
//Completely stateless
//
public class Characters : TokenizationState{
    var allowedCharacters : String
    var inverted = false
    
    override func stateClassName()->String {
        return "Char \(allowedCharacters)"
    }

 
    
    public init(from:String){
        self.allowedCharacters = from
        super.init()
    }
    
    public init(except:String){
        self.inverted = true
        
        //Inverted chars can be dangerous if they don't reject
        //the eot character
        self.allowedCharacters = except+"\u{0004}"
        super.init()
    }
    
    func isAllowed(character:Character)->Bool{
        for allowedCharacter in allowedCharacters.characters{
            if allowedCharacter == character {
                return !inverted
            }
        }
        return inverted
    }

    
    
    func annotations()->String{
        return inverted ? "!" : ""
    }
    
    override func serialize(indentation: String) -> String {
        
        var output = annotations()
        
        output+="\""
        for character in allowedCharacters.characters{
            switch character {
            case "\\":
                output+="\\\\"
            case "\"":
                output+="\\\""
            case "\u{04}":
                output+="\\x04"
            case "\r":
                output+="\\r"
            case "\n":
                output+="\\n"
            case "\t":
                    output+="\\t"
            default:
                output+="\(character)"
            }
        }
        output+="\""
        

        output+=serializeBranches(indentation+"\t")

        return output
    }

    
    override public func clone()->TokenizationState {
        var newState : TokenizationState
        
        if inverted {
            newState = Characters(except: allowedCharacters)
        } else {
            newState = Characters(from: allowedCharacters)
        }
        
        newState.__copyProperities(self)
        return newState
    }
    
    public override func scan(operation: TokenizeOperation) {
        operation.debug("Entered "+(inverted ? "!" : "")+"Char '\(allowedCharacters)'")

        if isAllowed(operation.current) {
            //Move scanning forward
            operation.advance()
            
            //Emit a token, branch on
            emitToken(operation)
            
            //If we are done, bug out
            if operation.complete {
                return
            }
            
            //Otherwise evaluate our branches
            scanBranches(operation)
        }
    }
    
}