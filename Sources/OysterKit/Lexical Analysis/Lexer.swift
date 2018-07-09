//    Copyright (c) 2014, RED When Excited
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

internal struct LexerContext : LexicalContext {
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

internal class Mark : CustomStringConvertible {
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

/**
 `Lexer` provides a concrete implementation of the `LexicalAnalyzer` protocol and is used by default for the rest of the OysterKit stack (for example
 in `Language.stream<N:Node,L:LexicalAnalyzer>(lexer:L)->AnySequence<N>`).
 
 In addition to the requirements of the `LexicalAnalyzer` protocol, this implementation provides the ability to skip characters from a `CharacterSet` when
 a call to `mark()` is made. This can be useful when the consumer always wants, for example, to ignore white space in a file.
 */
open class Lexer : LexicalAnalyzer, CustomStringConvertible{
    fileprivate let scanner : StringScanner
    private var marks   = [Mark]()
    
    /// If set, any characters in this set will be skipped when  `mark()` is called
    public var skip: CharacterSet?
    
    /**
     Creates a new instance of `Lexer` for the supplied `String`.
     
     - Parameter source: The `String` to perform the lexical analysis on
    */
    public required init(source: String) {
        scanner = StringScanner(source)
        mark()
    }
    
    /// The current `LexicalContext` of the `Lexer`
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
    
    /// The integer offset of the current position in characters from the beginning of the `String` being scanned
    ///
    ///  - SeeAlso: `index`
    public var position: Int{
        return scanner.string.unicodeScalars.distance(from: scanner.string.unicodeScalars.startIndex, to: scanner.scanLocation)
    }
    
    /// The index of the `UnicodeScalarView` position of the `String` being scanned
    public var index: String.UnicodeScalarView.Index {
        get {
            return scanner.scanLocation
        }
        
        set {
            scanner.scanLocation = newValue
        }
    }
    
    /// The current depth of the `Mark` stack used for unwinding failed rules
    public var depth: Int {
        return marks.count
    }
    
    /// The character at the current scanning position
    public var current : String {
        return "\(scanner.current)"
    }
    
    /// Mark the position of the scanner. It should be noted that at this point any characters matching `skip` will be skipped. There
    /// should always be a matching call to either `rewind()` or `proceed()->LexicalContext`
    public func mark() {
        marks.append(Mark(for:self))
    }
    
    /**
     Unwind the current scanning state to the previous position. Typically used when a scan for a match has failed and it is
     necessary to try another match.
     
     - SeeAlso: `proceed()->LexicalContext`
    */
    open func rewind() {
        let mark = marks.removeLast()
        
        scanner.scanLocation = mark.preSkipLocation
    }
    
    /**
     Creates a new `LexicalContext` from the start of top mark to the current scanner position. The mark is removed from the stack
     extending the range of the new top of the mark stack to this position.
     
     - Returns: A `LexicalContext` for the current match
    */
    open func proceed() -> LexicalContext {
        let mark = marks.removeLast()

        return LexerContext(mark: mark, endLocation: scanner.scanLocation, source: source)
    }
    
    /// Removes the top most `Mark` from the stack without creating a new `LexicalContext` effectively advancing the scanning position
    /// of the new topmost mark to this position.
    open func consume(){
        let _ = marks.removeLast()
    }
    
    /// `true` if the end of the `String` being scanned has been reached
    public var endOfInput: Bool{
        return scanner.isAtEnd
    }
    
    /**
     Scans until the specified terminal is reached in the source `String`. If the end of the `String` is reached before
     the supplied `String` is matched a `GrammarError` is thrown. If the terminal is matched, the scanning position will
     be at the end of that match.
     
     - Parameter terminal: A string to scan for
     - SeeAlso: `scanUpTo(terminal:String)`
    */
    open func scan(terminal: String) throws {
        if !scanner.scan(string: terminal){
            throw GrammarError.matchFailed(token: nil)
            
        }
    }
    
    /**
     Scans until one of the characters in the supplied `CharacterSet` is found. If the end of the source is reached before a
     character from the set is found a `GrammarError` is thrown. The scanner position will be directly after the matched
     character.
     
     - Parameter oneOf: A `CharacterSet` to scan for
    */
    open func scan(oneOf: CharacterSet) throws {
        if !scanner.scan(characterFrom: oneOf) {
            throw GrammarError.matchFailed(token: nil)
        }
    }
    
    /**
     Scans up to (that is, the position of the scanner will be at the start of the match, not after it) the supplied `String`. If the terminal is not found
     a `GrammarError` is thrown. The scanner position will be at the first character of the matched `terminal`.

     - Parameter terminal: A string to scan for
     - SeeAlso: `scan(terminal:String)`
    */
    open func scanUpTo(terminal:String) throws {
        if !scanner.scanUpTo(string: terminal){
            throw GrammarError.matchFailed(token: nil)
        }
    }
    
    /**
     Scans up to one of the characters in the supplied `CharacterSet` is found. If the end of the source is reached before a
     character from the set is found a `GrammarError` is thrown. The scanner position will be directly at the matched
     character.
     
     - Parameter oneOf: A `CharacterSet` to scan for
     */
    open func scanUpTo(oneOf terminal:CharacterSet) throws {
        if !scanner.scanUpTo(characterFrom: terminal){
            throw GrammarError.matchFailed(token: nil)
        }
    }
    
    /**
     Scan the supplied regular expression (```NSRegularExpression```). If not found an `Error` should be the thrown. The scanner
     position should be directly after the matched pattern.
     
     - Parameter regularExpression: The `NSRegularExpression` to scan for
     */
    open func scan(regularExpression regex: NSRegularExpression) throws {
        if !scanner.scan(regularExpression: regex){
            throw GrammarError.matchFailed(token: nil)
        }
    }
    
    /**
     Advances the scanner one character. If the end of the source `String` has already been reached a `GrammarException` will be thrown.
    */
    open func scanNext() throws {
        if scanner.scanNext() == nil {
            throw GrammarError.matchFailed(token: nil)
        }
    }
 
    /**
     Returns the `String` from the `source` representing the supplied range.
    */
    public subscript(range:Range<String.UnicodeScalarView.Index>)->String {
        return "\(scanner.string.unicodeScalars[range])"
    }
    
    
    /// The `String` currently being scanned
    public var source: String{
        return scanner.string
    }
    
    /// A description of the current state of the `Lexer`
    public var description: String{
        var result = "Scanning: \(scanner.string.count) characters, currently at \(scanner) '\(scanner.current)':\n"
        
        for mark in marks {
            let position = scanner.string.unicodeScalars.distance(from: scanner.string.unicodeScalars.startIndex, to: mark.preSkipLocation)
            result += "\t\(position)\n"
        }
        
        return result
    }
}

