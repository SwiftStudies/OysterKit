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
            if let constructionError = error as? AbstractSyntaxTreeConstructor.ConstructionError {
                switch constructionError {
                case .constructionFailed(let errors), .parsingFailed(let errors):
                    for error in errors{
                        if let rangedError = error as? HumanConsumableError {
                            let reference = TextFileReference(of: rangedError.range, in: source)
                            print(reference.report(rangedError.message,file:file))
                        } else {
                            print("\(error)")
                        }
                    }
                case .unknownError(let message):
                    print("Unknown error: \(message)")
                }
            } else if let humanReadable = error as? HumanConsumableError {
                print(humanReadable.formattedErrorMessage(in: source))
            } else {
                print("\(error)")
            }
        }
    }
}
