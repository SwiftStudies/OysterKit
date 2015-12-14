//
//  Named.swift
//  OysterKit Mac
//
//  Created by Nigel Hughes on 11/07/2014.
//  Copyright (c) 2014 RED When Excited Limited. All rights reserved.
//

import Foundation

public class Named : TokenizationState {
    let name:String
    let rootState:TokenizationState
    var endState:TokenizationState
    var cloneTimeEnd:TokenizationState?
    
    public init(name:String,root:TokenizationState){
        self.rootState = root
        self.endState = root
        self.name = name
        super.init()
    }
    
    override func stateClassName() -> String {
        return "Named"
    }
    
    public override func token(with: TokenCreationBlock) -> TokenizationState {
        endState.token(with)
        return self
    }
    
    public override func branch(toStates: [TokenizationState])->TokenizationState{
        endState.branch(toStates)
        endState = toStates[toStates.endIndex-1]
        
        return endState
    }
    
    override func serialize(indentation: String) -> String {
        if let originalEnd:TokenizationState = cloneTimeEnd {
            return name+originalEnd.pseudoTokenNameSuffix()+originalEnd.serializeBranches(indentation)
        } else {
            return name+endState.pseudoTokenNameSuffix()
        }
    }
    
    override var branches:[TokenizationState]{
        get{
            return endState.branches
        }
        set(newValue){
            endState.branches = newValue
        }
    }
    
    override public func clone()->TokenizationState {
        //Create a "new" named state with the root set as a clone of our root
        let newState = Named(name:name,root: rootState.clone())
        
//        println(self.rootState.description)
//        println(newState.rootState.description)
        
        newState.endState = newState.rootState.lowLeaf()
        newState.cloneTimeEnd = endState

        newState.__copyProperities(self)
        return newState
    }
    
    public override func scan(operation: TokenizeOperation) {
        operation.debug("Entered Named "+name)
        
        rootState.scan(operation)
    }
}

extension TokenizationState {
    
    func lowLeaf()-> TokenizationState{
        var traceState = self
        
        while traceState.branches.count > 0 {
            traceState = traceState.branches[traceState.branches.endIndex-1]
        }
        
        return traceState
    }
    
}