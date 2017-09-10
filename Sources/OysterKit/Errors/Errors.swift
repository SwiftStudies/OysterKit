//
//  Errors.swift
//  OysterKit
//
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

public enum GrammarError : Error, CustomStringConvertible{
    case notImplemented
    case noTokenCreatedFromMatch
    case matchFailed(token:Token?)
    
    public var description: String{
        switch self {
        case .notImplemented:
            return "Operation not implemented"
        case .noTokenCreatedFromMatch:
            return "No token created from a match"
        case .matchFailed:
            return "Match failed"
        }
    }
}
