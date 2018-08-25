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
import OysterKit
import STLR

class GrammarStructureTeset: XCTestCase {
    
    
    func testEnumIdentification() {
        do {
            let source =    """
                        grammar Test
                        quantifier = "*" | "+" | "?" | "-"
                        """
            
            let scope     = try _STLR.build(source)
            XCTAssertEqual(1, scope.grammar.rules.count,"Expected compliation into 1 rule")
            let grammar   = _GrammarStructure(for: scope, accessLevel: "internal")
            
            guard let quantifierNode = grammar.structure.children.first, grammar.structure.children.count == 1 else {
                XCTFail("Expected one child")
                return
            }
            XCTAssertEqual("quantifier", quantifierNode.name)
            XCTAssertEqual(_GrammarStructure.DataType.enumeration, quantifierNode.type)

        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testReferencedEnumIdentification() {
        let source =    """
                        grammar Test
                        quantifier = "*" | "+" | "?" | "-"
                        quantified = .letter+ quantifier
                        """

        do {
            let scope     = try _STLR.build(source)
            XCTAssertEqual(2, scope.grammar.rules.count,"Expected compliation into 2 rules")
            let grammar   = _GrammarStructure(for: scope, accessLevel: "internal")
            
            guard let quantifierNode = grammar.structure.children.first, grammar.structure.children.count == 2 else {
                XCTFail("Expected two children")
                return
            }
            XCTAssertEqual("quantifier", quantifierNode.name)
            XCTAssertEqual(_GrammarStructure.DataType.enumeration, quantifierNode.type)

        } catch {
            XCTFail("Unexpected error")
        }
    }

    
}


