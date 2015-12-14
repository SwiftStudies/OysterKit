//
//  CharSequences.swift
//  OysterKit Mac
//
//  Created by Nigel Hughes on 09/07/2014.
//  Copyright (c) 2014 RED When Excited Limited. All rights reserved.
//

import Foundation

public class Keywords : TokenizationState {
    override func stateClassName()->String {
        return "Keywords"
    }
    
    let validStrings : [String]
    
    public init(validStrings:Array<String>){
        self.validStrings = validStrings
        super.init()
    }
    
    public override func scan(operation: TokenizeOperation) {
        operation.debug("Entered Keywords \(validStrings)")

        var didAdvance = false
        
        if completions(operation.context.consumedCharacters+"\(operation.current)") == nil {
            return
        }
        
        while let allCompletions = completions(operation.context.consumedCharacters+"\(operation.current)") {
            if allCompletions.count == 1 && allCompletions[0] == operation.context.consumedCharacters {
                //Pursue our branches
                emitToken(operation)
                
                scanBranches(operation)
                return
            } else {
                operation.advance()
                didAdvance = true
            }
        }
        
        if (didAdvance){
            scanBranches(operation)
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
    
    override public func clone() -> TokenizationState {
        let newState = Keywords(validStrings: validStrings)
        
        newState.__copyProperities(self)
        
        return newState
    }
}