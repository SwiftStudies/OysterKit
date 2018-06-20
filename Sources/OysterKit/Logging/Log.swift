//
//  Logs.swift
//  OysterKit
//
//  Created on 18/06/2018.
//

import Foundation

#if canImport(NaturalLanguage)
import os

@available(OSX 10.14, *)
public enum Log {
    
    case parsing, decoding
    
    public static let _parsingLog   = OSLog(subsystem: "com.swift-studies.OysterKit", category: "parsing")
    public static let _decodingLog  = OSLog(subsystem: "com.swift-studies.OysterKit", category: "decoding")
    
    public static var parsingLog        : OSLog = .disabled
    public static var decodingLog       : OSLog = _decodingLog
    
    public func enable(){
        switch self {
        case .parsing:
            Log.parsingLog = Log._parsingLog
            Log.signPostIdStack.removeAll(keepingCapacity: true)
        case .decoding:
            Log.decodingLog = Log._decodingLog
        }
    }
    
    public func disable(){
        switch self {
        case .parsing: Log.parsingLog = .disabled
        case .decoding: Log.decodingLog = .disabled
        }
    }
    
    private static var signPostIdStack = [OSSignpostID]()
    static func decodingError(_ error:DecodingError){
        guard decodingLog.isEnabled(type: .default) else{
            return
        }
        os_log("%{public}@", Log.formatted(decodingError: error))
    }
    
    private static func describe(rule:Rule)->String{
        if rule.produces.transient {
            return "\(rule)"
        }
        return "\(rule.produces)"
    }
    
    static func beginRule(rule:Rule){
        guard parsingLog.signpostsEnabled else {
            return
        }
        let newId = OSSignpostID(log: parsingLog)
        signPostIdStack.append(newId)
        
        os_signpost(type: .begin, log: parsingLog, name: "matches", signpostID: newId, "%{public}@", "\(describe(rule: rule))" as NSString)
    }
    
    static func endRule(rule:Rule, result:MatchResult){
        guard parsingLog.signpostsEnabled else {
            return
        }
        let oldId = signPostIdStack.removeLast()
        
        let resultDescription : String
        switch result {
        case .success( _):
            resultDescription = "✅"
        case .consume( _):
            resultDescription = "👄"
        case .ignoreFailure( _):
            resultDescription = "❌"
        case .failure( _):
            resultDescription = "☠️"
        }
        
        os_signpost(type: .end, log: parsingLog, name: "matches", signpostID: oldId, "%{public}@ %{public}@", "\(describe(rule: rule))" as NSString, resultDescription as NSString)
    }
}
#endif
