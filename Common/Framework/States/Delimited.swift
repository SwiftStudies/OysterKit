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

public class Delimited : TokenizationState{
    
    class PoppingChar : Characters {
        
        override func scan(operation: TokenizeOperation) {
            //If it is the delimiter character, pop the state and emit our token (if any)
            if isAllowed(operation.current) {
                operation.popContext(true)
                operation.context.flushConsumedCharacters()
                operation.advance()
                emitToken(operation) //Will not emit something if it has not been told to, need to propagate the token generator (or make sure it has been)
            }
        }
        
    }
    
    override func stateClassName()->String {
        return "Delimited"
    }
 
    
    let openingDelimiter:Character
    
    var delimetedStates:Array<TokenizationState>
    let poppingState:PoppingChar

    public init(open:String,close:String,states:TokenizationState...){
        self.openingDelimiter = open[open.startIndex]
        self.delimetedStates = states
        self.poppingState = PoppingChar(from: close)
        
        //Initialise super class
        super.init()
        
        //TODO: Change this to a popping char state so that we don't have to keep
        //forcing this state to be re-entrant (and more complex as a result). 
        //The Char state should use the same token generator as this state, be placed
        //first in the list, and Pop the tokenizer state when exited
        //
        // BE CERTAIN THAT THE INITIALISER BELOW IS UPDATED AS WELL
        //
        preparePoppingState()
    }

    override func flatten() -> TokenizationState {
        
        for i in 0..<delimetedStates.count {
            delimetedStates[i] = delimetedStates[i].flatten()
        }
        
        flattenBranches()
        
        return self
    }

    public init(delimiter:String,states:TokenizationState...){
        self.openingDelimiter = delimiter[delimiter.startIndex]
        self.delimetedStates = states
        self.poppingState = PoppingChar(from:delimiter)
        
        //Initialise super class
        super.init()
        preparePoppingState()
    }
    
    //
    // Popping state setup and maintenance
    //
    func preparePoppingState() {
        delimetedStates.insert(poppingState, atIndex: 0)
    }
    
    
    public override func scan(operation: TokenizeOperation) {
        operation.debug("Entered \(openingDelimiter)Delimited\(poppingState.allowedCharacters)")
        if openingDelimiter != operation.current {
            return
        }
        
        //Consume delimiter and emit any token
        operation.advance()
        emitToken(operation)
        
        //Put the new context in place, and we are done
        operation.pushContext(delimetedStates)
    }
    
    //
    // Assigned token propagation
    //
    public override func token(with: TokenCreationBlock) -> TokenizationState {
        super.token(with)
        poppingState.token(with)
        return self
    }
    
    //
    // Serialization
    //
    func escapeDelimiter(delimiter:Character)->String {
        if delimiter == "'" {
            return "\\'"
        }
        return "\(delimiter)"
    }
    
    override func serialize(indentation: String) -> String {

        var output = ""
        
        output+="<'\(escapeDelimiter(openingDelimiter))',"
        
        let opening = "\(openingDelimiter)"
        let allowed = "\(poppingState.allowedCharacters)"

        if opening != allowed {
            output+="'\(poppingState.allowedCharacters)',"
        }
        
        output += "{"

        let subStates = Array(delimetedStates[1..<self.delimetedStates.endIndex])
        output += serializeStateArray(indentation+"\t", states: subStates)
        
        output+="}"
        
        return output+">"+serializeBranches(indentation+"\t")
    }

    override public func clone() -> TokenizationState {
        let newState = Delimited(open: "\(openingDelimiter)", close: "\(poppingState.allowedCharacters)")
        
        for _ in delimetedStates {
            //Woo-hoo correct array semantics!
            newState.delimetedStates=delimetedStates
        }
        
        newState.__copyProperities(self)
        
        return newState
    }
}