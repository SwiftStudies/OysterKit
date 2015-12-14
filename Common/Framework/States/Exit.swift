//
//  Exit.swift
//  OysterKit Mac
//
//  Created by Nigel Hughes on 14/07/2014.
//  Copyright (c) 2014 RED When Excited Limited. All rights reserved.
//

import Foundation

public class Exit : TokenizationState {
    
    public override init(){
        super.init()
    }
    
    override func serialize(indentation: String) -> String {
        return "^"+pseudoTokenNameSuffix()
    }
    
    public override func scan(operation: TokenizeOperation) {
        operation.debug("Entered Exit")
        
        emitToken(operation)
    }
}