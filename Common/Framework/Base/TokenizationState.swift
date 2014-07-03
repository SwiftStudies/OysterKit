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
    case Exit
    //Leave this state, and there was an error
    case Error(errorToken:Token.ErrorToken)
    //Move to this new state
    case Transition(newState:TokenizationState)
}


protocol TokenizationState{
    //
    // Tokenization
    //
    func couldEnterWithCharacter(character:UnicodeScalar, controller:TokenizationController)->Bool
    func consume(character:UnicodeScalar, controller:TokenizationController) -> TokenizationStateChange
    
    //
    // State transition
    //
    func reset()
    func didEnter()
    func didExit()
    
    //
    // Definition of tokenization state machine
    //
    func branch(toStates:TokenizationState...)->TokenizationState
    func sequence(ofStates:TokenizationState...)->TokenizationState
    func token(emitToken:Token)->TokenizationState
    func token(emitToken:String)->TokenizationState
    func token(with:TokenCreationBlock)->TokenizationState
    
    func description()->String
}

typealias   TokenCreationBlock = ((state:TokenizationState,controller:TokenizationController)->Token)


