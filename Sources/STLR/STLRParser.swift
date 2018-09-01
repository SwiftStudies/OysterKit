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
import OysterKit

/// A parser for [STLR](https://github.com/SwiftStudies/OysterKit/blob/master/STLR.md) source files
public class STLRParser : Parser{
    public var ast    : STLR
    
    /**
     Creates a new instance of the parser and parses the source
     
     - Parameter source: The STLR source
    */
    @available(*, deprecated, message: "Replace with _STLR.build(_ source:String)")
    public init(source:String) {
        do {
            ast = try STLR.build(source)
            
            super.init(grammar: ast.grammar.dynamicRules)
            
            ast.grammar.optimize()

        } catch {
            ast = try! STLR.build("grammar Failed\n\ntry = \"again\"\n")
            super.init(grammar: ast.grammar.dynamicRules)
            errors.append(error)
        }
    }
    
    /// The errors encountered during parsing
    public private(set) var errors = [Error]()
    
    /// `true` if the STLR was succesfully compiled
    public var compiled : Bool {
        return ast.grammar.rules.count > 0
    }
}
