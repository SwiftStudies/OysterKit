//
//  BlockRuleTest.swift
//  OysterKitTests
//
//  Created on 16/07/2018.
//

import XCTest
@testable import OysterKit


fileprivate func isLetter(lexer:LexicalAnalyzer, ir:IntermediateRepresentation) throws {
    try lexer.scan(oneOf: CharacterSet.letters)
}

fileprivate let aToken = StringToken("a")

class BlockRuleTest: XCTestCase {
    typealias LowLevelResult = (lexer:Lexer,ir:AbstractSyntaxTreeConstructor, root:TokenType?)

    let singleLetterRule = ClosureRule(with: Behaviour(.scanning), using: isLetter)

    func checkTree(from source:String, with rules: [Rule]) throws ->HomogenousTree {
        return try AbstractSyntaxTreeConstructor().build("a", using: Parser(grammar: rules))
    }
    
    func validate(lowLevelResult:LowLevelResult, index: String.Index? = nil, errors:[String]? = nil, token:TokenType? = nil)->[String] {
        var failures = [String]()

        if let token = token {
            if let rootToken = lowLevelResult.root{
                if "\(token)" != "\(rootToken)" {
                    failures.append("Expected \(token) but got \(rootToken)")
                }
            } else {
                failures.append("Expected \(token) but got nothing")
            }
        } else {
            if let rootToken = lowLevelResult.root {
                failures.append("Expected no structure but got \(rootToken)")
            }
        }
        
        if let index = index, lowLevelResult.lexer.index != index {
            failures.append("Expected scanner index to be \(index.encodedOffset) but it was \(lowLevelResult.lexer.index.encodedOffset)")
        }
        
        if let errors = errors {
            let actualErrors : [String] = lowLevelResult.ir.errors.compactMap({
                let stringVersion = "\($0)"
                //Remove complaints about no nodes because we check for a token explicitly
                if stringVersion.range(of: "No nodes") != nil {
                    return nil
                }
                return stringVersion

            })
            if errors != actualErrors {
                failures.append("Expected \(errors) but got \(actualErrors)")
            }
        }
    
        return failures
    }
    
    func check(rule:Rule, on source:String, includeAST:Bool = false) -> LowLevelResult{
        let ir = AbstractSyntaxTreeConstructor(with: source)
        let lexer = Lexer(source: source)
        
        do {
            try rule.match(with: lexer, for: ir)
            if includeAST {
                do {
                    let tree = try ir.generate(HomogenousTree.self)
                    return (lexer,ir, tree.token)
                } catch {
                    return (lexer,ir, nil)
                }
            } else {
                return (lexer, ir, nil)
            }
        } catch {
            ir._errors.append(error)
            return (lexer,ir,nil)
        }
        
    }
    
    func testTestLexerIsolation(){
        let source = "a"
        
        let rule = ClosureRule(with: Behaviour(.scanning)) { (lexer, ir) in
            try lexer.scanNext()
            //Force scanning past the end
            try lexer.scanNext()
        }
        
        for failure in validate(lowLevelResult: check(rule:rule, on:source, includeAST: false), index: source.startIndex, errors: ["Match failed"], token: nil){
            XCTFail(failure)
        }
    }
    
    func testStructure(){
        let source = "a"
        
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(.structural(token: aToken)), on:source, includeAST: true), index: source.endIndex, errors: [], token: aToken){
            XCTFail(failure)
        }
    }
    
    func testStructureFail(){
        let source = "1"
        
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(.structural(token: aToken)), on:source, includeAST: true), index: source.startIndex, errors: ["Match failed"], token: nil){
            XCTFail(failure)
        }
    }
    
    func testNegatedStructure(){
        let source = "1"
        
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(.structural(token: aToken), negated:true), on:source, includeAST: true), index: source.endIndex, errors: [], token: aToken){
            XCTFail(failure)
        }
    }
    
    
    func testNegatedStructureFail(){
        let source = "a"
        
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(.structural(token: aToken), negated:true), on:source, includeAST: true), index: source.startIndex, errors: ["Undefined Error: Undefined error at 0"], token: nil){
            XCTFail(failure)
        }
    }
    
    func testOptionalStructure(){
        let source = "a"
        
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(.structural(token: aToken), cardinality: 0...1), on:source, includeAST: true), index: source.endIndex, errors: [], token: aToken){
            XCTFail(failure)
        }
    }
    
    
    func testOptionalStructureFail(){
        let source = "1"
        
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(.structural(token: aToken), cardinality: 0...1), on:source, includeAST: true), index: source.startIndex, errors: [], token: nil){
            XCTFail(failure)
        }
    }
    
    func testStructureError(){
        let source = "1"
        let specificError = "TestPassed"
        
        let structuralRule = singleLetterRule.newBehaviour(.structural(token: aToken)).annotatedWith([.error: .string(specificError)])
        
        for failure in validate(lowLevelResult: check(rule:structuralRule, on:source, includeAST: true), index: source.startIndex, errors: ["Parsing Error: \(specificError) at 0"], token: nil){
            XCTFail(failure)
        }
    }

    func testScanError(){
        let source = "1"
        let specificError = "TestPassed"
        
        
        
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.instanceWith(annotations: [.error : .string(specificError)]), on:source), index: source.startIndex, errors: ["Parsing Error: \(specificError) at 0"]){
            XCTFail(failure)
        }
    }

    
    func testScan(){
        let source = "a"
        for failure in validate(lowLevelResult: check(rule:singleLetterRule, on:source), index: source.endIndex, errors: []){
            XCTFail(failure)
        }
    }
    
    func testNotScanFailure(){
        let source = "a"
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(negated:true), on:source), index: source.startIndex, errors: ["Undefined Error: Undefined error at 0"]){
            XCTFail(failure)
        }
    }
    
    func testScanFailure(){
        let source = "1"
        for failure in validate(lowLevelResult: check(rule:singleLetterRule, on:source), index: source.startIndex, errors: ["Match failed"]){
            XCTFail(failure)
        }
    }
    
    func testNotScan(){
        let source = "1"
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(negated:true), on:source), index: source.endIndex, errors: []){
            XCTFail(failure)
        }
    }

    func testLookahead(){
        //Look-ahead, positive, failure
        let source = "a"
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(lookahead:true), on:source), index: source.startIndex, errors: []){
            XCTFail(failure)
        }
    }
    
    func testLookaheadFailure(){
        //Look-ahead, positive, failure
        let source = "1"
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(lookahead:true), on:source), index: source.startIndex, errors: ["Match failed"]){
            XCTFail(failure)
        }
    }

    func testNotLookahead(){
        //Look-ahead, positive, failure
        let source = "1"
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(negated:true,lookahead:true), on:source), index: source.startIndex, errors: []){
            XCTFail(failure)
        }
    }
    
    func testNotLookaheadFailure(){
        //Look-ahead, positive, failure
        let source = "a"
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(negated:true,lookahead:true), on:source), index: source.startIndex, errors: ["Undefined Error: Undefined error at 0"]){
            XCTFail(failure)
        }
    }

    func testOptional(){
        //Look-ahead, positive, failure
        let source = "a"
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(cardinality: 0...1), on:source), index: source.endIndex, errors: []){
            XCTFail(failure)
        }
    }

    func testOptionalFailure(){
        //Look-ahead, positive, failure
        let source = "1"
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(cardinality: 0...1), on:source), index: source.startIndex, errors: []){
            XCTFail(failure)
        }
    }

    func testLookaheadOptionalFailure(){
        //Look-ahead, positive, failure
        let source = "1"
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(cardinality: 0...1, lookahead:true), on:source), index: source.startIndex, errors: []){
            XCTFail(failure)
        }
    }
    
    func testLookaheadOptional(){
        //Look-ahead, positive, failure
        let source = "a"
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(cardinality: 0...1, lookahead:true), on:source), index: source.startIndex, errors: []){
            XCTFail(failure)
        }
    }

}
