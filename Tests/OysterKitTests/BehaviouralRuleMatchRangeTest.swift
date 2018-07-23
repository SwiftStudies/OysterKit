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
@testable import OysterKit

class BehaviourRuleMatchRangeTest : XCTestCase {
    
    
    func testVoidTransientTokenTransientVoid() {
        let voidRule = ClosureRule(with: Behaviour(.skipping, cardinality: .one)) { (lexer, ir) in
            try lexer.scan(terminal: "\"")
        }
        let transientRule = ClosureRule(with: Behaviour(.scanning, cardinality: .oneOrMore)) { (lexer, ir) in
            try lexer.scan(terminal: " ")
        }
        let tokenRule = ClosureRule(with: Behaviour(.structural(token: LabelledToken(withLabel: "stringBody")), cardinality: .oneOrMore)) { (lexer, ir) in
            try lexer.scan(oneOf: CharacterSet.letters)
        }
        
        let source = """
                     "   stringBody   "
                     """
        
        let lexer = Lexer(source: source)
        let ir = AbstractSyntaxTreeConstructor(with: source)

        let root = LabelledToken(withLabel: "root")
        
        do {
            lexer.mark()
            ir.willEvaluate(token: root, at: lexer.index)
                _ = try voidRule.match(with: lexer, for: ir)
                _ = try transientRule.match(with: lexer, for: ir)
                _ = try tokenRule.match(with: lexer, for: ir)
                _ = try transientRule.match(with: lexer, for: ir)
                _ = try voidRule.match(with: lexer, for: ir)
            let context = lexer.proceed()
            ir.didEvaluate(token: root, annotations: [:], matchResult: MatchResult.success(context: context))

            let tree = try ir.generate(HomogenousTree.self)
            XCTAssertEqual("   stringBody   ", tree.matchedString)
            XCTAssertEqual("stringBody", "\(tree.children[0].token)")
        } catch {
            XCTFail("Unexpected error: \(error)" )
        }
    }
}
