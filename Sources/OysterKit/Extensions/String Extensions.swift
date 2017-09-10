//
//  String Extensions.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation


public extension String.UnicodeScalarView{

    public func length(of range:Range<String.UnicodeScalarView.Index>)->Int{
        let range = range.clamped(to: startIndex..<endIndex)
        
        return distance(from: range.lowerBound, to: range.upperBound)
    }
}

public extension StringProtocol {
    public func tokenStream (with rules: [Rule]) -> NodeIterator<HomogenousNode> {
        let parser = StreamRepresentation<HomogenousNode, Lexer>(
            source: String(self),
            language: rules.language
        )
        
        return parser.makeIterator()
    }
}

