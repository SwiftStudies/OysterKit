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

class Repeat : BranchingController{
    let minimumRepeats = 1
    let maximumRepeats : Int?
    let countedToken : String?
    
    var  repeats = 0
    let  repeatingState:TokenizationState
    
    init(state:TokenizationState, min:Int=1,max:Int? = nil){
        self.minimumRepeats = min
        self.maximumRepeats = max
        self.repeatingState = state
        self.countedToken = nil

        //Initialise super class
        super.init()        
    }
    
    override func holdToken(newToken: Token){
        if let countTokensCalled:String = self.countedToken{
            if newToken.name == countTokensCalled {
                println("Counted "+newToken.description())
                self.repeats++
            }
        } else {
            println("Counted "+newToken.description())
            self.repeats++
        }
        
        return
    }
    
    override func clearToken() {
        println("Token stacking not currently supported by repeat, use a specific counted token name instead")
    }
    
    override func didEnter() {
        repeats = 0
        currentState = repeatingState
    }
    
    override func couldEnterWithCharacter(character: UnicodeScalar, controller: TokenizationController) -> Bool {
        return repeatingState.couldEnterWithCharacter(character, controller: self)
    }
    
    func ungracefulExit(controller:TokenizationController, consumedCharacter:Bool)->TokenizationStateChange{
        //Regardless of the reason, if I have not crossed the number of minimum repeats I should generate an error
        if repeats < minimumRepeats {
            return TokenizationStateChange.Exit(consumedCharacter: consumedCharacter)
        }
        
        //Otherwise create a deferred transition, if it was an error I haven't consumed the current character
        //if it wasn't then I have
        if !consumedCharacter {
            return selfSatisfiedBranchOutOfStateTransition(false, controller: controller, withToken: createToken(controller, capturedCharacters: controller.capturedCharacters()))
        } else {
            return selfSatisfiedBranchOutOfStateTransition(true, controller: controller, withToken: createToken(controller, capturedCharacters: controller.capturedCharacters()+"\(controller.currentCharacter())"))
        }
        
    }
    
    override func consume(character: UnicodeScalar, controller: TokenizationController) -> TokenizationStateChange {
        tokenizing = character
        
        let beforeConsumptionRepeats = repeats
        let consumptionResult = currentState!.consume(character, controller: self)
        let tokenEncountered = beforeConsumptionRepeats != repeats
        
        if tokenEncountered{
            if maximumRepeats && maximumRepeats == repeats {
                //Hit the limit, create the token which may be deferred if I can branch and move on
                let token = createToken(controller, capturedCharacters: controller.capturedCharacters()+"\(controller.currentCharacter())")
                return selfSatisfiedBranchOutOfStateTransition(true, controller: controller, withToken: token)
            }
            
            //Reset and look for another
            currentState = repeatingState
            storedCharacters = ""
            
            return TokenizationStateChange.None
        }
        
        switch consumptionResult{
        case .Exit(let exitCondition):

            return ungracefulExit(controller, consumedCharacter:exitCondition)
        case .Transition(let newState, let consumedCharacter):
            currentState = newState
            if !consumedCharacter {
                return consume(character,controller: controller)
            }
            fallthrough
        case .None:
            storedCharacters += "\(character)"
            return TokenizationStateChange.None
        default:
            println("What the hell???")
        }
        
    }

    override func description()->String {
        return "Repeat \(repeatingState.description()) Min:\(minimumRepeats) Max:\(maximumRepeats)"
    }
    
    
}