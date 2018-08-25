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

import XCTest
@testable import OysterKit
import STLR

class TestAbstractSyntaxTree: XCTestCase {

    func testParseFailing(){
        do {
            let source = "grammar Test\nwibble = .letters"
            
            _ = try _STLR.build(source)
            XCTFail("Expected error")

        } catch {
            // Pass
        }
    }

    func testNoRealRule(){
        do {
            let source = ""
            
            _ = try _STLR.build(source)
            XCTFail("Expected error")
        } catch {
            //Pass
        }
    }

    func testConstruction() {
        let exampleString = "Hello World"
        let worldNode = AbstractSyntaxTreeConstructor.IntermediateRepresentationNode(for: LabelledToken(withLabel: "world"), at: exampleString.range(of: "World")!, annotations: [
            RuleAnnotation.void : RuleAnnotationValue.set,
            RuleAnnotation.custom(label: "Integer") : RuleAnnotationValue.int(10),
            RuleAnnotation.custom(label: "Boolean") : RuleAnnotationValue.bool(true),
            RuleAnnotation.custom(label: "String") : RuleAnnotationValue.string("value"),
            ])
        let helloNode = AbstractSyntaxTreeConstructor.IntermediateRepresentationNode(for: LabelledToken(withLabel: "hello"), at: exampleString.range(of: "Hello World")!, children: [worldNode], annotations: [
            RuleAnnotation.void : RuleAnnotationValue.set
            ])

        do {
            let homogenousTree = try HomogenousTree(with: helloNode, from: exampleString)

            XCTAssertEqual(homogenousTree.annotations, [RuleAnnotation.void : RuleAnnotationValue.set])
            XCTAssertEqual(homogenousTree.children[0].annotations, [
                RuleAnnotation.void : RuleAnnotationValue.set,
                RuleAnnotation.custom(label: "Integer") : RuleAnnotationValue.int(10),
                RuleAnnotation.custom(label: "Boolean") : RuleAnnotationValue.bool(true),
                RuleAnnotation.custom(label: "String") : RuleAnnotationValue.string("value"),
                ])            
        } catch {
            XCTFail("AST contruction resulted in: \(error)")
        }        
    }

}
