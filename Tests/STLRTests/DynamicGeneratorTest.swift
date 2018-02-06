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


@available(swift, deprecated: 4.0, message: "TEST DISABLED PENDING IMPLEMENTATION")
func testForFutureEnhancement(gitHubId id:Int)->Bool{
    print("WARNING: Test for https://github.com/SwiftStudies/OysterKit/issues/\(id) is currently disabled. Enable when implemented")
    return true
}

private enum Tokens : Int, Token {
    case tokenA = 1
}

private enum TestError : Error {
    case expected(String)
}

class DynamicGeneratorTest: XCTestCase {

    private enum TT : Int, Token {
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
        let stlr = """
        @forArrow  arrow  = ">" | "<"
        @forArrows arrows = arrow
        """
        
        guard let dynamicLangauage = STLRParser(source: stlr).ast.runtimeLanguage else {
            XCTFail("Could not compile the grammar under test"); return
        }
        
        if let tree = try? AbstractSyntaxTreeConstructor().build(">", using: dynamicLangauage)  {
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
        let stlr = """
        @forArrows arrows = @token("arrow") @forArrow ">"
        """
        
        guard let dynamicLangauage = STLRParser(source: stlr).ast.runtimeLanguage else {
            XCTFail("Could not compile the grammar under test"); return
        }
        
        if let tree = try? AbstractSyntaxTreeConstructor().build(">", using: dynamicLangauage)  {
//            print(tree.description)
            XCTAssertTrue("\(tree.token)" == "arrows", "Root node should be arrows")
            XCTAssertTrue(tree.isSet(annotation: RuleAnnotation.custom(label: "forArrows")))
            XCTAssertEqual(tree.annotations.count, 1)
            guard let arrowNode = tree.nodeAtPath(["arrow"]) else {
                XCTFail("Arrow is not a child of arrows"); return
            }
            XCTAssertTrue(arrowNode.isSet(annotation: RuleAnnotation.custom(label: "forArrow")))
            XCTAssertEqual(arrowNode.annotations.count, 1)
        } else {
            XCTFail("Could not parse the test source using the generated language"); return
        }
    }
    
    /// Intended to test the fix for Issue #39
    func testGrammarRuleProductionIdentifierRecursive(){
        let stlr = """
        @forArrow  arrow  = ">" arrows?
        @forArrows arrows = arrow
        """
        
        guard let dynamicLangauage = STLRParser(source: stlr).ast.runtimeLanguage else {
            XCTFail("Could not compile the grammar under test"); return
        }
        
        if let tree = try? AbstractSyntaxTreeConstructor().build(">", using: dynamicLangauage)  {
//           print(tree.description)
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
    func testGrammarRuleProductionIdentifierAnnotationRecursive(){
        let stlr = """
        @forArrows arrows = @token("arrow") @forArrow ">" arrows?
        """
        
        guard let dynamicLangauage = STLRParser(source: stlr).ast.runtimeLanguage else {
            XCTFail("Could not compile the grammar under test"); return
        }
        
        if let tree = try? AbstractSyntaxTreeConstructor().build(">", using: dynamicLangauage)  {
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
    func testGrammarCumulativeAttributes(){
        let stlr = """
        a   =   @one "a"
        ba  =   "b" @two a
        ca  =   "c" @three a
        """
        
        guard let dynamicLangauage = STLRParser(source: stlr).ast.runtimeLanguage else {
            XCTFail("Could not compile the grammar under test"); return
        }
        
        do {
            let tree = try AbstractSyntaxTreeConstructor().build("baca", using: dynamicLangauage)
//            print(tree.description)
            XCTAssertEqual("\(tree.children[0].token)","ba")
            XCTAssertTrue(tree.children[0].annotations.isEmpty)
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
        let stlr = """
        v    = "v"
        t    = "t"
        vs   = @void      ":" v @void      ":" @transient v @void      ":"
        ts   = @transient ":" t @transient ":" @transient t @transient ":"
        """
        
        guard let dynamicLangauage = STLRParser(source: stlr).ast.runtimeLanguage else {
            XCTFail("Could not compile the grammar under test"); return
        }
        
        if let tree = try? AbstractSyntaxTreeConstructor().build(":t:t::v:v::t:t:", using: dynamicLangauage)  {
//            print(tree.description)
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
        if testForFutureEnhancement(gitHubId: 40){
            return
        }
        
        let stlr = """
        v    = "v"
        t    = "t"
        vs   = ":"- v ":"- ~v ":"-
        ts   = ":"~ t ":"~ t~ ":"~
        """
        
        guard let dynamicLangauage = STLRParser(source: stlr).ast.runtimeLanguage else {
            XCTFail("Could not compile the grammar under test"); return
        }
        
        if let tree = try? AbstractSyntaxTreeConstructor().build(":t:t::v:v::t:t:", using: dynamicLangauage)  {
 //           print(tree.description)
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
        guard let rule = "\"x\" | \"y\" | \"z\"".dynamicRule(token: TT.xyz) else {
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
        guard let rule = "\"x\" \"y\" \"z\"".dynamicRule(token: TT.xyz) else {
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
        guard let rule = "(\"x\" \"y\" \"z\")".dynamicRule(token: TT.xyz) else {
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
        guard let rule = "(\"x\" (\"y\") \"z\")".dynamicRule(token: TT.xyz) else {
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
        guard let rule = "(\"x\"? (\"y\")? \"z\")".dynamicRule(token: TT.xyz) else {
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
        guard let rule = "\"xy\" \"z\"+".dynamicRule(token: TT.xyz) else {
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
        // "\"" ("\""!)+ "\""
        guard let rule = "\"\\\"\" (!\"\\\"\")+ \"\\\"\"".dynamicRule(token: TT.quote) else {
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
        // "\""!
        guard let rule = "!\"\\\"\"".dynamicRule(token: TT.letters) else {
            XCTFail("Could not compile")
            return
        }
        
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
        guard let rule = "\"\\\"\"".dynamicRule(token: TT.quote) else {
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
        let stlrSource = "\"\\\\\\\\\" (!.newlines)* .newlines"
        
        guard let rule = stlrSource.dynamicRule(token: TT.comment) else {
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
        guard let rule = "\"xy\" \"z\"*".dynamicRule(token: TT.xyz) else {
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
        
        XCTAssert(count == 3, "Incorrect tokens count \(count)")
        
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors)")
    }
    
    
    func testSimpleGroup() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        guard let rule = "( \"x\" \"y\" ) (\"z\" | \"Z\")".dynamicRule(token: TT.xyz) else {
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
        guard let rule = "!\"x\"".dynamicRule(token: TT.character) else {
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
        let source = "rhs =  rhs \"|\" rhs ; "
        let stlr = STLRParser(source: source)
        
        for rule in stlr.ast.rules {
            XCTAssert(rule.directLeftHandRecursive)
        }
    }
    
    
    func testCheckLeftHandRecursion(){
        // rhs = "|" expr \n expr = ">" rhs
        let source = "rhs = \"|\" expr \nexpr= \">\" rhs "
        let stlr = STLRParser(source: source)
        
        for rule in stlr.ast.rules {
            XCTAssert(rule.leftHandRecursive)
            XCTAssert(!rule.directLeftHandRecursive)
        }
    }
    
    func testIllegalLeftHandRecursionDetection(){
        let source = "rhs = rhs\n expr = lhs\n lhs = (expr \" \")\n"
        let stlr = STLRParser(source: source)
        
        for _ in stlr.ast.rules {
            for rule in stlr.ast.rules {
                do {
                    try rule.validate()
                    XCTFail("Validation should have failed")
                } catch {
                    
                }
            }
        }
    }
    
    func testDirectLeftHandRecursion(){
        let source = "rhs = (\">\" rhs) | (\"<\" rhs)"
        let stlr = STLRParser(source: source)
        
        
        
        //To stop the stack overflow for now, but it's the right line
        XCTAssert(stlr.ast.runtimeLanguage != nil)
        var rules = [Rule]()
        for rule in stlr.ast.rules {
            if let identifier = rule.identifier, let parserRule = rule.rule(from:stlr.ast, creating: identifier.token) {
                rules.append(parserRule)
//                print("\(parserRule)")
            } else {
                XCTFail("Rule has missing identifier or rule")
            }
            
            do {
                try rule.validate()
            } catch {
                XCTFail("Rule should failed to validate")
            }
        }
        
        XCTAssert(rules.count == 1, "Got \(rules.count) rules")
    }
    
    func testConsume() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        guard let rule = "(\" \"*)- \"x\"".dynamicRule(token: TT.character) else {
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
        guard let rule = "\"\\\"\"".dynamicRule(token: TT.character) else {
            XCTFail("Could not compile")
            return
        }
        
        let stream = TestableStream(source: "\"", [rule])
        
        let iterator = stream.makeIterator()
        
        while let token = iterator.next() {
            XCTAssert(token.token == TT.character, "Unexpected token \(token)")
        }
        
        XCTAssert(iterator.parsingErrors.count == 0, "\(iterator.parsingErrors)")
    }
    
    func testSimpleLookahead() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        guard let rule = "\"x\"".dynamicRule(token: TT.character) else {
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
        guard let rule = "\"x\"".dynamicRule(token: TT.character) else {
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
        guard let rule = ".whitespaces+".dynamicRule(token: TT.whitespace) else {
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
        guard let rule = "\"0\"...\"9\"".dynamicRule(token: TT.decimalDigits) else {
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
        let ast = STLRParser(source: source).ast
        
        guard let identifier = ast.identifiers[identifierName] else {
            throw TestError.expected("Missing identifier \(identifierName)")
        }
        
        guard let rule = identifier.rule(from: ast, creating: Tokens.tokenA) else {
            return "Could not create rule"
        }
        
        let swift = "\(rule)".trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")
        
        return swift
    }
    
    func generatedStringSerialization(for source:String, desiredRule rule: Int = 0)throws ->String {
        let ast = STLRScope(building: source)
        
        if ast.rules.count <= rule {
            throw TestError.expected("at least \(rule + 1) rule, but got \(ast.rules.count)")
        }
        
        guard let rule = ast.rules[rule].rule(from: ast, creating: Tokens.tokenA) else {
            return "Could not create rule"
        }
        
        let swift = "\(rule)".trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")
        
        return swift
    }
    
    func testPredefinedCharacterSet() {
        do {
            let result = try generatedStringSerialization(for: "letter = @error(\"error\").whitespaces")
            
            XCTAssert(result == "tokenA = @error(\"error\") .characterSet", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testCustomCharacterSet() {
        do {
            let result = try generatedStringSerialization(for: "letter = @error(\"error\") \"a\"...\"z\"")
            
            XCTAssert(result == "tokenA = @error(\"error\") .characterSet", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testSimplestPossibleGrammar(){
        do {
            let result = try generatedStringSerialization(for: "a=\"a\"")
            
            XCTAssert(result == "tokenA =  \"a\"", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testTerminal(){
        do {
            let result = try generatedStringSerialization(for: "letter = @error(\"error\") \"hello\"")
            
            XCTAssert(result == "tokenA = @error(\"error\") \"hello\"", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testSingleCharacterTerminal(){
        do {
            let result = try generatedStringSerialization(for: "letter = @error(\"error\") \"h\"")
            
            XCTAssert(result == "tokenA = @error(\"error\") \"h\"", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testTerminalChoiceWithIndividualAnnotations(){
        do {
            let reference = "tokenA =  (@error(\"error a\") \"a\"|@error(\"error b\") \"b\"|@error(\"error c\") \"c\")"
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
            let reference = "tokenA =  (@error(\"error a\") \"a\"|@error(\"error b\") \"b\"|@error(\"error c\") \"c\")"
            let result = try generatedStringSerialization(for: "letter = @error(\"error a\") \"a\"| @error(\"error b\")\"b\"| @error(\"error c\") \"c\"").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")
            
            
            XCTAssertEqual(reference, result)
            
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testTerminalChoice(){
        do {
            let result = try generatedStringSerialization(for: "letter = @error(\"error\") (\"a\"|\"b\"|\"c\")")
            
            XCTAssertEqual("@error(\"error\")(\"a\" | \"b\" | \"c\")", result)
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testTerminalSequence(){
        do {
            let result = try generatedStringSerialization(for: "letter = @error(\"error\") (\"a\" \"b\" \"c\")")
            let reference = "tokenA = @error(\"error\") ( \"a\"  \"b\"  \"c\")"
            XCTAssertEqual(result, reference)
            
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testTerminalSequenceWithIndividualAnnotations(){
        do {
            let result = try generatedStringSerialization(for: "letter = @error(\"error a\") \"a\"  @error(\"error b\")\"b\"  @error(\"error c\") \"c\"").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")
            
            XCTAssert(result == "tokenA =  (@error(\"error a\") \"a\" @error(\"error b\") \"b\" @error(\"error c\") \"c\")", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testAnnotatedNestedIdentifiers(){
        do {
            let aRule = try generatedStringSerialization(for: "a = @error(\"a internal\")\"a\"\naa = @error(\"error a1\") a @error(\"error a2\") a", desiredRule: 0)
            let result = try generatedStringSerialization(for: "a = @error(\"a internal\")\"a\"\naa = @error(\"error a1\") a @error(\"error a2\") a", desiredRule: 1)
            
            XCTAssert(aRule == "tokenA = @error(\"a internal\") \"a\"", "Bad generated output '\(aRule)'")
            XCTAssert(result == "tokenA =  (a = @error(\"error a1\") \"a\" a = @error(\"error a2\") \"a\")", "Bad generated output '\(result)'")
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
            let result = try generatedStringSerialization(for: "word = @error(\"Expected a letter\") .letters+", desiredRule: 0)
            
            XCTAssert(result == "tokenA = @error(\"Expected a letter\")  .characterSet+", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testMergedAnnotationOnIdentifierReferenceWithQuantifiers(){
        do {
            let result = try generatedStringSerialization(for: "@error(\"expected a\")a = @error(\"inner a\") \"a\"\naa = a+ \" \" @error(\"error a2\") a+", desiredRule: 1)
            
            XCTAssert(result == "tokenA =  (@error(\"expected a\") a = @error(\"expected a\") \"a\"+  \" \" @error(\"error a2\") a = @error(\"expected a\") \"a\"+)", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
    func testRepeatedReference(){
        do {
            let result = try generatedStringSerialization(for: "@error(\"Expected a1\") a1 = \"a\" @error(\"Expected 1\") \"1\"\ndoubleA1 = a1 @error(\"Expected second a1\") a1", desiredRule: 1)
            
            XCTAssert(result == "tokenA =  (a1 = @error(\"Expected a1\") ( \"a\" @error(\"Expected 1\") \"1\") a1 = @error(\"Expected second a1\") ( \"a\" @error(\"Expected 1\") \"1\"))", "Bad generated output '\(result)'")
        } catch (let error){
            XCTFail("\(error)")
        }
    }
    
}
