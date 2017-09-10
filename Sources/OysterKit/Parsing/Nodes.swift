//
//  Nodes.swift
//  OysterKit
//
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

public extension Node {
    public var description: String {
        return "\(token)"
    }
}

public extension Collection where Iterator.Element : Node {
    public var combinedRange : Range<String.UnicodeScalarView.Index> {
        let finalRange = reduce(first!.range, { (rangeSoFar, nextChild) -> Range<String.UnicodeScalarView.Index> in
            let lowerBound = rangeSoFar.lowerBound < nextChild.range.lowerBound ? rangeSoFar.lowerBound : nextChild.range.lowerBound
            let upperBound = rangeSoFar.upperBound > nextChild.range.upperBound ? rangeSoFar.upperBound : nextChild.range.upperBound
            
            return lowerBound..<upperBound
        })
        
        return finalRange
    }
}
