//
//  STLROptimizers.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation


public protocol STLROptimizer : CustomStringConvertible{
    
}

public protocol STLRExpressionOptimizer : STLROptimizer{
    func optimize(expression:STLRIntermediateRepresentation.Expression)->STLRIntermediateRepresentation.Expression?
}

private var optmizers = [STLROptimizer]()

public extension STLRIntermediateRepresentation{
    public static func register(optimizer:STLROptimizer){
        optmizers.append(optimizer)
    }
    
    public static func removeAllOptimizations(){
        optmizers.removeAll()
    }
}

extension STLRIntermediateRepresentation.Expression{
    
    var optimize : STLRIntermediateRepresentation.Expression?{
        var optimizedForm : STLRIntermediateRepresentation.Expression?

        optmizers.flatMap({$0 as? STLRExpressionOptimizer}).forEach(){
            if let appliedOptimization = $0.optimize(expression: optimizedForm ?? self) {
                optimizedForm = appliedOptimization
            }
        }
        
        return optimizedForm
    }
    
}
