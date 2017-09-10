//
//  STLR Optimization.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

public extension STLRIntermediateRepresentation{
    public func optimize(){
        
        func rulesAreEqual(rule1:STLRIntermediateRepresentation.GrammarRule, rule2:STLRIntermediateRepresentation.GrammarRule)->Bool{
            guard let id1 = rule1.identifier?.name, let id2 = rule2.identifier?.name else {
                return true
            }
            return id1 == id2
        }
        
        let originalRootRules = rootRules
        
        for rule in rules{
            if let optimizedExpression = rule.expression?.optimize {
                rule.expression = nil
                rule.expression = optimizedExpression
            }
        }
        
        let newRootRules = rootRules
        
        let unusedRules = newRootRules.filter(){ (newRootRule) in
            !originalRootRules.contains(where: { (originalRootRule) in
                rulesAreEqual(rule1: newRootRule, rule2: originalRootRule)
            })
        }
        
        rules = rules.filter({ (rule) in
            !unusedRules.contains(){ (unused) in
                rulesAreEqual(rule1: unused, rule2: rule)
            }
        })
    }
    
}
