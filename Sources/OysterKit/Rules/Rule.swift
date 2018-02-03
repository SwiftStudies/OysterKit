//    Copyright (c) 2016, RED When Excited
//    All rights reserved.
//
//    Redistribution and use in source and binary forms, with or without
//    modification, are permitted provided that the following conditions are met:
//
//    * Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
//    * Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
//    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
//    FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//    SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import Foundation

/// A constant for the integer value of a transient token
public let transientTokenValue = -1

/// Extensions to enable any Int to be used as a token. Note that **only positive integers should be used**
extension Int {
    /// A token from this integer value
    var token : Token {
        struct TransientToken : Token { let rawValue : Int }
        return TransientToken(rawValue: self)
    }
}

/**
 `Token`s are generated when rules are matched (usually, sometime a rule just advances the scan-head). Tokens with a `rawValue` of -1 are considered transient, meaning that they should not be included in any construction of an AST. However, they may provide context to the AST.
 */
public protocol Token {
    /// A rawValue that unless the token is transient should be unique
    var rawValue : Int { get }
}

/**
 Provides a convience static variable that returns a transient ``Token``
 */
public extension Token {
    
    /// A transient token
    public static var transientToken : Token {
        return transientTokenValue.token
    }
}

/**
 A generic ``Token`` implementation that is labelled (has an associated ``String`). The value is automatically generated
 */
public struct LabelledToken : Token, CustomStringConvertible {
    /// The label for the token
    private     let label : String
    
    /// The ``Int`` identifier of the Token. It is automatically generated
    public      let rawValue : Int
    
    /**
     Create a new token instance
     
     - Parameter label: The textual representation of the token
    */
    public init(withLabel label: String){
        self.label = label
        rawValue = label.hashValue
    }
    
    /// A human readable representation of the token
    public var description: String{
        return label
    }
}

/**
 An extension to allow any `String` to be used as a `Token`.
 */
extension String : Token {
    /// Returns the `hash` of the `String`
    public var rawValue : Int {
        return self.hash
    }
}

/**
 An extension to allow any `Int` to be used as a `Token`.
 */
extension Int : Token{
    /// Itself
    public var rawValue: Int{
        return self
    }
}

/**
 A set of utility extensions for creating rules for `Token`s quickly.
 */
public extension Token {
    /**
     Create a rule that creates the `Token` when on of the characters in the supplied set is found
     
     - Parameters oneOf: A character set
     - Returns: A `Rule` that will issue the token if one of the characters from the set is at the scan head
    */
    public func from(oneOf characterSet:CharacterSet)->Rule{
        return characterSet.terminal(token: self)
    }
    
    /**
     Create a rule that will consume one of the characters in the supplied set is found. No token will be issued.
     
     - Parameters characterSet: A character set
     - Returns: A `Rule` that is satisfied if one of the characters from the set is at the scan head
     */
    public func consume(_ characterSet:CharacterSet)->Rule{
        return characterSet.consume(greedily: false)
    }
    
    /**
     Create a rule that will consume as many of the characters in the supplied set as possible. No token will be issued.
     
     - Parameters characterSet: A character set
     - Returns: A `Rule` that is satisfied if until one of the characters from the set is not at the scan head
     */
    public func consumeGreedily(_ characterSet:CharacterSet)->Rule{
        return characterSet.consume(greedily: true)
    }
    
    /**
     Create a rule that creates the `Token` when one or more of the characters in the supplied set is found
     
     - Parameters oneOf: A character set
     - Returns: A `Rule` that will issue the token if one or more of the characters from the set is at the scan head
     */
    public func oneOrMore(of characterSet:CharacterSet)->Rule{
        return characterSet.terminal(token:0).repeated(min:1, producing: self)
    }
}

/**
 Match results are passed from `Rule`s to `IntermediateRepresentations` and provide all information required to create an AST or even begin
 interpretting the results of the match.
 */
public enum MatchResult : CustomStringConvertible{
    /// The match was successful
    case success(context:LexicalContext)
    /// The match was successful but no token should be issued
    case consume(context:LexicalContext)
    /// The match failed, but that failure is OK
    case ignoreFailure(atIndex:String.UnicodeScalarView.Index)
    /// The match failed
    case failure(atIndex:String.UnicodeScalarView.Index)
    
    /// A human readable description of the result
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
    
    /// The substring of the source that the match was against
    public var matchedString : String? {
        switch self {
        case .success(let context):
            return context.matchedString
        default:
            return nil
        }
    }
}

/**
 Represents the value for a rule annotation
 */
public enum RuleAnnotationValue : CustomStringConvertible{
    /// A `String` value
    case    string(String)
    
    /// A `Bool` value
    case    bool(Bool)
    
    /// An `Int` value
    case    int(Int)
    
    /// No value, but the annotation was present
    case    set
    
    /// A human readable description of the annotation value
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

/**
 An annotation that can be associated with any rule influencing how matches are interpretted and providing additional data about the token. The following annotations represent "reserved words", but otherwise you can define any annotations you want.
 
    - `.token` Override the token to be created when the rule is matched (ignoring the `Rule`'s `produces` property
    - '.error` A specific error message to generate if the `Rule` is not satisfied
    - '.void' The match should be completely ignored. This is not a failure but rather a consumption
    - '.transient' The match should be made and a `Node` could be created but this token is not significant for the AST
    - '.pinned' The token should be created with no value even if the `Rule` is not matched in an ignorable failure
 
 
 */
public enum RuleAnnotation : Hashable, CustomStringConvertible{
    /// Token to be created when the rule is matched
    case token
    /// An error to be generated when the rule is not matched
    case error
    /// Matches will be completely discarded (no node, no adoption of children by parent)
    case void
    
    ///Token will not be preserved in the AST but it's children should be adopted by the parent node
    case transient
    
    ///Nodes will be created for failed optional matches
    case pinned
    
    ///A custom developer defined annotation that your own AST will interpret
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
    
    /**
        Compares two annotations for equality (not values, but keys)
     
     - Parameter lhs: The first annotation
     - Parameter rhs: The second annotation
     - Returns: `true` if the annotations are the same, `false` otherwise.
    */
    public static func ==(lhs:RuleAnnotation, rhs:RuleAnnotation)->Bool{
        return lhs.hashValue == rhs.hashValue
    }
    
    /// A human readable description of the annotation
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

/// A dictionary of annotations and their values
public typealias RuleAnnotations = [RuleAnnotation : RuleAnnotationValue]

/// Compares two ``RuleAnnotations``
public func areEqual(lhs: RuleAnnotations, rhs: RuleAnnotations)->Bool{
    func areEqual(lhs:RuleAnnotationValue, rhs:RuleAnnotationValue)->Bool{
        return lhs.description == rhs.description
    }
    if lhs.count != rhs.count {
        return false
    }
    
    for tuple in lhs {
        guard let rhsValue = rhs[tuple.key] else {
            return false
        }
        if !areEqual(lhs: rhsValue, rhs: tuple.value) {
            return false
        }
    }

    return true
}

/// An extension for dictionaries of `RuleAnnotations`
public extension Collection where Iterator.Element == (key:RuleAnnotation,value:RuleAnnotationValue){
    
    /// Creates a new collection of RuleAnnotations where the merged annotations override those in
    /// this object
    /// - Parameter with: The annotations which will add to or override those already in the dictionary
    public func merge(with incoming:RuleAnnotations)->RuleAnnotations{
        var merged = self as! RuleAnnotations
        for annotation in incoming {
            merged[annotation.key] = annotation.value
        }
        
        return merged
    }
    
    /// A description in STLR format of the `RuleAnnotations`
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

/**
 The protocol that parsing and scanning rules must adhere to. There is no need to fully implement this protocol unless you are looking for bespoke `LexicalAnalyzer` or `IntermediateRepresentation` control. It is recommended to use `ParserRule.custom` in almost all cases.
 */
public protocol Rule {
    /**
     Should perform the actual check and manage the communicaion with the supplied `IntermedidateRepresentation`. If the match fails, and that failure cannot
     be ignored an `Error` should be thrown. It is the responsiblity of the implementer to ensure the following basic pattern is followed
     
        1. `ir.willEvaluate()` is called to inform the `ir` that evaluation is beginning. If the `ir` returns an existing match result that should be used (proceed to step XXX)
        2. `lexer.mark()` should be called so that an accurate `LexicalContext` can be generated.
        3. Perform apply your rule using `lexer`.
        4. Depending on the outcome, and the to-be-generated token:
            - If the rule was satisfied, return a `MatchResult.success` together with a generated `lexer.proceed()` generated context
            - If the rule was satisfied, but the result should be consumed (no node/token created, but scanning should proceed after the match) return `MatchResult.consume` with a generated `lexer.proceed()` context
            - If the rule was _not_ satisfied but the failure can be ignored return `MatchResult.ignoreFailure`. Depending on your grammar you *may* want to leave the scanner in the same position in which case issue a `lexer.proceed()` but discard the result. Otherwise issue a `lexer.rewind()`.
            - If the rule was _not_ satisfied but the failure should not be ignored. Call `lexer.rewind()` and return a `MatchResult.failure`
            - If the rule was _not_ satisifed and parsing of this branch of the grammar should stop immediately throw an `Error`
     
    For standard implementations of rules that should satisfy almost every grammar see `ParserRule` and `ScannerRule`. `ParserRule` has a custom case which
     provides all of the logic above with the exception of actual matching which is a lot simpler, and it is recommended that you use that if you wish to provide your own rules.
     
     - Parameter with: The `LexicalAnalyzer` providing the scanning functions
     - Parameter for: The `IntermediateRepresentation` that wil be building any data structures required for subsequent interpretation of the parsing results
     - Returns: The match result.
    */
    func match(with lexer : LexicalAnalyzer, `for` ir:IntermediateRepresentation) throws -> MatchResult
    
    /// The token produced by this rule
    var  produces : Token {get}
    
    /// The annotations on this rule
    var  annotations : RuleAnnotations { get set }
    
    /// Returns the value of the specific `RuleAnnotationValue` identified by `annotation` if present
    subscript(annotation:RuleAnnotation)->RuleAnnotationValue? { get }
}

/// A set of standard properties and functions for all `Rule`s
public extension Rule{
    
    /// The user specified (in an annotation) error associated with the rule
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

    /// Is this rule marked as void?
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
    
    /// Is this rule marked as transient
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
    
    /// Returns the value of the specific `RuleAnnotationValue` identified by `annotation` if present
    public subscript(annotation:RuleAnnotation)->RuleAnnotationValue?{
        return annotations[annotation]
    }
    
}

/**
 Compares two tokens for equality
 */
public func ==(lhs:Token, rhs:Token)->Bool{
    return lhs.rawValue == rhs.rawValue
}

/// Utility extension for determining if a token is trasnient
public extension Token{
    /// True if the token is transient
    public var transient : Bool {
        return rawValue == transientTokenValue
    }
}
