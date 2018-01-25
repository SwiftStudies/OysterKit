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

/// A parser for [STLR](https://github.com/SwiftStudies/OysterKit/blob/master/STLR.md) source files
public class STLRParser : Parser{
    public var ast    : STLRIntermediateRepresentation
    
    /**
     Creates a new instance of the parser and parses the source
     
     - Parameter source: The STLR source
    */
    public init(source:String){
        ast = STLRIntermediateRepresentation()

        super.init(grammar: STLR.generatedLanguage.grammar)
        
        //We don't need the resultant tree
        let _ = build(intermediateRepresentation: HeterogenousAST<HeterogeneousNode,STLRIntermediateRepresentation>(constructor: ast), using: Lexer(source: source))
                
        ast.optimize()
    }
    
    /// The errors encountered during parsing
    var errors : [Error] {
        return ast.errors
    }
    
    /// `true` if the STLR was succesfully compiled
    public var compiled : Bool {
        return ast.rules.count > 0
    }
}
