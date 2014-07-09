//
//  LoopingChar.swift
//  OysterKit Mac
//
//  Created by Nigel Hughes on 09/07/2014.
//  Copyright (c) 2014 RED When Excited Limited. All rights reserved.
//

import Foundation

class LoopingChar : Char {
    
    override func consume(character: UnicodeScalar, controller: TokenizationController) -> TokenizationStateChange {
        if isAllowed(character){
            return TokenizationStateChange.None
        } else {
            return selfSatisfiedBranchOutOfStateTransition(false, controller: controller, withToken: createToken(controller, useCurrentCharacter: false))
        }
    }
}