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
        
        self._privateCreateHandler()
    }
    
    //Should be private
    func _privateCreateHandler(){
        self.handler = {(token:Token)->Bool in
            if let countTokensCalled:String = self.countedToken{
                if token.name == countTokensCalled {
                    self.repeats++
                }
            } else {
                self.repeats++
            }

            //Start from scratch next time around
            self.currentState = self.repeatingState
            
            return true
        }
    }
    
    override func didEnter() {
        repeats = 0
        currentState = repeatingState
    }
    
    override func couldEnterWithCharacter(character: UnicodeScalar, controller: TokenizationController) -> Bool {
        
        return repeatingState.couldEnterWithCharacter(character, controller: self)
    }
    
    func validBranchingState(character: UnicodeScalar, controller: TokenizationController)->TokenizationStateChange?{
        for branch in branches{
            if branch.couldEnterWithCharacter(character, controller: controller){
                let validBranchTransition = branch.consume(character, controller: controller)
                switch validBranchTransition{
                case .Error,.Exit,.Transition:
                    return validBranchTransition
                case .None:
                    return TokenizationStateChange.Transition(newState: branch)
                }
            }
        }
        return nil
    }
    
    func manageExitFromState(character:UnicodeScalar, controller:TokenizationController) -> TokenizationStateChange{

        //Can I consume this character as a branch?
        if let validBranch = validBranchingState(character, controller: controller){
            return validBranch
        } else {
            //if not, create a token if I can
            if let token = generateToken(controller){
                controller.processToken(token)
            }
            return TokenizationStateChange.Exit
        }
        
    }
    
    override func consume(character: UnicodeScalar, controller: TokenizationController) -> TokenizationStateChange {
        tokenizing = character
        
        if maximumRepeats && maximumRepeats == repeats{
            return manageExitFromState(character, controller: controller)
        }
        
        let beforeConsumptionRepeats = repeats
        let consumptionResult = currentState!.consume(character, controller: self)
        let tokenEncountered = beforeConsumptionRepeats != repeats
        
        switch consumptionResult{
        case .Error(let subErrorToken):
            if repeats < minimumRepeats{
                let oldDescription = subErrorToken.errorToken.description()
                let newError = Token.ErrorToken(forString: controller.describeCaptureState(), problemDescription: "Expected at least \(minimumRepeats) repeats, "+subErrorToken.errorToken.description())
                return TokenizationStateChange.Error(errorToken: newError)
            }
            
            return manageExitFromState(character, controller: controller)
        case .Exit:
            currentState = repeatingState
            //Have we hit the repeat limit
            if maximumRepeats && repeats == maximumRepeats{
                return manageExitFromState(character, controller: controller)
            }
                        
            return consume(character, controller: controller)

        case .Transition(let newState):
            currentState = newState
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