//
//  LoopingChar.swift
//  OysterKit Mac
//
//  Created by Nigel Hughes on 09/07/2014.
//  Copyright (c) 2014 RED When Excited Limited. All rights reserved.
//

import Foundation

public class LoopingCharacters : Characters {
    
    public override init(except: String) {
        super.init(except: except)
    }
    
    public override init(from: String) {
        super.init(from:from)
    }
    
    override func stateClassName()->String {
        return "LoopingChar \(allowedCharacters)"
    }
    
    override func annotations() -> String {
        return "*"+super.annotations()
    }

    override public func clone() -> TokenizationState {
        let newState = LoopingCharacters(from: "\(allowedCharacters)")
        
        newState.__copyProperities(self)
        
        return newState
    }
    
    public override func scan(operation: TokenizeOperation){
        operation.debug("Entered "+(inverted ? "!" : "")+"LoopingChar '\(allowedCharacters)'")
        
        if isAllowed(operation.current) {
            //Scan through as much as we can
            repeat {
                operation.advance()
            } while !operation.complete && isAllowed(operation.current)
            
            
            //Emit a token, branch on
            emitToken(operation)
            

            
            scanBranches(operation)
            
            if operation.complete {
                return
            }
        }
    }
}