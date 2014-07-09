//
//  Loop.swift
//  OysterKit Mac
//
//  Created by Nigel Hughes on 09/07/2014.
//  Copyright (c) 2014 RED When Excited Limited. All rights reserved.
//

import Foundation

class __Loop : Branch {
    class Popping : TokenizationState {
        var cachingState : Caching?
        var parentState: TokenizationState?
        
        override func couldEnterWithCharacter(character: UnicodeScalar, controller: TokenizationController) -> Bool {
            return true
        }
        
        override func consume(character: UnicodeScalar, controller: TokenizationController) -> TokenizationStateChange {
            controller.pop()
            if let cachedState = cachingState {
//                println("Using cached state \(cachedState.observedCharacters)")
                tokenGenerator?(state: parentState!,capturedCharacteres: cachedState.observedCharacters,charactersStartIndex: cachedState.startIndex)
            }
            return TokenizationStateChange.Exit(consumedCharacter: false)
        }
    }
    
    class Caching : TokenizationState {
        var observedCharacters = ""
        var startIndex = 0
        
        override func couldEnterWithCharacter(character: UnicodeScalar, controller: TokenizationController) -> Bool {
//            println("Caught: \(character)")
            observedCharacters+="\(character)"
            return false
        }
    }
    
    var loopedStates:Array<TokenizationState>
    var loopedStatesWithExit:Array<TokenizationState>
    
    let poppingState:Popping
    let catchingState:Caching
    
    init(state:TokenizationState){
        self.loopedStates = state.loopingStates()
        self.loopedStatesWithExit = self.loopedStates
        self.poppingState = Popping()
        self.catchingState = Caching()
        
        //Initialise super class
        super.init()

        self.loopedStatesWithExit.append(poppingState)
    }
    
    
    override func token(with: TokenCreationBlock) -> TokenizationState {
        super.token(with)
        poppingState.tokenGenerator = tokenGenerator
        
        //Only set the caching state once
        if loopedStatesWithExit[0] is Caching {
            return self
        }
        poppingState.parentState = self
        poppingState.cachingState = catchingState
        loopedStatesWithExit.insert(catchingState, atIndex: 0)
        return self
    }
    
    //
    // State management
    //
    
    override func couldEnterWithCharacter(character: UnicodeScalar, controller: TokenizationController) -> Bool {
        for state in loopedStates {
            if state.couldEnterWithCharacter(character, controller: controller){
                return true
            }
        }
        
        return false
    }
    
    override func consume(character: UnicodeScalar, controller: TokenizationController) -> TokenizationStateChange {
        catchingState.observedCharacters = ""
        catchingState.startIndex = controller.currentElementIndex
        controller.push(self.loopedStatesWithExit)
        return TokenizationStateChange.Exit(consumedCharacter: false)
    }
    
    //
    // Serialization
    //
    override func serialize(indentation: String) -> String {
        if loopedStates.count == 1 {
            return "\(indentation)*\(loopedStates[0].serialize(indentation))"
        }
        
        var output = "\(indentation)*{"
        
        output += serializeStateArray(indentation+"\t", states: loopedStates)
        
        output+="}"
        
        return output+"}"+serializeBranches(indentation+"\t")
    }
    
}