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
        operation.debug(operation: "Entered Keywords \(validStrings)")

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