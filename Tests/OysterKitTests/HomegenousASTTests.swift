//
//  HomegenousASTTests.swift
//  PerformanceTests
//
//  Created by Nigel Hughes on 30/01/2018.
//

import XCTest
import OysterKit

//
// XML Parser
//
enum XMLGenerated : Int, Token {
    
    // Convenience alias
    private typealias T = XMLGenerated
    
    case _transient = -1, `ws`, `identifer`, `singleQuote`, `doubleQuote`, `value`, `attribute`, `attributes`, `data`, `openTag`, `closeTag`, `inlineTag`, `nestingTag`, `tag`, `contents`, `xml`
    
    func _rule(_ annotations: RuleAnnotations = [ : ])->Rule {
        switch self {
        case ._transient:
            return CharacterSet(charactersIn: "").terminal(token: T._transient)
        // ws
        case .ws:
            return CharacterSet.whitespacesAndNewlines.terminal(token: T.ws, annotations: annotations.isEmpty ? [RuleAnnotation.void : RuleAnnotationValue.set] : annotations)
        // identifer
        case .identifer:
            return [
                CharacterSet.letters.terminal(token: T._transient),
                [
                    CharacterSet.letters.terminal(token: T._transient),
                    [
                        "-".terminal(token: T._transient),
                        CharacterSet.letters.terminal(token: T._transient),
                        ].sequence(token: T._transient),
                    ].oneOf(token: T._transient).repeated(min: 0, producing: T._transient),
                ].sequence(token: T.identifer, annotations: annotations.isEmpty ? [ : ] : annotations)
        // singleQuote
        case .singleQuote:
            return "'".terminal(token: T.singleQuote, annotations: annotations)
        // doubleQuote
        case .doubleQuote:
            return "\"".terminal(token: T.doubleQuote, annotations: annotations)
        // value
        case .value:
            return [
                [
                    T.singleQuote._rule([RuleAnnotation.transient : RuleAnnotationValue.set]),
                    T.singleQuote._rule().not(producing: T._transient).repeated(min: 0, producing: T._transient),
                    T.singleQuote._rule([RuleAnnotation.error : RuleAnnotationValue.string("Expected closing '"),RuleAnnotation.transient : RuleAnnotationValue.set]),
                    ].sequence(token: T._transient),
                [
                    T.doubleQuote._rule([RuleAnnotation.transient : RuleAnnotationValue.set]),
                    T.doubleQuote._rule().not(producing: T._transient).repeated(min: 0, producing: T._transient),
                    T.doubleQuote._rule([RuleAnnotation.error : RuleAnnotationValue.string("Expected closing \""),RuleAnnotation.transient : RuleAnnotationValue.set]),
                    ].sequence(token: T._transient),
                ].oneOf(token: T.value, annotations: annotations)
        // attribute
        case .attribute:
            return [
                T.ws._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 1, producing: T._transient),
                T.identifer._rule(),
                [
                    T.ws._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                    "=".terminal(token: T._transient, annotations: [RuleAnnotation.transient : RuleAnnotationValue.set]),
                    T.ws._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                    T.value._rule(),
                    ].sequence(token: T._transient).optional(producing: T._transient),
                ].sequence(token: T.attribute, annotations: annotations.isEmpty ? [ : ] : annotations)
        // attributes
        case .attributes:
            return T.attribute._rule().repeated(min: 1, producing: T.attributes, annotations: annotations)
        // data
        case .data:
            return "<".terminal(token: T._transient, annotations: annotations).not(producing: T._transient, annotations: annotations).repeated(min: 1, producing: T.data, annotations: annotations)
        // openTag
        case .openTag:
            return [
                T.ws._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                "<".terminal(token: T._transient, annotations: [RuleAnnotation.transient : RuleAnnotationValue.set]),
                T.identifer._rule(),
                [
                    T.attributes._rule(),
                    T.ws._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                    ].oneOf(token: T._transient),
                ">".terminal(token: T._transient, annotations: [RuleAnnotation.transient : RuleAnnotationValue.set]),
                ].sequence(token: T.openTag, annotations: annotations.isEmpty ? [ : ] : annotations)
        // closeTag
        case .closeTag:
            return [
                T.ws._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                "</".terminal(token: T._transient, annotations: [RuleAnnotation.transient : RuleAnnotationValue.set]),
                T.identifer._rule(),
                T.ws._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                ">".terminal(token: T._transient, annotations: [RuleAnnotation.transient : RuleAnnotationValue.set]),
                ].sequence(token: T.closeTag, annotations: annotations.isEmpty ? [ : ] : annotations)
        // inlineTag
        case .inlineTag:
            return [
                T.ws._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                "<".terminal(token: T._transient, annotations: [RuleAnnotation.transient : RuleAnnotationValue.set]),
                T.identifer._rule(),
                [
                    T.attribute._rule().repeated(min: 1, producing: T._transient),
                    T.ws._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                    ].oneOf(token: T._transient),
                "/>".terminal(token: T._transient, annotations: [RuleAnnotation.transient : RuleAnnotationValue.set]),
                ].sequence(token: T.inlineTag, annotations: annotations.isEmpty ? [ RuleAnnotation.transient : RuleAnnotationValue.set ] : annotations)
        // nestingTag
        case .nestingTag:
            guard let cachedRule = XMLGenerated.leftHandRecursiveRules[self.rawValue] else {
                // Create recursive shell
                let recursiveRule = RecursiveRule()
                XMLGenerated.leftHandRecursiveRules[self.rawValue] = recursiveRule
                // Create the rule we would normally generate
                let rule = [
                    T.openTag._rule(),
                    T.contents._rule().repeated(min: 0, producing: T._transient),
                    T.closeTag._rule([RuleAnnotation.error : RuleAnnotationValue.string("Expected closing tag")]),
                    ].sequence(token: T.nestingTag, annotations: annotations.isEmpty ? [ : ] : annotations)
                recursiveRule.surrogateRule = rule
                return recursiveRule
            }
            return cachedRule
        // tag
        case .tag:
            guard let cachedRule = XMLGenerated.leftHandRecursiveRules[self.rawValue] else {
                // Create recursive shell
                let recursiveRule = RecursiveRule()
                XMLGenerated.leftHandRecursiveRules[self.rawValue] = recursiveRule
                // Create the rule we would normally generate
                let rule = [
                    T.nestingTag._rule(),
                    T.inlineTag._rule(),
                    ].oneOf(token: T.tag, annotations: annotations)
                recursiveRule.surrogateRule = rule
                return recursiveRule
            }
            return cachedRule
        // contents
        case .contents:
            guard let cachedRule = XMLGenerated.leftHandRecursiveRules[self.rawValue] else {
                // Create recursive shell
                let recursiveRule = RecursiveRule()
                XMLGenerated.leftHandRecursiveRules[self.rawValue] = recursiveRule
                // Create the rule we would normally generate
                let rule = [
                    T.data._rule(),
                    T.tag._rule(),
                    ].oneOf(token: T.contents, annotations: annotations)
                recursiveRule.surrogateRule = rule
                return recursiveRule
            }
            return cachedRule
        // xml
        case .xml:
            return [T.tag._rule()].sequence(token: self)
        }
    }
    
    
    // Cache for left-hand recursive rules
    private static var leftHandRecursiveRules = [ Int : Rule ]()
    
    // Create a language that can be used for parsing etc
    public static var generatedLanguage : Parser {
        return Parser(grammar: [T.xml._rule()])
    }
    
    // Convient way to apply your grammar to a string
    public static func parse(source: String) -> DefaultHeterogeneousAST {
        return XMLGenerated.generatedLanguage.build(source: source)
    }
}

class HomegenousASTTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let tree = try? AbstractSyntaxTreeConstructor().build("<a/>",using: XMLGenerated.generatedLanguage)
        print(tree!.description)
    }
}
