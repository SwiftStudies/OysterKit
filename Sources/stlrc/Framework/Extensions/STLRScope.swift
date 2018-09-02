//
//  STLRScope.swift
//  stlrc
//
//  Created on 18/06/2018.
//

import Foundation
import STLR
import OysterKit

extension Array where Element == Error {
    func report(in source:String, from file:String? = nil){
        for error in self {
            if let processingError = error as? ProcessingError {
                print(processingError.message)
                for cause in processingError.causedBy ?? [] {
                    if let cause = cause as? CausalErrorType, let range = cause.range {
                        let reference = TextFileReference(of: range.lowerBound..<range.upperBound, in: source)
                        print(reference.report(cause.message,file:file))
                    } else {
                        print("\(cause)")
                    }
                }
            } else {
                print("\(error)")
            }
        }
    }
}
