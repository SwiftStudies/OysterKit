//
//  SwiftTypeExtensions.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

public extension String {
    @available(*, deprecated,message: "This function has been depricated and will be removed in version 1.0")
    func until(token:Token, annotations:RuleAnnotations? = nil)->Rule{
        return ParserRule.terminalUntil(produces: token, self, annotations)
    }
    
    @available(*, deprecated,message: "Replace with .token(token, from: .one)[.annotatedWith(annotations)]")
    func terminal(token:Token, annotations:RuleAnnotations? = nil)->Rule{
        return ParserRule.terminal(produces: token, self, annotations)
    }
    
    @available(*, deprecated,message: "Replace with .skip(.one)[.annotatedWith(annotations)]")
    func consume(annotations:RuleAnnotations?=nil)->Rule {
        return terminal(token: ConsumedToken.skip).consume(annotations: annotations)
    }

}

public extension CharacterSet {
    
    @available(*, deprecated,message: "This function has been depricated and will be removed in version 1.0")
    func until(token:Token, annotations:RuleAnnotations? = nil)->Rule{
        return ParserRule.terminalUntilOneOf(produces: token, self, annotations)
    }
    
    @available(*, deprecated,message: "Replace with .token(token, from: .one)[.annotatedWith(annotations)]")
    func terminal(token:Token, annotations:RuleAnnotations? = nil)->Rule{
        return ParserRule.terminalFrom(produces: token, self, annotations)
    }
    
    @available(*, deprecated,message: "Replace with .skip(.one)[.annotatedWith(annotations)]")
    func consume(greedily greedy:Bool, annotations:RuleAnnotations? = nil)->Rule{
        if greedy {
            return terminal(token: ConsumedToken.skip).repeated(min: 1).consume(annotations: annotations)
        } else {
            return terminal(token: ConsumedToken.skip).consume(annotations: annotations)
        }
    }
    
}

