//
//  SwiftTypeExtensions.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

public extension String {
    func until(token:Token, annotations:RuleAnnotations? = nil)->Rule{
        return ParserRule.terminalUntil(produces: token, self, annotations)
    }
    
    func terminal(token:Token, annotations:RuleAnnotations? = nil)->Rule{
        return ParserRule.terminal(produces: token, self, annotations)
    }
    
    func consume(annotations:RuleAnnotations?=nil)->Rule {
        return terminal(token: ConsumedToken.skip).consume(annotations: annotations)
    }
    
    func  dynamicRule(token:Token)->Rule? {
        let grammarDef = "_ = \(self)"
        
        let compiler = STLRParser(source: grammarDef)
        
        let ast = compiler.ast 
        
        guard ast.rules.count > 0 else {
            return nil
        }
        
        
        return ast.rules[0].rule(from: ast, creating: token)
    }
}

public extension CharacterSet {
    

    
    func until(token:Token, annotations:RuleAnnotations? = nil)->Rule{
        return ParserRule.terminalUntilOneOf(produces: token, self, annotations)
    }
    
    func terminal(token:Token, annotations:RuleAnnotations? = nil)->Rule{
        return ParserRule.terminalFrom(produces: token, self, annotations)
    }
    
    func consume(greedily greedy:Bool, annotations:RuleAnnotations? = nil)->Rule{
        if greedy {
            return terminal(token: ConsumedToken.skip).repeated(min: 1).consume(annotations: annotations)
        } else {
            return terminal(token: ConsumedToken.skip).consume(annotations: annotations)
        }
    }
    
}

