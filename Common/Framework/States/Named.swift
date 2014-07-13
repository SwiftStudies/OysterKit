//
//  Named.swift
//  OysterKit Mac
//
//  Created by Nigel Hughes on 11/07/2014.
//  Copyright (c) 2014 RED When Excited Limited. All rights reserved.
//

import Foundation

class Named : TokenizationState {
    let name:String
    let rootState:TokenizationState
    var endState:TokenizationState
    
    init(name:String,root:TokenizationState){
        self.rootState = root
        self.endState = root
        self.name = name
        super.init()
    }
    
    override func stateClassName() -> String {
        return "Named"
    }
    
    override func token(with: TokenCreationBlock) -> TokenizationState {
        endState.token(with)
        return self
    }
    
    func append(nextState:TokenizationState){
        endState.branch(nextState)
        endState = nextState
    }

    override func couldEnterWithCharacter(character: UnicodeScalar, controller: TokenizationController) -> Bool {
        return rootState.couldEnterWithCharacter( character, controller: controller)
    }
    
    override func consume(character: UnicodeScalar, controller: TokenizationController) -> TokenizationStateChange {
        return rootState.consume(character, controller: controller)
    }
    
    override func serialize(indentation: String) -> String {
        //TODO: This should also check for additional branches on the end state
        return name+endState.pseudoTokenNameSuffix()
    }
    
    override var branches:[TokenizationState]{
        get{
            return endState.branches
        }
        set(newValue){
            endState.branches = newValue
        }
    }
    
    override func clone()->TokenizationState {
        //Create a "new" named state with the root set as a clone of our root
        var newState = Named(name:name,root: rootState.clone())
        
        newState.endState = newState.rootState.lowBranch()
        
        newState.__copyProperities(self)
        return newState
    }
}

extension TokenizationState {
    
    func lowBranch()-> TokenizationState{
        var traceState = self
        
        while traceState.branches.count > 0 {
            traceState = traceState.branches[traceState.branches.endIndex-1]
        }
        
        return traceState
    }
    
}