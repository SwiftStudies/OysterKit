//
//  Language.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

public protocol HumanConsumableError {
    var message : String {get}
    var range : Range<String.UnicodeScalarView.Index> {get}
}

public enum LanguageError : Error, HumanConsumableError, CustomStringConvertible, Equatable {
    case scanningError(at: Range<String.UnicodeScalarView.Index>, message:String)
    case parsingError(at: Range<String.UnicodeScalarView.Index>, message:String)
    case semanticError(at: Range<String.UnicodeScalarView.Index>, referencing: Range<String.UnicodeScalarView.Index>?, message:String)
    case warning(at: Range<String.UnicodeScalarView.Index>, message:String)
    
    public var range : Range<String.UnicodeScalarView.Index> {
        switch self {
        case .parsingError(let range, _), .semanticError(let range, _, _), .scanningError(let range, _), .warning(let range, _):
            return range
        }
    }
    
    public var message : String {
        switch self {
        case .parsingError(_, let message), .semanticError(_, _, let message), .scanningError(_, let message), .warning(_, let message):
            return message
        }
    }
    
    public var description: String{
        switch self {
        case .parsingError(let range, let message), .semanticError(let range, _, let message), .scanningError(let range, let message), .warning(let range, let message):
            return "\(message) from \(range.lowerBound) to \(range.upperBound)"
        }
    }
    
    public static func ==(lhs:LanguageError, rhs:LanguageError)->Bool{
       return lhs.range == rhs.range && lhs.message == rhs.message
    }
}

public protocol Language{
    var  grammar : [Rule] {get}
}

public extension Array where Element == Rule {
    struct Wrapper : Language{
        public let grammar: [Rule]
    }
    
    public var language : Language {
        return Wrapper(grammar: self)
    }
    
}

public extension Language {
    public func build<IR:IntermediateRepresentation>(intermediateRepresentation ir:IR, using lexer:LexicalAnalyzer)->IR{
        let lexer = lexer
        var success : Bool
        
        var productionErrors = [Error]()
        
        ir.willBuildFrom(source: lexer.source, with: self)
        
        while !lexer.endOfInput {
            success = false
            productionErrors.removeAll()
            let positionBeforeParsing = lexer.index
            for rule in grammar {
                do {
                    let _ = try rule.match(with: lexer, for: ir)
                    success = true
                } catch (let error){
                    productionErrors.append(error)
                }
            }
            
            if lexer.index == positionBeforeParsing {
                productionErrors.append(LanguageError.parsingError(at: lexer.index..<lexer.index, message: "Lexer not advanced"))
                success = false
            }
            
            if !success {
                break
            } else {
                productionErrors.removeAll()
            }
        }
        
        if !lexer.endOfInput {
            productionErrors.append(LanguageError.scanningError(at: lexer.index..<lexer.source.unicodeScalars.endIndex, message: "Scanning stopped before end of input"))
        }
        
        ir.didBuild()
        
        return ir
    }
    
    public func build<IR:IntermediateRepresentation>(using lexer:LexicalAnalyzer)->IR{
        return build(intermediateRepresentation: IR(), using: lexer)
    }
    
    public func build<IR:IntermediateRepresentation>(source:String)->IR{
        return build(using: Lexer(source: source))
    }
}
