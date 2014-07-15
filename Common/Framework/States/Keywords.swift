//
//  CharSequences.swift
//  OysterKit Mac
//
//  Created by Nigel Hughes on 09/07/2014.
//  Copyright (c) 2014 RED When Excited Limited. All rights reserved.
//

import Foundation

class Keywords : Branch {
    override func stateClassName()->String {
        return "Keywords"
    }
    
    let validStrings : [String]
    
    init(validStrings:Array<String>){
        self.validStrings = validStrings
        super.init()
    }
    
    override func scan(operation: TokenizeOperation) {
        var didAdvance = false
        
        if !completions(operation.context.consumedCharacters+"\(operation.current)"){
            return
        }
        
        while let allCompletions = completions(operation.context.consumedCharacters) {
            if allCompletions.count == 1 && allCompletions[0] == operation.context.consumedCharacters {
                //Pursue our branches
                emitToken(operation)
                
                //Keywords don't consider their branches
                super.scan(operation)
                return
            } else {
                operation.advance()
                didAdvance = true
            }
        }
        
        if (didAdvance){
            super.scan(operation)
            return
        }
    }
    
    override func couldEnterWithCharacter(character: UnicodeScalar, controller: TokenizationController) -> Bool {
        let totalString = controller.capturedCharacters()+"\(character)"
        
        if completions(totalString){
            return true
        }
        
        return false
    }
    
    override func consume(character: UnicodeScalar, controller: TokenizationController) -> TokenizationStateChange {
        let totalString = controller.capturedCharacters()+"\(character)"
        
        if let allCompletions = completions(totalString) {
            if allCompletions.count == 1 && allCompletions[0] == totalString {
                return selfSatisfiedBranchOutOfStateTransition(true, controller: controller, withToken: createToken(controller, useCurrentCharacter: true))
            } else {
                return TokenizationStateChange.None
            }
        } else {
            //See if we can branch out, and perhaps one of our branches can deal with the other characters
            return selfSatisfiedBranchOutOfStateTransition(false, controller: controller, withToken: nil)
        }
    }
    
    func completions(string:String) -> Array<String>?{
        var allMatches = Array<String>()
        
        for validString in validStrings{
            if validString.hasPrefix(string){
                allMatches.append(validString)
            }
        }
        
        if allMatches.count == 0{
            return nil
        } else {
            return allMatches
        }
    }
    
    func completions(controller:TokenizationController) -> Array<String>? {
        return completions(controller.capturedCharacters())
    }
    
    override func serialize(indentation: String) -> String {
        
        var output = ""
        
        output+="["
        
        var first = true
        for keyword in validStrings {
            if !first {
                output+=","
            } else {
                first = false
            }
            output+="\"\(keyword)\""
        }
        
        output+="]"
        
        return output+serializeBranches(indentation+"\t")
    }
    
    override func clone() -> TokenizationState {
        var newState = Keywords(validStrings: validStrings)
        
        newState.__copyProperities(self)
        
        return newState
    }
}