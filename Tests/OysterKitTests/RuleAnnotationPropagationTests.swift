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
import STLR
import OysterKit
@testable import TestingSupport

class RuleAnnotationPropagationTests: XCTestCase {

    func testTerminal() {
        do {
            let source = "term "
            let token = AnnotationTestTokens.terminal
            let tree = try [token.rule].parse(source)
            let annotations : RuleAnnotations = [.custom(label: "terminal") : .bool(true)]

            XCTAssertEqual(annotations, tree.annotations)
            XCTAssertEqual("\(tree.token)", "\(token)")
            XCTAssertEqual(tree.matchedString, source)
            print(tree)
        } catch let error as ProcessingError {
            XCTFail(error.description)
            print(error.debugDescription)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testGroup() {
        do {
            let source = "term "
            let token = AnnotationTestTokens.group
            let tree = try [token.rule].parse(source)
            let annotations : RuleAnnotations = [.custom(label: "group") : .bool(true)]
            
            XCTAssertEqual(annotations, tree.annotations)
            XCTAssertEqual("\(tree.token)", "\(token)")
            XCTAssertEqual(tree.matchedString, source)
            print(tree)
        } catch let error as ProcessingError {
            XCTFail(error.description)
            print(error.debugDescription)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testIdentifier() {
        do {
            let source = "term "
            let token = AnnotationTestTokens.identifier
            let tree = try [token.rule].parse(source)
            let annotations : RuleAnnotations = [.custom(label: "identifier") : .bool(true)]
            
            XCTAssertEqual(annotations, tree.annotations)
            XCTAssertEqual("\(tree.token)", "\(token)")
            XCTAssertEqual(tree.matchedString, source)
            print(tree)
        } catch let error as ProcessingError {
            XCTFail(error.description)
            print(error.debugDescription)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testNormal() {
        do {
            let source = "term term term recurse recurse recurse "
            let token = AnnotationTestTokens.normal
            let tree = try [token.rule].parse(source)
            let annotations : RuleAnnotations = [:]
            
            XCTAssertEqual(annotations, tree.annotations)
            XCTAssertEqual("\(tree.token)", "\(token)")
            XCTAssertEqual(tree.matchedString, source)
            print(tree)
        } catch let error as ProcessingError {
            XCTFail(error.description)
            print(error.debugDescription)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testOverrides() {
        do {
            let source = "term term term recurse recurse recurse "
            let token = AnnotationTestTokens.overrides
            let tree = try [token.rule].parse(source)
            let annotations : RuleAnnotations = [:]
            
            XCTAssertEqual(annotations, tree.annotations)
            XCTAssertEqual("\(tree.token)", "\(token)")
            XCTAssertEqual(tree.matchedString, source)
            print(tree)
        } catch let error as ProcessingError {
            XCTFail(error.description)
            print(error.debugDescription)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
}
