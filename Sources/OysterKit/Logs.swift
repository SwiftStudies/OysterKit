//
//  Logs.swift
//  OysterKit
//
//  Created on 18/06/2018.
//

import Foundation

#if canImport(os)
import os.log
import os.signpost

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
    
    static func endRule(rule:Rule){
        guard parsingLog.signpostsEnabled else {
            return
        }
        let oldId = signPostIdStack.removeLast()
        
        os_signpost(type: .end, log: parsingLog, name: "matches", signpostID: oldId, "${public}@", "\(rule)" as NSString)
    }
}
#endif
