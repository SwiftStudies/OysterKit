//
//  Rule.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

internal let transientTokenValue = -1

extension Int {
    var token : Token {
        struct TransientToken : Token { let rawValue : Int }
        return TransientToken(rawValue: self)
    }
}

public protocol Token {
    var rawValue : Int { get }
}

extension String : Token {
    public var rawValue : Int {
        return self.hash
    }
}

extension Int : Token{
    public var rawValue: Int{
        return self
    }
}

public extension Token {
        
    public func from(oneOf characterSet:CharacterSet)->Rule{
        return characterSet.terminal(token: self)
    }
    
    public func consume(_ characterSet:CharacterSet)->Rule{
        return characterSet.consume(greedily: false)
    }
    
    public func consumeGreedily(_ characterSet:CharacterSet)->Rule{
        return characterSet.consume(greedily: true)
    }
    
    public func oneOrMore(of characterSet:CharacterSet)->Rule{
        return characterSet.terminal(token:0).repeated(min:1, producing: self)
    }
}

//extension Token {
//    public var hashValue: Int{
//        return rawValue
//    }
//    
//    static public func==(lhs:Token, rhs:Token)->Bool{
//        return lhs.rawValue == rhs.rawValue
//    }
//}

public enum MatchResult : CustomStringConvertible{
    case success(context:LexicalContext)
    case consume(context:LexicalContext)
    case ignoreFailure(atIndex:String.UnicodeScalarView.Index)
    case failure(atIndex:String.UnicodeScalarView.Index)
    
    public var description: String{
        switch self {
        case .success(let context):
            return "Success (\(context.source.unicodeScalars[context.range]))"
        case .consume(let context):
            return "Consumed (\(context.source.unicodeScalars[context.range]))"
        case .ignoreFailure:
            return "Ignore Failure"
        case .failure(let at):
            return "Failed at \(at)"
        }
    }
    
    public var matchedString : String? {
        switch self {
        case .success(let context):
            return context.matchedString
        default:
            return nil
        }
    }
}

public enum RuleAnnotationValue : CustomStringConvertible{
    case    string(String)
    case    bool(Bool)
    case    int(Int)
    case    set
    
    public var description: String{
        switch self{
        case .set:
            return ""
        case .int(let value):
            return "\(value)"
        case .bool(let value):
            return "\(value)"
        case .string(let value):
            return "\"\(value)\""
        }
    }
}

public enum RuleAnnotation : Hashable, CustomStringConvertible{
    case token //Token to be created when the rule is matched
    case error //An error to be generated when the rule is not matched
    case void  //Matches will be completely discarded (no node, no adoption of children by parent)
    case transient //Token will not be preserved in the AST but it's children should be adopted by the parent node
    case pinned //Nodes will be created for failed optional matches
    
    case custom(label:String)
    
    public var hashValue: Int{
        switch self {
        case .token, .error, .void, .transient:
            return "\(self)".hash
        case .pinned:
            return "pin".hash
        case .custom(let label):
            return label.hash
        }
    }
    
    public static func ==(lhs:RuleAnnotation, rhs:RuleAnnotation)->Bool{
        return lhs.hashValue == rhs.hashValue
    }
    
    public var description: String{
        switch self {
        case .pinned:
            return "pin"
        case .token:
            return "token"
        case .error:
            return "error"
        case .void:
            return "void"
        case .transient:
            return "transient"
        case .custom(let label):
            return label
        }
    }
}

public typealias RuleAnnotations = [RuleAnnotation : RuleAnnotationValue]

public extension Collection where Iterator.Element == (key:RuleAnnotation,value:RuleAnnotationValue){
    
    // Creates a new collection of RuleAnnotations where the merged annotations override those in 
    // this object
    public func merge(with incoming:RuleAnnotations)->RuleAnnotations{
        var merged = self as! RuleAnnotations
        for annotation in incoming {
            merged[annotation.key] = annotation.value
        }
        
        return merged
    }
    
    public var stlrDescription : String {
        var result = ""
        for tuple in self {
            result += "@\(tuple.0)"
            let value = tuple.1.description
            if !value.isEmpty {
                result+="(\(value))"
            }
        }
        
        return result
    }
}

public protocol Rule {
    func match(with lexer : LexicalAnalyzer, `for` ir:IntermediateRepresentation) throws -> MatchResult
    var  produces : Token {get}
    
    var  annotations : RuleAnnotations { get set }
    subscript(annotation:RuleAnnotation)->RuleAnnotationValue? { get }
}

public extension Rule{
    public var error : String? {
        guard let value = self[RuleAnnotation.error] else {
            return nil
        }
        
        if case let .string(stringValue) = value {
            return stringValue
        } else {
            return "Unexpected annotation value: \(value)"
        }
    }
    
    public var void : Bool {
        guard let value = self[RuleAnnotation.void] else {
            return false
        }
        
        switch value {
        case .set:
            return true
        case .bool(let boolValue):
            return boolValue
        default:
            return false
        }
    }
    
    public var transient : Bool{
        if produces.transient {
            return true
        }
        
        guard let value = self[RuleAnnotation.transient] else {
            return false
        }
        
        switch value {
        case .set:
            return true
        case .bool(let boolValue):
            return boolValue
        default:
            return false
        }
    }
    
    public subscript(annotation:RuleAnnotation)->RuleAnnotationValue?{
        return annotations[annotation]
    }
    
}

public func ==(lhs:Token, rhs:Token)->Bool{
    return lhs.rawValue == rhs.rawValue
}

public extension Token{
    public var transient : Bool {
        return rawValue == transientTokenValue
    }
}
