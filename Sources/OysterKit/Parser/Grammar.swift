//    Copyright (c) 2016, RED When Excited
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

/// Depricated, use `Grammar`
@available(*,deprecated,message: "Parser has been depricated the rules used at initialization can be directly used as a Grammar. e.g. let parser = Parser(grammar:rules) becomes let parser = rules")
public typealias Parser = Grammar

/// Depricated, use `Grammar`
@available(*,deprecated,message: "Replace with Grammar and use the rules property of Grammar instead of a grammar property of Language")
public typealias Language = Grammar

/**
 A language stores a set of grammar rules that can be used to parse `String`s. Extensions provide additional methods (such as parsing) that operate on these rules.
 */
public protocol Grammar{
    /// The rules in the `Language`'s grammar
    var  rules : [Rule] {get}
}

/// Extensions to an array where the elements are `Rule`s
extension Array : Grammar  where Element == Rule {
    public var rules: [Rule] {
        return self
    }    
}

public extension Grammar {

    /**
     Creates an iterable stream of tokens using the supplied source and this `Grammar`
     
     It is very easy to create and iterate through a stream, for example:
     
         let source = "12+3+10"
     
         for token in try calculationGrammar.stream(source){
            // Do something cool...
         }
     
     Streams are the easiest way to use a `Grammar`, and consume less memory and are in general faster
     (they certainly will never be slower). However you cannot easily navigate and reason about the
     stream, and only top level rules and tokens will be created.
     
     - Parameter source: The source to parse
     - Returns: An iterable stream of tokens
     **/
    func tokenize(_ source:String)->TokenStream{
        return TokenStream(source, using: self)
    }
    
    /**
     Creates a `HomogenousTree` using the supplied grammar.
     
     A `HomogenousTree` captures the result of parsing hierarchically making it
     easy to manipulate the resultant data-structure. It is also possible to get
     more information about any parsing errors. For example:
     
         let source = "12+3+10"
     
         do {
            // Build the HomogenousTree
            let ast = try calculationGrammar.parse(source)
     
            // Prints the parsing tree
            print(ast)
         } catch let error as ProcessingError {
            print(error.debugDescription)
         }
     
     - Parameter source: The source to parse with the `Grammar`
     - Returns: A `HomogenousTree`
     **/
    func parse(_ source:String) throws ->HomogenousTree{
        return try AbstractSyntaxTreeConstructor(with: source).build(using: self)
    }
    
    /**
     Builds the supplied source into a Heterogeneous representation (any Swift `Decodable` type).
     
     This is the most powerful application of a `Grammar` and leverages Swift's `Decoable` protocol.
     It is strongly recommended that you [read a little about that first](https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types).
     
     Essentially each token in the grammar will be mapped to a `CodingKey`. You should first parse into a `HomogenousTree`
     to make sure your types and the hierarchy generated from your grammar align.
    
     If you want to automatically generate the `Decodable` types you can do this using [STLR](https://github.com/SwiftStudies/OysterKit/blob/master/Documentation/STLR.md)
     and [`stlrc`](https://github.com/SwiftStudies/OysterKit/blob/master/Documentation/stlr-toolc.md) which will automatically synthesize your grammar and data-structures in Swift.
     
     - Parameter source: The source to compile
     - Parameter type: The `Decodable` type that should be created
     - Returns: The populated type
     **/
    func build<T : Decodable>(_ source:String,as type: T.Type) throws -> T{
        return try ParsingDecoder().decode(T.self, using: parse(source))
    }
}
