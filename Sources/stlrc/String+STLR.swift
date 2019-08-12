//
//  String+STLR.swift
//  stlr
//
//  Created by Swift Studies on 11/12/2017.
//

import Foundation

public extension String {
    var canonicalPath : String {
        
        return NSString(string:"\(hasPrefix(".") || hasPrefix("/") || hasPrefix("~") ? "" : "./")\(self)").expandingTildeInPath + (hasSuffix("/") ? "/" : "")
    }
}
