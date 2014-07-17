//
//  Exit.swift
//  OysterKit Mac
//
//  Created by Nigel Hughes on 14/07/2014.
//  Copyright (c) 2014 RED When Excited Limited. All rights reserved.
//

import Foundation

class Exit : TokenizationState {
        
    override func serialize(indentation: String) -> String {
        return "^"+pseudoTokenNameSuffix()
    }
    
    override func scan(operation: TokenizeOperation) {
        operation.debug(operation: "Entered Exit")
        
        emitToken(operation)
    }
}