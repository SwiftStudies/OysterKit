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

public class Repeat : TokenizationState{
    var minimumRepeats = 1
    var maximumRepeats : Int?
    var repeatingState:TokenizationState
    
    override func stateClassName()->String {
        return "Repeat"
    }
    
    
    public init(state:TokenizationState, min:Int=1,max:Int? = nil){
        self.minimumRepeats = min
        self.maximumRepeats = max
        self.repeatingState = state

        //Initialise super class
        super.init()        
    }
    
    override func flatten() -> TokenizationState {
        let flattenedRepeatingState = repeatingState.flatten()
        
        if flattenedRepeatingState === self {
            return self
        } else {
            let flattenedCopy = Repeat(state: flattenedRepeatingState, min: minimumRepeats, max: maximumRepeats)
            
            flattenedCopy.branches = branches
            flattenedCopy.tokenGenerator = tokenGenerator
            
            return flattenedCopy
        }
    }
    
    func fallThroughToBranches(operation:TokenizeOperation, repeats:Int){
        operation.debug("Exiting Repeat with \(repeats) repititions, before pop")
        operation.popContext(false)
        operation.debug("Exiting Repeat, after pop")
        
        //Did we get enough repeats?
        if repeats < minimumRepeats{
            return
        }
        
        if operation.context.currentPosition > operation.context.startPosition {
            emitToken(operation)
        }
        scanBranches(operation)
    }
    
    public override func scan(operation: TokenizeOperation) {
        operation.debug("Entered Repeat (\(minimumRepeats).."+(maximumRepeats != nil ? ", \(maximumRepeats))" : ")"))
        
        //Create a new context to capture any tokens, we don't want to fall back though, so will pop it off
        //before returning
        operation.pushContext([])
        var repeats = 0
        
        var tokensCreated = false
        
        repeat {
            tokensCreated = false
            
            operation.debug("Before repeat scan")
            repeatingState.scan(operation)
            operation.debug("After repeat scan")
            
            if operation.context.tokens.count > 0 {
                repeats++
                tokensCreated = true
                
                operation.debug("Repeating state created token, about to clear")
                operation.context.tokens.removeAll(keepCapacity: true)
                operation.debug("Cleared")
        
                //If we have hit the limit, then exit
                if maximumRepeats != nil && repeats == maximumRepeats {
                    fallThroughToBranches(operation, repeats: repeats)
                    return
                }
            }
        } while tokensCreated
        
        //Done
        fallThroughToBranches(operation, repeats: repeats)
    }
    
    override func serialize(indentation: String) -> String {

        var output = ""

        output+="("+repeatingState.serialize(indentation+"\t")
        
        if minimumRepeats != 1 || maximumRepeats != nil {
            output+=",\(minimumRepeats)"
            if (maximumRepeats != nil) {
                output+=",\(maximumRepeats)"
            }
        }
        
        output+=")"
        
        return output+serializeBranches(indentation+"\t")
    }
        
    override public func clone()->TokenizationState {
        let newState = Repeat(state: repeatingState.clone(), min: minimumRepeats, max: maximumRepeats)
        newState.__copyProperities(self)

        return newState
    }
}