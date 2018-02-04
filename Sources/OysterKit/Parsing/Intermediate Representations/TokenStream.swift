//    Copyright (c) 2018, RED When Excited
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
 A ``TokenStream`` provides lazy iterators that minimize memory consumption and overhead allowing you to iterate through the tokens created by the
 root rules (those at the lowest level in the language) in the supplied ``Language``
 */
public class TokenStream : Sequence{
    /// The iterator implementation to use
    public typealias Iterator =  TokenStreamIterator
    
    /// The lexer to use for the iterator
    let lexerType   : LexicalAnalyzer.Type
    
    /// The language to use to parse
    let language    : Language
    
    /// The source ``String`` to parse
    let source      : String
    
    public init(_ source:String, using language:Language){
        self.source = source
        self.lexerType = Lexer.self
        self.language = language
    }

    public init<Lex:LexicalAnalyzer>(_ source:String, using language:Language, with lexer:Lex.Type){
        self.lexerType = lexer
        self.language = language
        self.source = source
    }
    
    public func makeIterator() -> Iterator {
        return TokenStreamIterator(with: lexerType.init(source: source), and: language)
    }

}

/// The elements generated during streaming. These are very light-weight and are the same
/// as those used as an intermediate representation when building an ``AbstractSyntaxTree``
public typealias StreamedToken = AbstractSyntaxTreeConstructor.IntermediateRepresentationNode

/// The Iterator created by token streams
public class TokenStreamIterator : IteratorProtocol {
    /// The iterator generates elements of type ``StreamedToken``
    public typealias Element = StreamedToken

    /// Any errors encountered during parsing
    public private (set) var parsingErrors = [Error]()
    
    /// **DO NOT CALL**
    public required init() {
        fatalError("Do not create an instance of this object directly")
    }
    
    /**
     Creates a new instance of the iterator
     
     - Parameter lexer: The ``LexicalAnalyzer`` to use
     - Parameter language: The ``Language`` to use
    */
    init(with lexer:LexicalAnalyzer, and language:Language){
        parsingContext = ParsingStrategy.ParsingContext(lexer: lexer, ir: self, language: language)
    }
    
    /**
     Fetches the next matching token
     
     - Return: The generated token or nil
    */
    public func next() -> StreamedToken? {
        nextToken = nil
        if depth == 0 {
            willBuildFrom(source: parsingContext.lexer.source, with: parsingContext.language)
        }
        
        do {
            if try ParsingStrategy.pass(in: parsingContext) == false{
                nextToken = nil
            }
        } catch {
            parsingErrors.append(error)
            nextToken = nil
        }
        
        return nextToken
    }
    
    /// True if parsing reached the end of input naturally (that is, encountered no errors)
    public var reachedEndOfInput  : Bool {
        return parsingContext.complete
    }
    
    /// This must be force unwrapped as the parsing context requies this object in its initializer.
    var parsingContext     : ParsingStrategy.ParsingContext!
    
    /// Track the depth of evaluation
    var depth              = 0
    
    /// The token generated during the last pass
    var nextToken          : StreamedToken?
    
}

/// This iterator is a very light weight intermediate representation that only constructs top level nodes
extension TokenStreamIterator : IntermediateRepresentation {
    
    /// Increments the depth
    public func willEvaluate(rule: Rule, at position: String.UnicodeScalarView.Index) -> MatchResult? {
        depth += 1
        return nil
    }
    
    /// Decrements the depth and generates the next token if the depth is one and the match was successful or an ignorableFailure that was pinned
    /// It ignores both transient and void annotations on the top level rules
    public func didEvaluate(rule: Rule, matchResult: MatchResult) {
        depth -= 1
        
        if depth == 1  {
            switch matchResult {
            case .ignoreFailure(let index):
                if rule.annotations[RuleAnnotation.pinned] != nil {
                    nextToken = StreamedToken(for: rule.produces, at: index..<index, annotations: rule.annotations)
                }
            case .success(let context):
                nextToken = StreamedToken(for: rule.produces, at: context.range, annotations: rule.annotations)
            default:
                nextToken = nil
            }
        }
    }
    
    /// Sets the initial depth to 1
    public func willBuildFrom(source: String, with: Language) {
        depth = 1
    }
    
    /// Disables further evaluation
    public func didBuild() {
        depth = 0
    }
    
    /// Disables further evaluation
    public func resetState() {
        depth = 0
    }

}
