//
//  DebuggingDelegate.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

public class DebuggingDelegate : IntermediateRepresentation{
    private var depth = 0
    
    public required init() {
    }
    
    func debugMessage(message:String, indent:Int){
        let message = String(repeating: "\t", count: indent-1)+message
        print(message)
    }
    
    public func willBuildFrom(source: String, with: Language) {
        depth = 1
    }
    
    public func didBuild() {
    }
    
    public func willEvaluate(rule: Rule, at position: String.UnicodeScalarView.Index) -> MatchResult? {
        debugMessage(message: "ℹ️ \(rule.produces)", indent: depth)
        depth += 1
        return nil
    }
    
    public func didEvaluate(rule: Rule, matchResult: MatchResult) {
        depth -= 1
        switch matchResult{
        case .success(_):
            debugMessage(message: "✅ \(rule.produces) matched", indent: depth)
        case .failure:
            debugMessage(message: "⁉️ \(rule.produces)", indent: depth)
        case .ignoreFailure:
            debugMessage(message: "⚠️ \(rule.produces), but failure is ignorable", indent: depth)
        case .consume:
            debugMessage(message: "✅ \(rule.produces) consumed", indent: depth)
        }
    }
    
    public func resetState() {
        
    }
}
