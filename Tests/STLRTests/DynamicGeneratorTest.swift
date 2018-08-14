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
@testable import STLR

fileprivate enum Tokens : Int, Token {
    case tokenA = 1
}

fileprivate enum TestError : Error {
    case expected(String)
}

class DynamicGeneratorTest: XCTestCase {

    let testGrammarName = "grammar STLRTest\n"
    
    fileprivate enum TT : Int, Token {
        case character = 1
        case xyz
        case whitespace
        case newline
        case whitespaceOrNewline
        case decimalDigits
        case letters
        case alphaNumeric
        case quote
        case comment
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        STLRScope.removeAllOptimizations()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        STLRScope.removeAllOptimizations()
    }

    /// Intended to test the fix for Issue #39
    func testGrammarRuleProductionIdentifierNonRecursive(){
        let stlr = testGrammarName+"""
        @forArrow  arrow  = ">" | "<"
        @forArrows arrows = arrow
        """
        
        let dynamicLanguage : Parser
        do {
            dynamicLanguage = try Parser(grammar:_STLR.build(stlr).grammar.dynamicRules)
        } catch {
            XCTFail("Failed to compile: \(error)")
            return
        }
        
        if let tree = try? AbstractSyntaxTreeConstructor().build(">", using: dynamicLanguage)  {
//            print(tree.description)
            XCTAssertTrue("\(tree.token)" == "arrows", "Root node should be arrows")
            XCTAssertTrue(tree.isSet(annotation: RuleAnnotation.custom(label: "forArrows")))
            guard let arrowNode = tree.nodeAtPath(["arrow"]) else {
                XCTFail("Arrow is not a child of arrows"); return
            }
            XCTAssertTrue(arrowNode.isSet(annotation: RuleAnnotation.custom(label: "forArrow")))
            XCTAssertEqual(tree.annotations.count, 1)
            XCTAssertEqual(arrowNode.annotations.count, 1)

        } else {
            XCTFail("Could not parse the test source using the generated language"); return
        }
    }
    
    /// Intended to test the fix for Issue #39
    func testGrammarRuleProductionIdentifierAnnotationNonRecursive(){
        let stlr = testGrammarName+"""
        @forArrows arrows = @token("arrow") @forArrow ">"
        """
        
        let dynamicLanguage : Parser
        do {
            dynamicLanguage = try Parser(grammar:_STLR.build(stlr).grammar.dynamicRules)
        } catch {
            XCTFail("Failed to compile: \(error)")
            return
        }
        
        if let tree = try? AbstractSyntaxTreeConstructor().build(">", using: dynamicLanguage)  {
//            print(tree.description)
            XCTAssertTrue("\(tree.token)" == "arrows", "Root node should be arrows")
            XCTAssertTrue(tree.isSet(annotation: RuleAnnotation.custom(label: "forArrows")))
            XCTAssertEqual(tree.annotations.count, 1)
            guard let arrowNode = tree.nodeAtPath(["arrow"]) else {
                XCTFail("Arrow is not a child of arrows"); return
            }
            XCTAssertTrue(arrowNode.isSet(annotation: RuleAnnotation.custom(label: "forArrow")))
            XCTAssertEqual(arrowNode.annotations.count, 1, arrowNode.annotations.description)
        } else {
            XCTFail("Could not parse the test source using the generated language"); return
        }
    }
    
    /// Intended to test the fix for Issue #39
    func testGrammarRuleProductionIdentifierRecursive(){
        let stlr = testGrammarName+"""
        @forArrow  arrow  = ">" arrows?
        @forArrows arrows = arrow
        """
        
        let dynamicLanguage : Parser
        do {
            dynamicLanguage = try Parser(grammar:_STLR.build(stlr).grammar.dynamicRules)
        } catch {
            XCTFail("Failed to compile: \(error)")
            return
        }
        
        do {
            let tree = try AbstractSyntaxTreeConstructor().build(">", using: dynamicLanguage)
            //           print(tree.description)
            XCTAssertTrue("\(tree.token)" == "arrows", "Root node should be arrows")
            XCTAssertTrue(tree.isSet(annotation: RuleAnnotation.custom(label: "forArrows")))
            guard let arrowNode = tree.nodeAtPath(["arrow"]) else {
                XCTFail("Arrow is not a child of arrows"); return
            }
            XCTAssertTrue(arrowNode.isSet(annotation: RuleAnnotation.custom(label: "forArrow")))
            XCTAssertEqual(tree.annotations.count, 1)
            XCTAssertEqual(arrowNode.annotations.count, 1)
        } catch {
            XCTFail("Could not parse: \(error)")
        }
    }
    
    /// Intended to test the fix for Issue #39
    func testGrammarRuleProductionIdentifierAnnotationRecursive(){
        let stlr = testGrammarName+"""
        @forArrows arrows = @token("arrow") @forArrow ">" arrows?
        """
        
        let dynamicLanguage : Parser
        do {
            dynamicLanguage = try Parser(grammar:_STLR.build(stlr).grammar.dynamicRules)
        } catch {
            XCTFail("Failed to compile: \(error)")
            return
        }
        
        do {
            let tree = try AbstractSyntaxTreeConstructor().build(">", using: dynamicLanguage)
            //           print(tree.description)
            XCTAssertTrue("\(tree.token)" == "arrows", "Root node should be arrows")
            XCTAssertTrue(tree.isSet(annotation: RuleAnnotation.custom(label: "forArrows")))
            guard let arrowNode = tree.nodeAtPath(["arrow"]) else {
                XCTFail("Arrow is not a child of arrows"); return
            }
            XCTAssertTrue(arrowNode.isSet(annotation: RuleAnnotation.custom(label: "forArrow")))
            XCTAssertEqual(tree.annotations.count, 1)
            XCTAssertEqual(arrowNode.annotations.count, 1)

        } catch {
            XCTFail("Could not parse: \(error)")
        }
   }
    
    /// Intended to test the fix for Issue #39
    func testGrammarCumulativeAttributes(){
        let stlr = testGrammarName+"""
        @one a   =  "a"
        ba  =   "b" @two a
        ca  =   "c" @three a
        """
        
        let dynamicLanguage : Parser
        do {
            let ast = try _STLR.build(stlr)
            dynamicLanguage = Parser(grammar:ast.grammar.dynamicRules)
        } catch {
            XCTFail("Failed to compile: \(error)")
            return
        }
        
        do {
            let tree = try AbstractSyntaxTreeConstructor().build("baca", using: dynamicLanguage)
            XCTAssertEqual("\(tree.children[0].token)","ba")
            XCTAssertTrue(tree.children[0].annotations.isEmpty)
            if tree.children[0].children.isEmpty {
                XCTFail("No children")
                return
            }
            XCTAssertEqual("\(tree.children[0].children[0].token)","a")
            XCTAssertNotNil(tree.children[0].children[0].annotations[RuleAnnotation.custom(label: "one")])
            XCTAssertNotNil(tree.children[0].children[0].annotations[RuleAnnotation.custom(label: "two")])
            XCTAssertEqual("\(tree.children[1].token)","ca")
            XCTAssertEqual("\(tree.children[1].children[0].token)","a")
            XCTAssertNotNil(tree.children[1].children[0].annotations[RuleAnnotation.custom(label: "one")])
            XCTAssertNotNil(tree.children[1].children[0].annotations[RuleAnnotation.custom(label: "three")])
        } catch {
            XCTFail("Could not parse the test source using the generated language: \(error)")
        }
    }
    
    /// Test to ensure trasnients just omit the token, but not the range
    /// and voids omit the token and the range
    func testGrammarTransientVoid(){
        let stlr = testGrammarName+"""
        v    = "v"
        t    = "t"
        vs   = @void      ":" v @void      ":" @transient v @void      ":"
        ts   = @transient ":" t @transient ":" @transient t @transient ":"
        """
        
        let dynamicLanguage : Parser
        do {
            dynamicLanguage = try Parser(grammar:_STLR.build(stlr).grammar.dynamicRules)
        } catch {
            XCTFail("Failed to compile: \(error)")
            return
        }
        
        if let tree = try? AbstractSyntaxTreeConstructor().build(":t:t::v:v::t:t:", using: dynamicLanguage)  {
//            print(tree.description)
            if tree.children.count < 3 {
                XCTFail("Expected 3 children")
                return
            }
            // Transient means it doesn't create child nodes, but is in the range
            XCTAssertEqual("\(tree.children[0].token)","ts")
            XCTAssertEqual(tree.children[0].children.count,1)
            XCTAssertEqual(tree.children[0].matchedString,":t:t:")
            // Void means it doesn't create child nodes, and is excluded from the range, but anything in the middle will be captured
            XCTAssertEqual("\(tree.children[1].token)","vs")
            XCTAssertEqual(tree.children[1].children.count,1)
            XCTAssertEqual(tree.children[1].matchedString,"v:v")
            // Transient means it doesn't create child nodes, but is in the range here testing at the end of the file
            XCTAssertEqual("\(tree.children[2].token)","ts")
            XCTAssertEqual(tree.children[2].matchedString,":t:t:")
            XCTAssertEqual(tree.children[2].children.count, 1)

        } else {
            XCTFail("Could not parse the test source using the generated language"); return
        }
    }

    /// Test of SLTR short hand for transient and void
    /// At this point I expect it to fail
    func testGrammarTransientVoidSyntacticSugar(){
        let stlr = testGrammarName+"""
        v    = "v"
        t    = "t"
        vs   = -":" v -":" ~v -":"
        ts   = ~":" t ~":" ~t ~":"
        """
        
        let dynamicLanguage : Parser
        do {
            dynamicLanguage = try Parser(grammar:_STLR.build(stlr).grammar.dynamicRules)
        } catch {
            XCTFail("Failed to compile: \(error)")
            return
        }
        
        if let tree = try? AbstractSyntaxTreeConstructor().build(":t:t::v:v::t:t:", using: dynamicLanguage)  {
 //           print(tree.description)
            if tree.children.count < 3 {
                XCTFail("Expected 3 children")
                return
            }
            // Transient means it doesn't create child nodes, but is in the range
            XCTAssertEqual("\(tree.children[0].token)","ts")
            XCTAssertEqual(tree.children[0].children.count,1)
            XCTAssertEqual(tree.children[0].matchedString,":t:t:")
            // Void means it doesn't create child nodes, and is excluded from the range, but anything in the middle will be captured
            XCTAssertEqual("\(tree.children[1].token)","vs")
            XCTAssertEqual(tree.children[1].children.count,1)
            XCTAssertEqual(tree.children[1].matchedString,"v:v")
            // Transient means it doesn't create child nodes, but is in the range here testing at the end of the file
            XCTAssertEqual("\(tree.children[2].token)","ts")
            XCTAssertEqual(tree.children[2].matchedString,":t:t:")
            XCTAssertEqual(tree.children[2].children.count, 1)
            
        } else {
            XCTFail("Could not parse the test source using the generated language"); return
        }
    }

    func testSimpleChoice(){
        
        guard let rule = try? "\"x\" | \"y\" | \"z\"".dynamicRule(.structural(token: TT.xyz)) else {
            XCTFail("Could not compile")
            return
        }
        
        let stream = TestableStream(source: "xyz", [rule])
        let iterator = stream.makeIterator()
        
        var count = 0
        while let token = iterator.next() {
            XCTAssert(token.token == TT.xyz, "Unexpected token \(token)")
            count += 1
        }
        
        XCTAssert(count == 3, "Incorrect number of tokens \(count)")
        
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors)")
    }
    
    
    func testSimpleSequence(){
        guard let rule = try? "\"x\" \"y\" \"z\"".dynamicRule(.structural(token:TT.xyz)) else {
            XCTFail("Could not compile")
            return
        }
        
        let stream  = TestableStream(source: "xyz", [rule])
        
        let iterator = stream.makeIterator()
        
        while let token = iterator.next() {
            XCTAssert(token.token == TT.xyz, "Unexpected token \(token)")
        }
        
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors)")
        
    }
    
    func testGroupAtRootOfExpression(){
        guard let rule = try? "(\"x\" \"y\" \"z\")".dynamicRule(.structural(token: TT.xyz)) else {
            XCTFail("Could not compile")
            return
        }
        
        let stream  = TestableStream(source: "xyzxyz", [rule])
        
        let iterator = stream.makeIterator()
        
        var count = 0
        while let token = iterator.next() {
            XCTAssert(token.token == TT.xyz, "Unexpected token \(token)")
            count += 1
        }
        
        XCTAssert(count == 2, "Incorrect tokens count \(count)")
        
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors)")
    }
    
    func testNestedGroups(){
        guard let rule = try? "(\"x\" (\"y\") \"z\")".dynamicRule(.structural(token: TT.xyz)) else {
            XCTFail("Could not compile")
            return
        }
        
        let stream = TestableStream(source: "xyzxyz", [rule])
        
        let iterator = stream.makeIterator()
        
        var count = 0
        while let token = iterator.next() {
            XCTAssert(token.token == TT.xyz, "Unexpected token \(token)")
            count += 1
        }
        
        XCTAssert(count == 2, "Incorrect tokens count \(count)")
        
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors)")
    }
    
    func testZeroOrOne() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        guard let rule = try? "(\"x\"? (\"y\")? \"z\")".dynamicRule(.structural(token: TT.xyz)) else {
            XCTFail("Could not compile")
            return
        }
        
        let stream = TestableStream(source: "xyzxzyz", [rule])
        
        let iterator = stream.makeIterator()
        
        var count = 0
        while let token = iterator.next() {
            XCTAssert(token.token == TT.xyz, "Unexpected token \(token)")
            count += 1
        }
        
        XCTAssert(count == 3, "Incorrect tokens count \(count)")
        
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors)")
    }

    func testOneOrMore() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        guard let rule = try? "\"xy\" \"z\"+".dynamicRule(.structural(token: TT.xyz)) else {
            XCTFail("Could not compile")
            return
        }
        
        let stream = TestableStream(source: "xyzzzzzzzzzxyzxy", [rule])
        
        let iterator = stream.makeIterator()
        
        var count = 0
        while let token = iterator.next() {
            XCTAssert(token.token == TT.xyz, "Unexpected token \(token)")
            count += 1
        }
        
        XCTAssert(count == 2, "Incorrect tokens count \(count)")
        
        XCTAssert(iterator.parsingErrors.count == 1, "\(iterator.parsingErrors)")
    }

    func testEscapedQuotedString() {
        // "\"" (!"\"")+ "\""
        guard let rule = try? "\"\\\"\" (!\"\\\"\")+ \"\\\"\"".dynamicRule(.structural(token: TT.quote)) else {
            XCTFail("Could not compile")
            return
        }
        
        let stream = TestableStream(source: "\"hello\"", [rule])
        
        let iterator = stream.makeIterator()
        
        var count = 0
        while let token = iterator.next() {
            XCTAssert(token.token == TT.quote, "Unexpected token \(token)")
            
            count += 1
        }
        
        XCTAssert(count == 1, "Incorrect tokens count \(count)")
        
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors)")
    }
    
    func testNotEscapedQuote() {
        // !"\""
        guard let rule = try? "!\"\\\"\"".dynamicRule(.structural(token: TT.letters)) else {
            XCTFail("Could not compile")
            return
        }
        
        print(rule)
        
        let stream = TestableStream(source: "ab\"c", [rule])
        
        let iterator = stream.makeIterator()
        
        var count = 0
        while let _ = iterator.next() {
            count += 1
        }
        
        XCTAssert(count == 2, "Incorrect tokens count \(count)")
        
        XCTAssert(iterator.parsingErrors.count == 1, "\(iterator.parsingErrors)")
    }
    
    func testEscapedQuote() {
        // "\""
        guard let rule = try? "\"\\\"\"".dynamicRule(.structural(token: TT.quote)) else {
            XCTFail("Could not compile")
            return
        }
        
        // \"
        let stream = TestableStream(source: "\"", [rule])
        
        let iterator = stream.makeIterator()
        
        var count = 0
        while let token = iterator.next() {
            XCTAssert(token.token == TT.quote, "Unexpected token \(token)")
            count += 1
        }
        
        XCTAssert(count == 1, "Incorrect tokens count \(count)")
        
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors)")
    }
    
    func testComment(){
        let stlrSource = "\"\\\\\\\\\" (!.newline)* .newline"
        
        guard let rule = try? stlrSource.dynamicRule(.structural(token: TT.comment)) else {
            XCTFail("Could not compile")
            return
        }
        
        let source = "\\\\ Wibble\n"
        
        var count = 0
        
        for node in TestableStream(source: source,[rule]){
            count += 1
            XCTAssert(node.token == TT.comment, "Got unexpected token \(node.token)")
        }
        
        XCTAssert(count == 1, "Incorrect tokens count \(count)")
    }
    
    func testZeroOrMore() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        guard let rule = try? "\"xy\" \"z\"*".dynamicRule(.structural(token: TT.xyz)) else {
            XCTFail("Could not compile")
            return
        }
        
        let stream = TestableStream(source: "xyzzzzzzzzzxyzxy", [rule])
        
        let iterator = stream.makeIterator()
        
        var count = 0
        while let token = iterator.next() {
            XCTAssert(token.token == TT.xyz, "Unexpected token \(token)")
            count += 1
        }
        
        XCTAssertEqual(3, count)
        
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors)")
    }
    
    
    func testSimpleGroup() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        guard let rule = try? "( \"x\" \"y\" ) (\"z\" | \"Z\")".dynamicRule(.structural(token: TT.xyz)) else {
            XCTFail("Could not compile")
            return
        }
        
        let stream = TestableStream(source: "xyzxyZ", [rule])
        
        let iterator = stream.makeIterator()
        
        var count = 0
        while let token = iterator.next() {
            XCTAssert(token.token == TT.xyz, "Unexpected token \(token)")
            count += 1
        }
        
        XCTAssert(count == 2, "Incorrect tokens count \(count)")
        
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors)")
    }
    
    func testNot() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        guard let rule = try? "!\"x\"".dynamicRule(.structural(token: TT.character)) else {
            XCTFail("Could not compile")
            return
        }
        
        let testSource = "ykfxd"
        
        let stream = TestableStream(source: testSource, [rule])
        
        let iterator = stream.makeIterator()
        var count = 0
        while let node = iterator.next() {
            let captured = "\(testSource.unicodeScalars[node.range])"
            XCTAssert(node.token == TT.character, "Unexpected token \(node) \(captured)")
            XCTAssert(captured != "x", "Unexpected capture \(captured)")
            if node.token == TT.character {
                count+=1
            }
        }

        XCTAssert(count == 3, "Expected 3 tokens but got \(count)")
        XCTAssert(iterator.parsingErrors.count == 1, "\(iterator.parsingErrors)")
    }

    func testCheckDirectLeftHandRecursion(){
        let source =    """
                        grammar recursionCheck
                        rhs =  rhs "|" rhs
                        """
        do {
            let stlr = try _STLR.build(source)
            for rule in stlr.grammar.rules {
                XCTAssertTrue(stlr.grammar.isDirectLeftHandRecursive(identifier: rule.identifier))
            }
        } catch {
            XCTFail("Failed to compile: \(error)")
        }
    }
    
    
    func testCheckLeftHandRecursion(){
        // rhs = "|" expr \n expr = ">" rhs
        let source =    """
                        grammar recursionCheck
                        rhs = "|" expr
                        expr= ">" rhs
                        """
        let stlr : _STLR
        do {
            stlr = try _STLR.build(source)
        } catch {
            XCTFail("Failed to compile: \(error)")
            return
        }
        
        for rule in stlr.grammar.rules {
            XCTAssertTrue(stlr.grammar.isLeftHandRecursive(identifier: rule.identifier))
            XCTAssertFalse(stlr.grammar.isDirectLeftHandRecursive(identifier: rule.identifier))
        }
    }
    
    func testIllegalLeftHandRecursionDetection(){
        let source = "grammar recursionCheck\n rhs = rhs\n expr = lhs\n lhs = (expr \" \")\n"

        let stlr : _STLR
        do {
            stlr = try _STLR.build(source)
        } catch {
            XCTFail("Failed to compile: \(error)")
            return
        }

        for _ in stlr.grammar.rules {
            for rule in stlr.grammar.rules {
                do {
                    try stlr.grammar.validate(rule:rule)
                    XCTFail("Validation should have failed")
                } catch {
                    
                }
            }
        }
    }
    
    func testDirectLeftHandRecursion(){
        let source = testGrammarName+"rhs = (\">\" rhs) | (\"<\" rhs)"

        let stlr : _STLR
        do {
            stlr = try _STLR.build(source)
        } catch {
            XCTFail("Failed to compile: \(error)")
            return
        }

        
        
        //To stop the stack overflow for now, but it's the right line
        XCTAssert(!stlr.grammar.dynamicRules.isEmpty)
        var rules = [Rule]()
        for rule in stlr.grammar.rules {
            if let parserRule = stlr.grammar.dynamicRules.filter({ (compiledRule) -> Bool in
                if case let .structural(token) = compiledRule.behaviour.kind, "\(token)" == rule.identifier{
                    return true
                }
                return false
            }).first {
                rules.append(parserRule)
//                print("\(parserRule)")
            } else {
                XCTFail("Rule has missing identifier or rule")
            }
            
            do {
                try stlr.grammar.validate(rule:rule)
            } catch {
                XCTFail("Rule failed to validate")
            }
        }
        
        XCTAssert(rules.count == 1, "Got \(rules.count) rules")
    }
    
    func testConsume() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        guard let rule = try? "(\" \"*)- \"x\"".dynamicRule(.structural(token: TT.character)) else {
            XCTFail("Could not compile")
            return
        }
        
        let testSource = "    x"
        
        let stream = TestableStream(source: testSource, [rule])
        
        let iterator = stream.makeIterator()
        var count = 0
        while let node = iterator.next() {
            let captured = "\(testSource.unicodeScalars[node.range])"
            XCTAssert(node.token == TT.character, "Unexpected token \(node) \(captured)")
            XCTAssert(captured != "x", "Unexpected capture \(captured)")
            if node.token == TT.character {
                count+=1
            }
        }
        
        XCTAssert(count == 1, "Expected 1 tokens but got \(count)")
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors)")
    }
    
    
    func testEscapedTerminal() {
        guard let rule = try? "\"\\\"\"".dynamicRule(.structural(token: TT.character)) else {
            XCTFail("Could not compile")
            return
        }
        
        let stream = TestableStream(source: "\"", [rule])
        
        let iterator = stream.makeIterator()
        
        while let token = iterator.next() {
            XCTAssert(token.token == TT.character, "Unexpected token \(token)")
        }
        
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors.map({"\($0)"}).joined(separator: ", "))")
    }
    
    func testSimpleLookahead() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        guard let rule = try? "\"x\"".dynamicRule(.structural(token: TT.character)) else {
            XCTFail("Could not compile")
            return
        }
        let stream = TestableStream(source: "x", [rule])
        
        let iterator = stream.makeIterator()
        
        while let token = iterator.next() {
            XCTAssert(token.token == TT.character, "Unexpected token \(token)")
        }
        
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors)")
    }
    
    func testSimpleTerminal() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        guard let rule = try? "\"x\"".dynamicRule(.structural(token: TT.character)) else {
            XCTFail("Could not compile")
            return
        }
        let stream = TestableStream(source: "x", [rule])

        let iterator = stream.makeIterator()
        
        while let token = iterator.next() {
            XCTAssert(token.token == TT.character, "Unexpected token \(token)")
        }
        
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors)")
    }
    
    func testCharacterSets() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        guard let rule = try? ".whitespace+".dynamicRule(.structural(token: TT.whitespace)) else {
            XCTFail("Could not compile")
            return
        }
        
        let stream = TestableStream(source: "    \t    ", [rule])
        
        let iterator = stream.makeIterator()
        
        var count = 0
        while let node = iterator.next() {
            XCTAssert(node.token == TT.whitespace, "Unexpected token \(node.token)[\(node.token.rawValue)]")
            count += 1
        }
        
        XCTAssert(count == 1)
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors)")
    }
    
    func testCharacterRange() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        guard let rule = try? "\"0\"...\"9\"".dynamicRule(.structural(token: TT.decimalDigits)) else {
            XCTFail("Could not compile")
            return
        }
        
        let stream = TestableStream(source: "0123456789x", [rule])
        
        let iterator = stream.makeIterator()
        
        var count = 0
        while let token = iterator.next() {
            XCTAssert(token.token == TT.decimalDigits, "Unexpected token \(token)")
            count += 1
        }
        
        XCTAssert(count == 10)
        XCTAssert(iterator.parsingErrors.count == 1, "\(iterator.parsingErrors)")
    }

    func generatedStringSerialization(for source:String, desiredIdentifier identifierName:String)throws ->String {
        let grammar : _STLR.Grammar
        
        do {
            grammar = try _STLR.build("grammar Test\n"+source).grammar
        } catch {
            XCTFail("Failed to compile: \(error)")
            return "Could not compile"
        }
        
        guard let rule = grammar.dynamicRules.filter({ (compiledRule) -> Bool in
            if case let .structural(token) = compiledRule.behaviour.kind, "\(token)" == identifierName{
                return true
            }
            return false
        }).first else {
            return "Could not create rule"
        }
        
        let swift = "\(rule)".trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")
        
        return swift
    }
    
    func generatedStringSerialization(for source:String, desiredRule rule: Int = 0)throws ->String {
        let ast : _STLR.Grammar
        do {
            ast = try _STLR.build("grammar Test\n"+source).grammar
        } catch {
            throw TestError.expected("compilation but failed with \(error)")
        }
        
        if ast.rules.count <= rule {
            throw TestError.expected("at least \(rule + 1) rule, but got \(ast.rules.count)")
        }
        
        let dynamicRules = ast.dynamicRules
        
        if rule >= dynamicRules.count {
            throw TestError.expected("At least \(rule+1) dynamic rules, but have \(dynamicRules.count)")
        }
        
        let rule = dynamicRules[rule]
        let swift = "\(rule)".trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")
        
        return swift
    }
    
    func testPredefinedCharacterSet() {
        do {
            let result = try generatedStringSerialization(for: "letter = @error(\"error\").whitespace")
            
            XCTAssert(result == "letter = @error(\"error\") .whitespace", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testCustomCharacterSet() {
        do {
            let result = try generatedStringSerialization(for: "letter = @error(\"error\") \"a\"...\"z\"")
            
            XCTAssert(result == "letter = @error(\"error\") .customCharacterSet", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testSimplestPossibleGrammar(){
        do {
            let result = try generatedStringSerialization(for: "a=\"a\"")
            
            XCTAssert(result == "a = \"a\"", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testTerminal(){
        do {
            let result = try generatedStringSerialization(for: "letter = @error(\"error\") \"hello\"")
            
            XCTAssert(result == "letter = @error(\"error\") \"hello\"", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testRegularExpression(){
        do {
            let result = try generatedStringSerialization(for: "letter = @error(\"error\") /hello/ ")
            
            XCTAssert(result == "letter = @error(\"error\") /hello/", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testSingleCharacterTerminal(){
        do {
            let result = try generatedStringSerialization(for: "letter = @error(\"error\") \"h\"")
            
            XCTAssert(result == "letter = @error(\"error\") \"h\"", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testTerminalChoiceWithIndividualAnnotations(){
        do {
            let reference = "letter = (@error(\"error a\") \"a\" | @error(\"error b\") \"b\" | @error(\"error c\") \"c\")"
            let result = try generatedStringSerialization(for: "letter = @error(\"error a\") \"a\"| @error(\"error b\")\"b\"| @error(\"error c\") \"c\"").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")
            
            XCTAssertEqual(reference, result)
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testTerminalChoiceWithIndividualAnnotationsOptimized(){
        STLRScope.register(optimizer: InlineIdentifierOptimization())
        STLRScope.register(optimizer: CharacterSetOnlyChoiceOptimizer())
        do {
            let reference = "letter = (@error(\"error a\") \"a\" | @error(\"error b\") \"b\" | @error(\"error c\") \"c\")"
            let result = try generatedStringSerialization(for: "letter = @error(\"error a\") \"a\"| @error(\"error b\")\"b\"| @error(\"error c\") \"c\"").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")
            
            
            XCTAssertEqual(reference, result)
            
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testTerminalChoice(){
        do {
            let result = try generatedStringSerialization(for: "letter = @error(\"error\") (\"a\" | \"b\" | \"c\")")
            
            XCTAssertEqual("letter = @error(\"error\") ~(\"a\" | \"b\" | \"c\")", result)
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testTerminalSequence(){
        do {
            let result = try generatedStringSerialization(for: "letter = @error(\"error\") (\"a\" \"b\" \"c\")")
            let reference = "letter = @error(\"error\") ~(\"a\" \"b\" \"c\")"
            XCTAssertEqual(result, reference)
            
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testTerminalSequenceWithIndividualAnnotations(){
        do {
            let result = try generatedStringSerialization(for: "letter = @error(\"error a\") \"a\"  @error(\"error b\")\"b\"  @error(\"error c\") \"c\"").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")
            
            XCTAssert(result == "letter = (@error(\"error a\") \"a\" @error(\"error b\") \"b\" @error(\"error c\") \"c\")", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testAnnotatedNestedIdentifiers(){
        do {
            let source = """
            @error("a internal") a = "a"
            aa = @error("error a1") a @error("error a2") a
            """

            let aRule =  try generatedStringSerialization(for: source, desiredRule: 0)
            XCTAssertEqual(aRule,"aa = (@error(\"error a1\") a = \"a\" @error(\"error a2\") a = \"a\")")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testMergedAnnotationOnIdentifierReference(){
        do {
            let result = try generatedStringSerialization(for: "@error(\"expected a\")a = @error(\"inner a\") \"a\"\naa = a @error(\"error a2\") a", desiredRule: 1)
            
            XCTAssert(result == "tokenA =  (a = @error(\"expected a\") \"a\" a = @error(\"error a2\") \"a\")", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testAnnotationOnQuantifier(){
        do {
            let result = try generatedStringSerialization(for: "word = @error(\"Expected a letter\") .letter+", desiredRule: 0)
            
            XCTAssert(result == "word = @error(\"Expected a letter\") .letter+", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testMergedAnnotationOnIdentifierReferenceWithQuantifiers(){
        do {
            let result = try generatedStringSerialization(for: "@error(\"expected a\")a = @error(\"inner a\") \"a\"\naa = a+ \" \" @error(\"error a2\") a+", desiredRule: 1)
            
            XCTAssert(result == "a =  (@error(\"expected a\") a = @error(\"expected a\") \"a\"+  \" \" @error(\"error a2\") a = @error(\"expected a\") \"a\"+)", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testRepeatedReference(){
        do {
            let result = try generatedStringSerialization(for: "@error(\"Expected a1\") a1 = \"a\" @error(\"Expected 1\") \"1\"\ndoubleA1 = a1 @error(\"Expected second a1\") a1", desiredRule: 1)
            
            XCTAssert(result == "a1 =  (a1 = @error(\"Expected a1\") ( \"a\" @error(\"Expected 1\") \"1\") a1 = @error(\"Expected second a1\") ( \"a\" @error(\"Expected 1\") \"1\"))", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
}
