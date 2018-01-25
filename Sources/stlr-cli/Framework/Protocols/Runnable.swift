//
//  Runnable.swift
//  CommandKitPackageDescription
//
//  Created by Sean Alling on 11/8/17.
//

import Foundation

public enum RunnableReturnValue {
    case success
    case failure(error:Error, code:Int)
    
    var error   : Error? {
        switch self {
        case .failure(let error,_):
            return error
        default:
            return nil
        }
        
    }
    
    var code : Int {
        switch self {
        case .failure(_, let code):
            return code
        default:
            return 0
        }
    }
    
    var failed : Bool {
        return error != nil
    }
    
    var succeeded : Bool {
        return !failed
    }
}


/**
     An object that supports the concept of "running"
 */
public protocol Runnable{
    func run()->RunnableReturnValue
}

