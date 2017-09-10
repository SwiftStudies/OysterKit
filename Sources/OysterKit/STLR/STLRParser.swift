//
//  STLRParser.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

public class STLRParser : Parser{
    public var ast    : STLRIntermediateRepresentation
    
    public init(source:String){
        ast = STLRIntermediateRepresentation()

        super.init(grammar: STLR.generatedLanguage.grammar)
        
        //We don't need the resultant tree
        let _ = build(intermediateRepresentation: HeterogenousAST<HeterogeneousNode,STLRIntermediateRepresentation>(constructor: ast), using: Lexer(source: source))
                
        ast.optimize()
    }
    
    var errors : [Error] {
        return ast.errors
    }
    
    
    public var compiled : Bool {
        return ast.rules.count > 0
    }
}
