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

/**
 The job of an implementation of this protocol is two fold
 
  * Manage the state of the `Scanner` to provide n lookahead capability to the surrounding rules
  * To provide a layer of abstraction between consumers of scanning behaviour and the scanner itself. This allows the scanner to be
    as simple as possible
 
 It used heavily during `Rule` evaluation. Typically a rule will start by `mark()`ing it's possition (remembering the positiong of the `Scanner` at
 the start of rule evaluation. During `Rule` evaluation rules will result (eventually) in calls to the various `scan` methods which will advance
 the Scanner. Finally, the rule will either be satisfied and `proceed()->LexicalContext` will be called, or fail and `rewind()` will be called returning
 the `Scanner` to its state before `mark()` was called. 
 
 */
public protocol LexicalAnalyzer : class {
    
    /**
     Creates a new instance of `Lexer` for the supplied `String`.
     
     - Parameter source: The `String` to perform the lexical analysis on
     */
    init(source:String)
    
    /// The character currently being evaluated
    var current : String { get }
    
    /// The depth of the look-ahead stack
    var depth   : Int { get }
    
    ///: Marks the current position. This must be followed by a matching rewind() or proceed()
    func mark()
    
    ///: Discards the current mark, rewinding the scanner to that position
    func rewind()
    
    ///: Discards the current mark, but leaving the scanner at it's current location
    func proceed()->LexicalContext
    
    /// Should return `true` if the end of the source `String` has been reached
    var  endOfInput : Bool {get}
    
    
    /**
     Scan until the specified terminal is reached in the source `String`. If the end of the `String` is reached before
     the supplied `String` is matched an error should be thrown. If the terminal is matched, the scanning position should
     be at the end of that match.
     
     - Parameter terminal: A string to scan for
     - SeeAlso: `scanUpTo(terminal:String)`
     */
    func scan(terminal:String) throws

    
    /**
     Scan until one of the characters in the supplied `CharacterSet` is found. If the end of the source is reached before a
     character from the set is found an `Error` should be thrown. The scanner position should be directly after the matched
     character.
     
     - Parameter oneOf: A `CharacterSet` to scan for
     */
    func scan(oneOf:CharacterSet) throws
    
    /**
     Scan the supplied regular expression (```NSRegularExpression```). If not found an `Error` should be the thrown. The scanner
     position should be directly after the matched pattern.
     
     - Parameter regularExpression: The `NSRegularExpression` to scan for
    */
    func scan(regularExpression:NSRegularExpression) throws
    
    /**
     Scan up to (that is, the position of the scanner should be at the start of the match, not after it) the supplied `String`. If the terminal is not found
     an `Error` should be thrown. The scanner position should be at the first character of the matched `terminal`.
     
     - Parameter terminal: A string to scan for
     - SeeAlso: `scan(terminal:String)`
     */
    func scanUpTo(terminal:String) throws
    
    /**
     Scan up to one of the characters in the supplied `CharacterSet` is found. If the end of the source is reached before a
     character from the set is found an `Error` should be thrown. The scanner position should be directly at the matched
     character.
     
     - Parameter oneOf: A `CharacterSet` to scan for
     */
    func scanUpTo(oneOf terminal:CharacterSet) throws
    
    /**
     Advances the scanner one character. If the end of the source `String` has already been reached a `Error` should be thrown.
     */
    func scanNext() throws
    
    /**
     Should return the `String` from the `source` representing the supplied range.
     */
    subscript(range:Range<String.UnicodeScalarView.Index>)->String { get }
    
    /// Should return the `String` being analyzed
    var  source : String { get }
    
    /// Should return the integer offset of the current scanning position in charactes
    var position : Int { get }
    
    /// Should return the `String.UnicodeScalarView.Index` of the current scanning position in the supplied source `String`
    var index    : String.UnicodeScalarView.Index { get set }
    
}

/**
 A lexical context summarises the of a `String` being scanned by a `LexicalAnalyzer` between two marks. It is generated when the `LexicalAnalyzer` is advanced
 confirming that the last rule was essentially matched.
 */
public protocol LexicalContext {
    /// The range from the `LexicalAnalyzer.mark()` to the point at which `LexicalAnalyzer.proceed()->LexicalContext` was called
    var range         : Range<String.UnicodeScalarView.Index> { get }
    
    /// The string being scanned
    var source        : String { get }
    
    /// The substring that was matched and is catpured by the `range`
    var matchedString : String { get }
}


