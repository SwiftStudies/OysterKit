//
//  Lexer.swift
//  OysterKit
//
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

private struct LexerContext : LexicalContext {
    let mark  : Mark
    let endLocation : String.UnicodeScalarView.Index
    let source: String
    
    
    var range: Range<String.UnicodeScalarView.Index>{
        return mark.preSkipLocation..<endLocation
    }
    
    var matchedString : String {
        return String(source[range])
    }
    
}

private class Mark : CustomStringConvertible {
    let preSkipLocation     : String.UnicodeScalarView.Index
    let postSkipLocation    : String.UnicodeScalarView.Index
    
    init(`for` lexer:Lexer){
        preSkipLocation = lexer.scanner.scanLocation
        guard let skip = lexer.skip else {
            postSkipLocation = preSkipLocation
            return
        }
        let _ = lexer.scanner.scan(charactersFrom: skip)
        postSkipLocation = lexer.scanner.scanLocation
    }
    
    init(uniPosition:String.UnicodeScalarView.Index){
        preSkipLocation = uniPosition
        postSkipLocation = uniPosition
    }
    
    var description : String {
        return "\(postSkipLocation)"
    }
}

open class Lexer : LexicalAnalyzer, CustomStringConvertible{
    fileprivate let scanner : StringScanner
    private var marks   = [Mark]()
    
    public var skip: CharacterSet?
    
    public required init(source: String) {
        scanner = StringScanner(source)
        mark()
    }
    
    var currentContext : LexicalContext {
        return LexerContext(mark: Mark(uniPosition:scanner.scanLocation), endLocation: scanner.scanLocation, source: scanner.string)
    }
    
    internal var markedLocation : String.UnicodeScalarView.Index{
        //This is used for testing, and I'm not certain if it should be pre or post skip
        //I assume pre skip
        guard let mLoc = marks.last?.preSkipLocation else {
            return scanner.string.unicodeScalars.startIndex
        }
        
        return mLoc
    }
    
    public var position: Int{
        return scanner.string.unicodeScalars.distance(from: scanner.string.unicodeScalars.startIndex, to: scanner.scanLocation)
    }
    
    public var index: String.UnicodeScalarView.Index {
        get {
            return scanner.scanLocation
        }
        
        set {
            scanner.scanLocation = newValue
        }
    }
    
    public var depth: Int {
        return marks.count
    }
    
    public var current : String {
        return "\(scanner.current)"
    }
    
    public func mark() {
        marks.append(Mark(for:self))
    }
    
    open func rewind() {
        let mark = marks.removeLast()
        
        scanner.scanLocation = mark.preSkipLocation
    }
    
    open func proceed() -> LexicalContext {
        let mark = marks.removeLast()

        return LexerContext(mark: mark, endLocation: scanner.scanLocation, source: source)
    }
    
    open func consume(){
        let _ = marks.removeLast()
    }
    
    public var endOfInput: Bool{
        return scanner.isAtEnd
    }
    
    open func scan(terminal: String) throws {
        if !scanner.scan(string: terminal){
            throw GrammarError.matchFailed(token: nil)
            
        }
    }
    
    open func scan(oneOf: CharacterSet) throws {
        if !scanner.scan(characterFrom: oneOf) {
            throw GrammarError.matchFailed(token: nil)
        }
    }
    
    open func scanUpTo(terminal:String) throws {
        if !scanner.scanUpTo(string: terminal){
            throw GrammarError.matchFailed(token: nil)
        }
    }
    
    open func scanUpTo(oneOf terminal:CharacterSet) throws {
        if !scanner.scanUpTo(characterFrom: terminal){
            throw GrammarError.matchFailed(token: nil)
        }
    }
    
    open func scanNext() throws {
        if scanner.scanNext() == nil {
            throw GrammarError.matchFailed(token: nil)
        }
    }
 
    public subscript(range:Range<String.UnicodeScalarView.Index>)->String {
        return "\(scanner.string.unicodeScalars[range])"
    }
    
    public var source: String{
        return scanner.string
    }
    
    public var description: String{
        var result = "Scanning: \(scanner.string.characters.count) characters, currently at \(scanner) '\(scanner.current)':\n"
        
        for mark in marks {
            let position = scanner.string.unicodeScalars.distance(from: scanner.string.unicodeScalars.startIndex, to: mark.preSkipLocation)
            result += "\t\(position)\n"
        }
        
        return result
    }
}

