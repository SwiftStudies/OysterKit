//
//  BlockRuleTest.swift
//  OysterKitTests
//
//  Created by Nigel Hughes on 16/07/2018.
//

import XCTest
@testable import OysterKit


fileprivate func isLetter(lexer:LexicalAnalyzer, ir:IntermediateRepresentation) throws {
    try lexer.scan(oneOf: CharacterSet.letters)
}

fileprivate let aToken = LabelledToken(withLabel: "a")

class BlockRuleTest: XCTestCase {
    typealias LowLevelResult = (lexer:Lexer,ir:AbstractSyntaxTreeConstructor, matchResult:MatchResult, root:Token?)
    enum TestMatchingResult {
        case success, failure, consume, ignoreFailure
    }

    let singleLetterRule = ClosureRule(with: Behaviour(.scanning), using: isLetter)

    func checkTree(from source:String, with rules: [Rule]) throws ->HomogenousTree {
        return try AbstractSyntaxTreeConstructor().build("a", using: Parser(grammar: rules))
    }
    
    func validate(lowLevelResult:LowLevelResult, index: String.Index? = nil, errors:[String]? = nil, expectedResult:TestMatchingResult?, token:Token? = nil)->[String] {
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
        
        remainder:
        if let expectedResult = expectedResult {
            switch expectedResult {
            case .success:
                if case .success = lowLevelResult.matchResult {} else {
                    failures.append("Expected success but got \(lowLevelResult.matchResult)")
                }
            case .failure:
                if case .failure = lowLevelResult.matchResult {} else {
                    failures.append("Expected failure but got \(lowLevelResult.matchResult)")
                }
            case .consume:
                if case .consume = lowLevelResult.matchResult {} else {
                    failures.append("Expected consume but got \(lowLevelResult.matchResult)")
                }
            case .ignoreFailure:
                if case .ignoreFailure = lowLevelResult.matchResult {} else {
                    failures.append("Expected ignoreFailure but got \(lowLevelResult.matchResult)")
                }
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
            let result = try rule.match(with: lexer, for: ir)
            if includeAST {
                do {
                    let tree = try ir.generate(HomogenousTree.self)
                    return (lexer,ir,result, tree.token)
                } catch {
                    return (lexer,ir, result, nil)
                }
            } else {
                return (lexer, ir, result, nil)
            }
        } catch {
            ir._errors.append(error)
            return (lexer,ir,MatchResult.failure(atIndex: lexer.index),nil)
        }
        
    }
    
    func testStructure(){
        let source = "a"
        
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(.structural(token: aToken)), on:source, includeAST: true), index: source.endIndex, errors: [], expectedResult: .success, token: aToken){
            XCTFail(failure)
        }
    }
    
    func testStructureFail(){
        let source = "1"
        
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(.structural(token: aToken)), on:source, includeAST: true), index: source.startIndex, errors: ["Match failed"], expectedResult: .failure, token: nil){
            XCTFail(failure)
        }
    }
    
    func testNegatedStructure(){
        let source = "1"
        
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(.structural(token: aToken), negated:true), on:source, includeAST: true), index: source.endIndex, errors: [], expectedResult: .success, token: aToken){
            XCTFail(failure)
        }
    }
    
    
    func testNegatedStructureFail(){
        let source = "a"
        
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(.structural(token: aToken), negated:true), on:source, includeAST: true), index: source.startIndex, errors: ["Failed to match from 0 to 1"], expectedResult: .failure, token: nil){
            XCTFail(failure)
        }
    }
    
    func testOptionalStructure(){
        let source = "a"
        
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(.structural(token: aToken), cardinality: 0...1), on:source, includeAST: true), index: source.endIndex, errors: [], expectedResult: .success, token: aToken){
            XCTFail(failure)
        }
    }
    
    
    func testOptionalStructureFail(){
        let source = "1"
        
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(.structural(token: aToken), cardinality: 0...1), on:source, includeAST: true), index: source.startIndex, errors: [], expectedResult: .ignoreFailure, token: nil){
            XCTFail(failure)
        }
    }
    
    func testStructureError(){
        let source = "1"
        let specificError = "TestPassed"
        
        let structuralRule = singleLetterRule.newBehaviour(.structural(token: aToken)).instance(with: nil, andAnnotations: [.error: .string(specificError)])
        
        for failure in validate(lowLevelResult: check(rule:structuralRule, on:source, includeAST: true), index: source.startIndex, errors: ["\(specificError) from 0 to 0"], expectedResult: .failure, token: nil){
            XCTFail(failure)
        }
    }

    func testScanError(){
        let source = "1"
        let specificError = "TestPassed"
        
        
        
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.instanceWith(annotations: [.error : .string(specificError)]), on:source), index: source.startIndex, errors: ["\(specificError) from 0 to 0"], expectedResult: .failure){
            XCTFail(failure)
        }
    }

    
    func testScan(){
        let source = "a"
        for failure in validate(lowLevelResult: check(rule:singleLetterRule, on:source), index: source.endIndex, errors: [], expectedResult: .success){
            XCTFail(failure)
        }
    }
    
    func testNotScanFailure(){
        let source = "a"
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(negated:true), on:source), index: source.startIndex, errors: ["Failed to match from 0 to 1"], expectedResult: .failure){
            XCTFail(failure)
        }
    }
    
    func testScanFailure(){
        let source = "1"
        for failure in validate(lowLevelResult: check(rule:singleLetterRule, on:source), index: source.startIndex, errors: ["Match failed"], expectedResult: .failure){
            XCTFail(failure)
        }
    }
    
    func testNotScan(){
        let source = "1"
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(negated:true), on:source), index: source.endIndex, errors: [], expectedResult: .success){
            XCTFail(failure)
        }
    }

    func testLookahead(){
        //Look-ahead, positive, failure
        let source = "a"
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(lookahead:true), on:source), index: source.startIndex, errors: [], expectedResult: .success){
            XCTFail(failure)
        }
    }
    
    func testLookaheadFailure(){
        //Look-ahead, positive, failure
        let source = "1"
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(lookahead:true), on:source), index: source.startIndex, errors: ["Match failed"], expectedResult: .failure){
            XCTFail(failure)
        }
    }

    func testNotLookahead(){
        //Look-ahead, positive, failure
        let source = "1"
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(negated:true,lookahead:true), on:source), index: source.startIndex, errors: [], expectedResult: .success){
            XCTFail(failure)
        }
    }
    
    func testNotLookaheadFailure(){
        //Look-ahead, positive, failure
        let source = "a"
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(negated:true,lookahead:true), on:source), index: source.startIndex, errors: ["Failed to match from 0 to 1"], expectedResult: .failure){
            XCTFail(failure)
        }
    }

    func testOptional(){
        //Look-ahead, positive, failure
        let source = "a"
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(cardinality: 0...1), on:source), index: source.endIndex, errors: [], expectedResult: .success){
            XCTFail(failure)
        }
    }

    func testOptionalFailure(){
        //Look-ahead, positive, failure
        let source = "1"
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(cardinality: 0...1), on:source), index: source.startIndex, errors: [], expectedResult: .ignoreFailure){
            XCTFail(failure)
        }
    }

    func testLookaheadOptionalFailure(){
        //Look-ahead, positive, failure
        let source = "1"
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(cardinality: 0...1, lookahead:true), on:source), index: source.startIndex, errors: [], expectedResult: .ignoreFailure){
            XCTFail(failure)
        }
    }
    
    func testLookaheadOptional(){
        //Look-ahead, positive, failure
        let source = "a"
        for failure in validate(lowLevelResult: check(rule:singleLetterRule.newBehaviour(cardinality: 0...1, lookahead:true), on:source), index: source.startIndex, errors: [], expectedResult: .success){
            XCTFail(failure)
        }
    }

}
