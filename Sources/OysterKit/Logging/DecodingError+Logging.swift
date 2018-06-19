//
//  DecodingError.swift
//  OysterKit
//
//  Created by Nigel Hughes on 19/06/2018.
//

import Foundation

@available(OSX 10.14, *)
extension Log {
    static func formatted(codingPath: [CodingKey])->String{
        return codingPath.reduce("") { (result, currentKey) -> String in
            var nextResult = result + (result.isEmpty ? "" : ".")
            if let index = currentKey.intValue {
                nextResult += "[\(index)]"
            } else {
                nextResult += currentKey.stringValue
            }
            
            return nextResult
        }
    }
    
    static func formatted(error:Error)->String{
        if let decoding = error as? DecodingError {
            return formatted(decodingError: decoding)
        }
        return error.localizedDescription
    }
    
    static func formatted(decodingError:DecodingError)->String{
        switch decodingError {
        case .dataCorrupted(let context):
            return "Corrupted data at \(formatted(codingPath: context.codingPath))" + (
                context.underlyingError == nil ? "." : " caused by \(formatted(error:context.underlyingError!))."
            )
        case .keyNotFound(let missingKey, let context):
            return "Key \(missingKey.stringValue) not found at \(formatted(codingPath: context.codingPath))" + (
                context.underlyingError == nil ? "." : " caused by \(formatted(error:context.underlyingError!))."
            )
        case .typeMismatch(let type, let context):
            return "Expected \(type) at \(formatted(codingPath: context.codingPath))" + (
                context.underlyingError == nil ? "." : " caused by \(formatted(error:context.underlyingError!))."
            )
        case .valueNotFound(let type, let context):
            return "No value for \(type) at \(formatted(codingPath: context.codingPath))" + (
                context.underlyingError == nil ? "." : " caused by \(formatted(error:context.underlyingError!))."
            )
        }

    }
}
