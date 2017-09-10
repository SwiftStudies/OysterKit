//
//  HomogenousNode.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

public struct HomogenousNode : Node {
    public      let token       : Token
    public      let range       : Range<String.UnicodeScalarView.Index>
    public      let annotations : [RuleAnnotation : RuleAnnotationValue]

    public init(for token: Token, at range: Range<String.UnicodeScalarView.Index>, annotations:[RuleAnnotation: RuleAnnotationValue]) {
        self.token = token
        self.range = range
        self.annotations = annotations
    }
    
    public var description: String{
        return "\(token)"
    }
    
}

public extension Node{
    public func matchedString(_ scalars:String.UnicodeScalarView)->String{
        return "\(scalars[range])"
    }
    
    public func matchedString(_ string:String)->String{
        return String(string[range])
//        return matchedString(string.unicodeScalars)
    }
}

