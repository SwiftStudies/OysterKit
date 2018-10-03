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

import XCTest
@testable import STLR
@testable import OysterKit
import TestingSupport

let source = """
grammar G

@a l = .letter
@b d = .decimalDigit
"""

class SymbolTableTests: XCTestCase {
    
    func stlrGrammar() throws -> SymbolTable<SerializedSymbol> {
        let stlr = try ProductionSTLR.build(STLRSource)
        let grammar = try stlr.analyze(SerializedSymbol.self)
        
        return grammar
    }
    
    func testNotNewRule(){
        do {
            let identifier = "notNewRule"
            let source = "@hello(\"hello\") something"
            guard let rule : _Rule = try stlrGrammar()[dynamicRuleFor: identifier] as? _Rule else {
                XCTFail("Could not find rule")
                return
            }

            let lexer = Lexer(source: source)
            let ir = AbstractSyntaxTreeConstructor(with: source)
            
            try rule.evaluate(lexer: lexer, ir: ir)
            
            let tree = try ir.generate(HomogenousTree.self)
            
            print(tree.description)
            
        } catch let error as ProcessingError {
            XCTFail("Unexpected processing error")
            print(error.debugDescription)
        } catch {
            XCTFail("Unexpected error")
            print(error.localizedDescription)
        }
    }
    
    func testAllOfStlr() {
        do {
            let grammar = try stlrGrammar()
            
            print(grammar.description)
            
            let tree = try grammar.parse(STLRSource)
            
            print(tree.description)
            
        } catch let error as ProcessingError {
            XCTFail("Unexpected processing error")
            print(error.debugDescription)
        } catch {
            XCTFail("Unexpected error")
            print(error.localizedDescription)
        }
    }
    
    func testTest() {
        do {
            let grammar = try stlrGrammar()
            
            print(grammar.description)

            let tree = try grammar.parse(source)
            
            print(tree.description)
            
        } catch let error as ProcessingError {
            XCTFail("Unexpected processing error")
            print(error.debugDescription)
        } catch {
            XCTFail("Unexpected error")
            print(error.localizedDescription)
        }
    }
}
