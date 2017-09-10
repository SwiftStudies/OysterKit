//
//  ForkedIR.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

public class ForwardingIR<BaseIR:IntermediateRepresentation> : IntermediateRepresentation {
    public var primary   : BaseIR
    public var secondary : IntermediateRepresentation
    
    public required init() {
        fatalError("Forwarding IR requires that a secondary IR is supplied pre-initialized and then used with build(intermediateRepresentation:lexer:)")
    }
    
    public init(secondary:IntermediateRepresentation){
        self.primary   = BaseIR()
        self.secondary = secondary
    }
    
    public init(primary: BaseIR, secondary:IntermediateRepresentation){
        self.primary = primary
        self.secondary = secondary
    }
    
    
    public func willBuildFrom(source: String, with: Language) {
        primary.willBuildFrom(source: source, with: with)
        secondary.willBuildFrom(source: source, with: with)
    }
    
    public func resetState() {
        primary.resetState()
        secondary.resetState()
    }
    
    public func willEvaluate(rule: Rule, at position: String.UnicodeScalarView.Index) -> MatchResult? {
        let primaryHasCache = primary.willEvaluate(rule: rule, at: position)
        let _ = secondary.willEvaluate(rule: rule, at: position)
        
        if let primaryHasCache = primaryHasCache {
            secondary.didEvaluate(rule: rule, matchResult: primaryHasCache)
            
            return primaryHasCache
        }
        
        return nil
    }
    
    public func didEvaluate(rule: Rule, matchResult: MatchResult) {
        primary.didEvaluate(rule: rule, matchResult: matchResult)
        secondary.didEvaluate(rule: rule, matchResult: matchResult)
    }

    public func didBuild() {
        primary.didBuild()
        secondary.didBuild()
    }

}
