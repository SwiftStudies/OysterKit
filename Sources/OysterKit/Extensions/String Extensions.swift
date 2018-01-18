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


/// Provides an additional method to calculate the length of a range in actual characters
public extension String.UnicodeScalarView{

    /**
     Calculates the length of the supplied range in characters (complete Graphemes)
     
     - Parameter of: The range to evaluate
     - Returns: The length of the range between the two indexes
    */
    public func length(of range:Range<String.UnicodeScalarView.Index>)->Int{
        let range = range.clamped(to: startIndex..<endIndex)
        
        return distance(from: range.lowerBound, to: range.upperBound)
    }
}

/**
 A utility method to easily create a token stream from any string, allowing you to incrementally iterate over the results (lazily)
 
        ...
        for token in "PARSE ME".tokenStream(with: myRules){
            print("\(token)")
        }
 
 */
public extension StringProtocol {
    
    /**
     Creates an iterable stream of nodes from the String
     
     - Parameter with: The rules to use to parse the string
     - Returns: A `NodeIterator` (which conforms to `IteratorProtocol`) which can be used to iterate through the nodes
    */
    public func tokenStream (with rules: [Rule]) -> NodeIterator<HomogenousNode> {
        let parser = StreamRepresentation<HomogenousNode, Lexer>(
            source: String(self),
            language: rules.language
        )
        
        return parser.makeIterator()
    }
}

