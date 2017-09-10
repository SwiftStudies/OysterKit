//
//  LexicalAnalyzer.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

public protocol LexicalAnalyzer : class {
    init(source:String)
    
    var current : String { get }
    var depth   : Int { get }
    
    ///: Marks the current position. This must be followed by a matching rewind() or proceed()
    func mark()
    
    ///: Discards the current mark, rewinding the scanner to that position
    func rewind()
    
    ///: Discards the current mark, but leaving the scanner at it's current location
    func proceed()->LexicalContext
    
    var  endOfInput : Bool {get}
    
    func scan(terminal:String) throws
    func scan(oneOf:CharacterSet) throws
    func scanUpTo(terminal:String) throws
    func scanUpTo(oneOf terminal:CharacterSet) throws
    func scanNext() throws
    
    subscript(range:Range<String.UnicodeScalarView.Index>)->String { get }
    
    var  source : String { get }
    
    var position : Int { get }
    var index    : String.UnicodeScalarView.Index { get set }
    
}

public protocol LexicalContext {
    var range         : Range<String.UnicodeScalarView.Index> { get }
    var source        : String { get }
    var matchedString : String { get }
}


