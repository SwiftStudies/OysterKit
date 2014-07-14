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

var __anonymousStateCount:Int = 0

//
// XCode 6 Beta 3 Crashes if two protocols refer to each other, so turning this into a class for now
//
class TokenizationState : Printable, StringLiteralConvertible,Equatable {
    var tokenGenerator : TokenCreationBlock?
    var id : String = ""
    var reference : String?
    var branches = Array<TokenizationState>() //All states that can be transitioned to
    
    
    func stateClassName()-> String {
        return "TokenizationState"
    }
    
    init(){
        id = "\(stateClassName())\(__anonymousStateCount++)"
    }
    
    
    
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
    // Manage storage of branches
    //
    func branch(toStates: [TokenizationState]) -> TokenizationState {
        for state in toStates{
            branches.append(state)
        }
        
        return self
    }

    func branch(toStates: TokenizationState...) -> TokenizationState {
        return branch(toStates)
    }


    
    //
    // As this method only calls branch, we can provide a concrete implementation here
    //
    func sequence(ofStates: TokenizationState...) -> TokenizationState {
        sequence(ofStates)
        
        return self        
    }
    
    func sequence(ofStates:[TokenizationState]){
        branch(ofStates[0])
        for index in 1..<ofStates.count{
            ofStates[index-1].branch(ofStates[index])
        }
    }

    func loopingStates()->[TokenizationState]{
        return [self]
    }
    
    //
    // Token creation
    //
    func token(emitToken: String) -> TokenizationState {
        token(){(state:TokenizationState, capturedCharacters:String, startIndex:Int)->Token in
            var token = Token(name: emitToken, withCharacters: capturedCharacters)
            token.originalStringIndex = startIndex
            return token
        }
        
        return self
    }
    
    func token(emitToken: Token) -> TokenizationState {
        token(){(state:TokenizationState, capturedCharacters:String, startIndex:Int)->Token in
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
    
    func clearToken()-> TokenizationState{
        tokenGenerator = nil
        return self
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
    
    //
    // Output
    //
    func pseudoTokenNameSuffix()->String{
        if let token = tokenGenerator?(state: self,capturedCharacteres: "",charactersStartIndex:0){
            return "->"+token.name
        }
        return ""
    }
    
    func serialize(indentation:String)->String{
        if reference {
           return reference!+pseudoTokenNameSuffix()
        }
        return ""
    }

    var description:String{
        return serialize("")
    }
    
    //
    // Object Life Cycle
    //
    func __copyProperities(from:TokenizationState){
        if from.tokenGenerator{
            token(from.tokenGenerator!)
        }

        for branch in from.branches {
            self.branch(branch.clone())
        }
        
        reference = from.reference
    }
    
    func clone()->TokenizationState {
        var newState = TokenizationState()
        newState.__copyProperities(self)
        return newState
    }
    
    @final func isEqualTo(otherState:TokenizationState)->Bool{
        return id == otherState.id
    }
}

func ==(lhs: TokenizationState, rhs: TokenizationState) -> Bool{
    return lhs.isEqualTo(rhs)
}

func ==(lhs:[TokenizationState], rhs:[TokenizationState])->Bool{
    if lhs.count != rhs.count {
        return false
    }
    
    for i in 0..<rhs.count {
        if lhs[i] != rhs[i] {
            return false
        }
    }
    
    return true
}

typealias   TokenCreationBlock = ((state:TokenizationState,capturedCharacteres:String,charactersStartIndex:Int)->Token)


