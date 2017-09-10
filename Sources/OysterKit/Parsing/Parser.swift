//
//  Compiler.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

open class Parser : Language{
    public let grammar : [Rule]
    
    public init(grammar:[Rule]){
        self.grammar = grammar
    }
    
}
