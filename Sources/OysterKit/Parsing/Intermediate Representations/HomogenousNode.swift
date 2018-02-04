//
//  HomogenousNode.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

@available(*, deprecated, message: "Use AbstractSyntaxTree() instead")
public struct HomogenousNode : Node {
    /// The token representing the match
    public      let token       : Token
    
    /// The range of the match in the original source
    public      let range       : Range<String.UnicodeScalarView.Index>
    
    /// Annotations that were made on the token
    public      let annotations : [RuleAnnotation : RuleAnnotationValue]

    /**
     Creates a new instance of the node
     
     Parameter for: The token that has been matched
     Parameter range: The range of the match
     Parameter annotations: The annotations that were made on the token
     */
    public init(for token: Token, at range: Range<String.UnicodeScalarView.Index>, annotations:[RuleAnnotation: RuleAnnotationValue]) {
        self.token = token
        self.range = range
        self.annotations = annotations
    }
    
    /// A human readable description of the node
    public var description: String{
        return "\(token)"
    }
    
}

/// An extension providing convience methods for reporting the underlying matched string captured by the node
@available(*, deprecated, message: "Use AbstractSyntaxTree() instead")
public extension Node{
    
    /**
     Returns a `String` from the original source scalars that is the portion against which the rule that created the token matched
     
     - Parameter scalars: The original scalars being parsed
     - Returns: The `String` for the node
    */
    public func matchedString(_ scalars:String.UnicodeScalarView)->String{
        return "\(scalars[range])"
    }
    
    /**
     Returns a `String` from the original source  that is the portion against which the rule that created the token matched
     
     - Parameter scalars: The original `String` being parsed
     - Returns: The `String` for the node
     */
    public func matchedString(_ string:String)->String{
        return String(string[range])
    }
}

