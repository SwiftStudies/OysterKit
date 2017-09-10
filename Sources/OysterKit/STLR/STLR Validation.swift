//
//  STLR Validation.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

public extension STLRIntermediateRepresentation{
    public func validate() throws{
        enum ValidationError : Error {
            case didNotValidate
        }
        for rule in rules{
            do {
                try rule.validate()
            } catch (let error) {
                errors.append(error)
            }
        }
        for (_,identifier) in identifiers{
            if identifier.grammarRule == nil {
                errors.append(LanguageError.semanticError(at: identifier.references[0], referencing: nil, message: "\(identifier.name) is never defined"))
            }
        }
        
        if !errors.isEmpty{
            throw ValidationError.didNotValidate
        }
    }
    
    
    
    public func validate(parsingErrors: [Error]) -> [Error] {
        
        errors.append(contentsOf: parsingErrors)
        
        do{
            try validate()
        } catch {
            
        }
        
        return errors
    }

}
