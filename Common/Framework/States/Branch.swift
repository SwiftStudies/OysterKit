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


class Branch : TokenizationState {
    

    
    var tokenGenerator : TokenCreationBlock?
    var branches = Array<TokenizationState>() //All states that can be transitioned to
    
    init(){
        
    }
    
    init(states:Array<TokenizationState>){
        branches = states
    }
    
    //currently stateless
    func didExit() {
        reset()
    }
    
    //currently stateless
    func didEnter() {
        reset()
    }

    //reset all branches
    func reset() {
        for otherState in branches{
            otherState.reset()
        }
    }
    
    func couldEnterWithCharacter(character: UnicodeScalar, controller: TokenizationController) -> Bool {
        for branch in branches{
            if branch.couldEnterWithCharacter(character, controller: controller){
                return true
            }
        }
        return false
    }
    
    //You may wish to over-ride to set the context for improved error messages
    func consume(character:UnicodeScalar, controller:TokenizationController) -> TokenizationStateChange{
        for branch in branches{
            if (branch.couldEnterWithCharacter(character, controller: controller)){
                return TokenizationStateChange.Transition(newState: branch, consumedCharacter:false)
            }
            
        }

        return TokenizationStateChange.Exit(consumedCharacter: false)
    }
    
    func branch(toStates: TokenizationState...) -> TokenizationState {
        for state in toStates{
            branches.append(state)
        }
        
        return self
    }

    func sequence(ofStates: TokenizationState...) -> TokenizationState {
        branch(ofStates[0])
        for index in 1..ofStates.count{
            ofStates[index-1].branch(ofStates[index])
        }
        
        return self
    }

    func token(emitToken: String) -> TokenizationState {
        tokenGenerator = {(state:TokenizationState, capturedCharacters:String, startIndex:Int)->Token in
            var token = Token(name: emitToken, withCharacters: capturedCharacters)
            token.originalStringIndex = startIndex
            return token
        }
        
        return self
    }
    
    func token(emitToken: Token) -> TokenizationState {
        tokenGenerator = {(state:TokenizationState, capturedCharacters:String, startIndex:Int)->Token in
            var token = Token(name: emitToken.name, withCharacters: capturedCharacters)
            token.originalStringIndex = startIndex
            return token
        }

        return self
    }
    
    func token(with: TokenCreationBlock) -> TokenizationState {
        tokenGenerator = with

        return self
    }
    
    func serializeStateArray(indentation:String, states:Array<TokenizationState>)->String{
        if states.count == 1 {
            return states[0].serialize(indentation)
        }
        var output = ""
        var first = true
        for state in states {
            if !first {
                output+=","
            } else {
                first = false
            }
            output+="\n"
            output+=indentation+state.serialize(indentation)
        }
        
        return output
    }
    
    func serializeBranches(indentation:String)->String{
        if branches.count == 1  {
            return "."+branches[0].serialize(indentation)
        } else if tokenGenerator {
            if let token = tokenGenerator?(state: self,capturedCharacteres: "",charactersStartIndex:0){
                return "->"+token.name
            }
        } else if branches.count == 0 {
            return ""
        }
        
        
        var output = ".{"
        var first = true
        for branch in branches {
            if !first {
                output+=","
            } else {
                first = false
            }
            output+="\n"
            output+=indentation+branch.serialize(indentation)
        }
        return output+"}\n"
    }
    
    func serialize(indentation:String)->String{
        var output = "{"+serializeStateArray(indentation+"\t",states: branches)+"}"
        
        if branches.count > 1 {
            output+="\n"
        }
        
        return output
    }
    
    func selfSatisfiedBranchOutOfStateTransition(consumedCharacter:Bool, controller:TokenizationController, withToken:Token?)->TokenizationStateChange{
        emitToken(controller, token: withToken)

        if branches.count == 0 {
            return TokenizationStateChange.Exit(consumedCharacter: consumedCharacter)
        } else {
            var transientState = Branch(states: self.branches)
            
            //If we can either enter the transient state or we did consume the character
            if transientState.couldEnterWithCharacter(controller.currentCharacter(),controller: controller) || consumedCharacter{
                return TokenizationStateChange.Transition(newState: transientState, consumedCharacter: consumedCharacter)
            }

            return TokenizationStateChange.Exit(consumedCharacter: consumedCharacter)
        }
    }
    
    func errorToken(controller:TokenizationController) -> Token{
        return Token.ErrorToken(forString: controller.describeCaptureState(), problemDescription: "Illegal character")
    }
    
    
    func createToken(controller:TokenizationController, useCurrentCharacter:Bool)->Token?{
        var useCharacters = useCurrentCharacter ? controller.capturedCharacters()+"\(controller.currentCharacter())" : controller.capturedCharacters()
        if let token = tokenGenerator?(state:self, capturedCharacteres:useCharacters,charactersStartIndex:controller.storedCharactersStartIndex){
            return token
        }
        
        return nil
    }
    
    func emitToken(controller:TokenizationController,token:Token?){
        if let emittableToken = token {
            controller.holdToken(emittableToken)
        }
    }
    
    var description:String {
        return serialize("")
    }
}
