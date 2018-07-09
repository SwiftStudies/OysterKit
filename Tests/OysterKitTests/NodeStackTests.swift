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

struct TestNode : Node, CustomStringConvertible {
    var token: Token
    
    var range: Range<String.UnicodeScalarView.Index>
    
    var annotations: [RuleAnnotation : RuleAnnotationValue]
    
    var children: [TestNode]
    
    init(for token: Token, at range: Range<String.UnicodeScalarView.Index>, annotations: [RuleAnnotation : RuleAnnotationValue]) {
        self.token = token
        self.range = range
        self.annotations = annotations
        children = [TestNode]()
    }
    
    var description: String {
        return "\(token)"
    }
}

class NodeStackTests: XCTestCase {

    func testNodeStackDepth() {
        let stack = NodeStack<TestNode>()
        
        XCTAssertEqual(1, stack.depth)
        stack.push()
        XCTAssertEqual(2, stack.depth)
        let _ = stack.pop()
        XCTAssertEqual(1, stack.depth)
    }
    
    func testAll(){
        let source = "Hello world good to meet you"
        let stack = NodeStack<TestNode>()
        
        stack.top?.append(TestNode(for: LabelledToken(withLabel: "hello"), at: source.range(of: "Hello")!, annotations: [:]))
        stack.push()
        stack.top?.append(TestNode(for: LabelledToken(withLabel: "world"), at: source.range(of: "world")!, annotations: [:]))
        stack.top?.append(TestNode(for: LabelledToken(withLabel: "good"), at: source.range(of: "good")!, annotations: [:]))
        
        //Key thing is 2 nodes first to make sure it has been reversed
        XCTAssertEqual(stack.all.description,"[2 nodes, with [] errors, 1 nodes, with [] errors]")
    }
    
    func testArrayAppend(){
        var     setLikeArray = [Int]()
        
        XCTAssertEqual(0, setLikeArray.count)
        setLikeArray.append(unique: 0)
        XCTAssertEqual(1, setLikeArray.count)
        setLikeArray.append(unique: 0)
        XCTAssertEqual(1, setLikeArray.count)
        setLikeArray.append(unique: 1)
        XCTAssertEqual(2, setLikeArray.count)
        XCTAssertTrue(setLikeArray.contains(1))
        XCTAssertTrue(setLikeArray.contains(0))
    }

    func testAddError(){
        let source = "Hello"
        let nodeStack = NodeStack<TestNode>()
        
        nodeStack.top?.addError(error: LanguageError.scanningError(at: source.startIndex..<source.endIndex, message: "Top Error"))
        XCTAssertEqual(1, nodeStack.top!.errors.count)
        nodeStack.push()
        nodeStack.top?.addError(error: LanguageError.scanningError(at: source.endIndex..<source.endIndex, message: "Top Error"))
        nodeStack.top?.addError(error: LanguageError.parsingError(at: source.startIndex..<source.startIndex, message: "Top Error"))
        //Should not be added as one already exists
        nodeStack.top?.addError(error: LanguageError.warning(at: source.startIndex..<source.startIndex, message: "Top Error"))
        XCTAssertEqual(2, nodeStack.top!.errors.count)
        let _ = nodeStack.pop()
        XCTAssertEqual(1, nodeStack.top!.errors.count)
    }
    
    func testAddErrors(){
        let source = "Hello"
        let nodeStack = NodeStack<TestNode>()
        
        nodeStack.top?.addError(error: LanguageError.scanningError(at: source.startIndex..<source.endIndex, message: "Top Error"))
        nodeStack.top?.addErrors([
            LanguageError.scanningError(at: source.endIndex..<source.endIndex, message: "Top Error"),
            LanguageError.scanningError(at: source.endIndex..<source.endIndex, message: "Top Error"),
            LanguageError.parsingError(at: source.startIndex..<source.startIndex, message: "Top Error"),
            ])
        XCTAssertEqual(3, nodeStack.top!.errors.count)

        nodeStack.top?.flushErrors()
        XCTAssertEqual(0, nodeStack.top!.errors.count)
    }
    
    func testDescription(){
        let source = "Hello"
        let nodeStack = NodeStack<TestNode>()

        nodeStack.top?.append(TestNode(for: LabelledToken(withLabel: "hello"), at: source.startIndex..<source.endIndex, annotations: [
            RuleAnnotation.void : RuleAnnotationValue.set
            ]))
        
        nodeStack.push()
        nodeStack.top?.addErrors([
            LanguageError.scanningError(at: source.endIndex..<source.endIndex, message: "Top Error"),
            LanguageError.scanningError(at: source.endIndex..<source.endIndex, message: "Top Error"),
            LanguageError.parsingError(at: source.startIndex..<source.startIndex, message: "Top Error"),
            ])

        XCTAssertEqual(nodeStack.description, "NodeStack: \n0 nodes, with [Top Error from 5 to 5, Top Error from 0 to 0] errors\n1 nodes, with [] errors\n")
        
    }
}
