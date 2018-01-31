//
//  String+STLR.swift
//  stlr
//
//  Created by Swift Studies on 11/12/2017.
//

import Foundation

public extension String {
    public var canonicalPath : String {
        
        return ("\(hasPrefix(".") || hasPrefix("/") || hasPrefix("~") ? "" : "./")\(self)" as NSString).expandingTildeInPath + (hasSuffix("/") ? "/" : "")
    }
}
