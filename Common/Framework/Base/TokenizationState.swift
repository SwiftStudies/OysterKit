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

enum TokenizationStateChange{
    //No state change requried
    case None
    //Leave this state
    case Exit(consumedCharacter:Bool)
    //Move to this new state
    case Transition(newState:TokenizationState,consumedCharacter:Bool)
}

//
// XCode 6 Beta 3 Crashes if two protocols refer to each other, so turning this into a class for now
//
class TokenizationState : Printable, StringLiteralConvertible {
    //
    // String Literal
    //
    class func convertFromStringLiteral(value: String) -> TokenizationState {
        if let parsedState = OysterKit.parseState(value) {
            return parsedState
        }
        
        return TokenizationState()
    }
    
    class func convertFromExtendedGraphemeClusterLiteral(value: String) -> TokenizationState {
        return TokenizationState.convertFromStringLiteral(value)
    }
    
    
    //
    // Tokenization
    //
    
    //
    // This is called each time the state is a possible entry point for the next token. It is essential
    // that this method NEVER depends on the internal conditions of the state (this is important becuase
    // otherwise we would have to reset the state before considering it)
    //
    func couldEnterWithCharacter(character:UnicodeScalar, controller:TokenizationController)->Bool{
        return false
    }
    
    
    func consume(character:UnicodeScalar, controller:TokenizationController) -> TokenizationStateChange{
        return TokenizationStateChange.Exit(consumedCharacter: false)
    }
    
    //
    // State transition
    //
    func reset(){

    }
    
    func didEnter(){

    }
    
    func didExit(){

    }
    
    //
    // Definition of tokenization state machine
    //
    func branch(toStates:TokenizationState...)->TokenizationState{
        return self
    }
    func sequence(ofStates:TokenizationState...)->TokenizationState{
        return self
    }

    func token(emitToken:Token)->TokenizationState{
        return self
    }

    func token(emitToken:String)->TokenizationState{
        return self
    }

    func token(with:TokenCreationBlock)->TokenizationState{
        return self
    }

    
    //
    // Output
    //
    func serialize(indentation:String)->String{
return ""
}

    var description:String{
        return ""
    }
}

typealias   TokenCreationBlock = ((state:TokenizationState,capturedCharacteres:String,charactersStartIndex:Int)->Token)


