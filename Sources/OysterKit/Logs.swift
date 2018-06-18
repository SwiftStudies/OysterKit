//
//  Logs.swift
//  OysterKit
//
//  Created on 18/06/2018.
//

import Foundation

#if canImport(os)
import os

@available(OSX 10.14, *)
public enum Logs {
    static var parsingLog = OSLog(subsystem: "com.swift-studies.OysterKit", category: "parsing")
    
    private static var signPostIdStack = [OSSignpostID]()
    
    static func beginRule(rule:Rule){
        guard parsingLog.signpostsEnabled else {
            return
        }
        let newId = OSSignpostID(log: parsingLog)
        signPostIdStack.append(newId)

        os_signpost(type: .begin, log: parsingLog, name: "matches", signpostID: newId, "%{public}@", "\(rule)" as NSString)
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
        
        os_signpost(type: .end, log: parsingLog, name: "matches", signpostID: oldId, "%{public}@ %{public}@", "\(rule)" as NSString, resultDescription as NSString)
    }
}
#endif
