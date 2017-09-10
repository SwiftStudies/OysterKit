//
//  RuleExtensions.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation



public extension Rule {
    
    func consume(annotations:RuleAnnotations?=nil)->Rule{
        return ParserRule.consume(self, annotations)
    }
    
    func lookahead(annotations:RuleAnnotations?=nil)->Rule{
        return ParserRule.lookahead(self, annotations)
    }

    
    func optional(annotations:RuleAnnotations?=nil)->Rule {
        return ParserRule.optional(produces: produces, self,annotations)
    }
    
    func not(annotations:RuleAnnotations?=nil)->Rule {
        return ParserRule.not(produces: produces, self,annotations)
    }
    
    func not(producing token:Token, annotations:RuleAnnotations?=nil)->Rule{
        return ParserRule.not(produces: token, self,annotations)
    }
    
    
    func repeated(min:Int = 1, limit:Int? = nil, producing token:Token?  = nil, annotations:RuleAnnotations?=nil)->Rule{
        return ParserRule.repeated(produces: token ?? produces, self, min: min, limit: limit, annotations)
    }
    
    func optional(producing token:Token,annotations:RuleAnnotations?=nil)->Rule{
        return ParserRule.optional(produces: token, self,annotations)
    }
}

public extension Collection where Self.Iterator.Element == Rule {
    func sequence(token:Token,annotations:RuleAnnotations?=nil)->Rule{
        return ParserRule.sequence(produces: token, [Rule](self), annotations)
    }
    
    func oneOf(token:Token,annotations:RuleAnnotations?=nil)->Rule{
        return ParserRule.oneOf(produces: token, [Rule](self), annotations)
    }
    
}

