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

class BranchingController : Branch,TokenizationController {
    var storedCharacters = ""
    var handler:TokenHandler?
    var inStartingState = true
    var tokenizing : UnicodeScalar?
    var error:Bool = false
    
    var contexts = Array<Array<TokenizationState>>()

    var currentState : TokenizationState?{
        willSet{
            currentState?.didExit()
        }
        didSet{
            currentState?.didEnter()
        }
    }
    
    override func didExit() {
        inStartingState = false
    }
    
    func capturedCharacters() -> String {
        return storedCharacters
    }
        
    func describeCaptureState() -> String {
        return storedCharacters+"▷\(tokenizing)◁"
    }
    
    func processToken(newToken: Token) {
        handler!(token:newToken)        
    }
    
    func push(newContext: Array<TokenizationState>) {
        contexts.append(branches)
        branches = newContext
        currentState = self
        
    }
    
    func pop() {
        branches = contexts[contexts.endIndex-1]
        contexts.removeLast()
    }
    
    override func consume(character: UnicodeScalar, controller: TokenizationController) -> TokenizationStateChange {
        tokenizing = character
        
        var consumptionResult:TokenizationStateChange?
        
        if inStartingState{
            consumptionResult = super.consume(character,controller:self)
        } else {
            consumptionResult = currentState!.consume(character,controller:self)
        }
        
        
        switch consumptionResult!{
            case .Error(let errorToken):
                processToken(errorToken)
                error = true
            case .Exit:
                currentState = self
                return consume(character, controller:controller)
            case .Transition(let newState):
                currentState = newState
                return consume(character, controller: controller)
            case .None:
                storedCharacters += "\(character)"
                return TokenizationStateChange.None
        }
        
        return TokenizationStateChange.None
    }
    
    override func reset(){
        inStartingState = true
        storedCharacters = ""
        tokenizing = nil
        super.reset()
    }
    
    override func description() -> String {
        return "Controller"
    }
}