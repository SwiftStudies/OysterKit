//
//  LoopingChar.swift
//  OysterKit Mac
//
//  Created by Nigel Hughes on 09/07/2014.
//  Copyright (c) 2014 RED When Excited Limited. All rights reserved.
//

import Foundation

class LoopingChar : Char {
    override func stateClassName()->String {
        return "LoopingChar \(allowedCharacters)"
    }
    
    override func consume(character: UnicodeScalar, controller: TokenizationController) -> TokenizationStateChange {
        if isAllowed(character){
            return TokenizationStateChange.None
        } else {
            return selfSatisfiedBranchOutOfStateTransition(false, controller: controller, withToken: createToken(controller, useCurrentCharacter: false))
        }
    }
    
    override func annotations() -> String {
        return "*"+super.annotations()
    }

    override func clone() -> TokenizationState {
        var newState = LoopingChar(from: allowedCharacters)
        
        newState.__copyProperities(self)
        
        return newState
    }
    
    
}