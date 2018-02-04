//
//  HierarchyTests.swift
//  STLRTests
//
//  Created by Nigel Hughes on 31/01/2018.
//

import XCTest
import OysterKit
import STLR

class HierarchyTests: XCTestCase {

    func testExample() {
        // This needs to be integrated fully
        return
        guard let grammarSource = try? String(contentsOfFile: "/Volumes/Personal/SPM/XMLDecoder/XML.stlr") else {
            fatalError("Could not load grammar")
        }
        
        guard let xmlLanguage = STLRParser.init(source: grammarSource).ast.runtimeLanguage else {
            fatalError("Could not create language")
        }
        
        let xmlSource = """
<message subject='Hello, OysterKit!' priority="High">
    It's really <i>good</i> to meet you,
    <p />
    I hope you are settling in OK, let me know if you need anything.
    <p />
    Phatom Testers
</message>
"""
        for rule in xmlLanguage.grammar {
            print("Rule:\n\t\(rule)")
        }

        do {
            let tree = try AbstractSyntaxTreeConstructor().build(xmlSource, using: XML.generatedLanguage)
            print(tree.description)
        } catch {
            print(error)
            XCTFail("Could not parse source"); return
        }
        
//        print(STLRParser.init(source: grammarSource).ast.swift(grammar: "XML")!)
    }
    
    let xmlStlr = """
//
// XML Grammar
//

// Scanner Rules
@void ws        = .whitespacesAndNewlines
identifier      = .letters (.letters | ("-" .letters))*
singleQuote     = "'"
doubleQuote     = "\""

value           =       (-singleQuote !singleQuote* @error("Expected closing '")  -singleQuote) |
                        (-doubleQuote !doubleQuote* @error("Expected closing \"") -doubleQuote)

attribute       = ws+ identifier (ws* -"=" ws* value)?
attributes      = attribute+

data            = !"<"+

openTag         = ws* -"<"  identifier (attributes | ws*) -">"
@void
closeTag        = ws* -"</" identifier ws* -">"
inlineTag       = ws* -"<"  identifier (attribute+ | ws*) -"/>"
nestingTag      = @transient openTag contents @error("Expected closing tag") closeTag

// Grammar Rules
tag             = @transient nestingTag | @transient inlineTag
contents        = @token("content") (data | tag)*

// AST Root
xml             = tag
"""

}

//
// STLR Generated Swift File
//
// Generated: 2018-01-31 23:30:11 +0000
//
import Cocoa
import OysterKit

//
// XML Parser
//
enum XML : Int, Token {
    
    // Convenience alias
    private typealias T = XML
    
    case _transient = -1, `ws`, `identifier`, `singleQuote`, `doubleQuote`, `value`, `attribute`, `attributes`, `data`, `openTag`, `closeTag`, `inlineTag`, `nestingTag`, `tag`, `content`, `contents`, `xml`
    
    func _rule(_ annotations: RuleAnnotations = [ : ])->Rule {
        switch self {
        case ._transient:
            return CharacterSet(charactersIn: "").terminal(token: T._transient)
        // ws
        case .ws:
            return CharacterSet.whitespacesAndNewlines.terminal(token: T.ws, annotations: annotations.isEmpty ? [RuleAnnotation.void : RuleAnnotationValue.set] : annotations)
        // identifier
        case .identifier:
            return [
                CharacterSet.letters.terminal(token: T._transient),
                [
                    CharacterSet.letters.terminal(token: T._transient),
                    [
                        "-".terminal(token: T._transient),
                        CharacterSet.letters.terminal(token: T._transient),
                        ].sequence(token: T._transient),
                    ].oneOf(token: T._transient).repeated(min: 0, producing: T._transient),
                ].sequence(token: T.identifier, annotations: annotations.isEmpty ? [ : ] : annotations)
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
                T.identifier._rule(),
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
                T.identifier._rule(),
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
                T.identifier._rule(),
                T.ws._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                ">".terminal(token: T._transient, annotations: [RuleAnnotation.transient : RuleAnnotationValue.set]),
                ].sequence(token: T.closeTag, annotations: annotations.isEmpty ? [RuleAnnotation.void : RuleAnnotationValue.set] : annotations)
        // inlineTag
        case .inlineTag:
            return [
                T.ws._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                "<".terminal(token: T._transient, annotations: [RuleAnnotation.transient : RuleAnnotationValue.set]),
                T.identifier._rule(),
                [
                    T.attribute._rule().repeated(min: 1, producing: T._transient),
                    T.ws._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                    ].oneOf(token: T._transient),
                "/>".terminal(token: T._transient, annotations: [RuleAnnotation.transient : RuleAnnotationValue.set]),
                ].sequence(token: T.inlineTag, annotations: annotations.isEmpty ? [ : ] : annotations)
        // nestingTag
        case .nestingTag:
            guard let cachedRule = XML.leftHandRecursiveRules[self.rawValue] else {
                // Create recursive shell
                let recursiveRule = RecursiveRule(stubFor: self, with: annotations.isEmpty ? [ : ] : annotations)
                XML.leftHandRecursiveRules[self.rawValue] = recursiveRule
                // Create the rule we would normally generate
                let rule = [
                    T.openTag._rule([RuleAnnotation.transient : RuleAnnotationValue.set]),
                    T.contents._rule(),
                    T.closeTag._rule([RuleAnnotation.void : RuleAnnotationValue.set,RuleAnnotation.error : RuleAnnotationValue.string("Expected closing tag")]),
                    ].sequence(token: T._transient, annotations: [:])
                recursiveRule.surrogateRule = rule
                return recursiveRule
            }
            return cachedRule
        // tag
        case .tag:
            guard let cachedRule = XML.leftHandRecursiveRules[self.rawValue] else {
                // Create recursive shell
                let recursiveRule = RecursiveRule(stubFor: self, with: annotations)
                XML.leftHandRecursiveRules[self.rawValue] = recursiveRule
                // Create the rule we would normally generate
                let rule = [
                    T.nestingTag._rule([RuleAnnotation.transient : RuleAnnotationValue.set]),
                    T.inlineTag._rule([RuleAnnotation.transient : RuleAnnotationValue.set]),
                    ].oneOf(token: T._transient, annotations: [:])
                recursiveRule.surrogateRule = rule
                return recursiveRule
            }
            return cachedRule
        // content
        case .content:
            guard let cachedRule = XML.leftHandRecursiveRules[self.rawValue] else {
                // Create recursive shell
                let recursiveRule = RecursiveRule(stubFor: self, with: annotations)
                XML.leftHandRecursiveRules[self.rawValue] = recursiveRule
                // Create the rule we would normally generate
                let rule = [
                    T.data._rule(),
                    T.tag._rule(),
                    ].oneOf(token: T._transient, annotations: annotations).repeated(min: 0, producing: T._transient, annotations: [:])
                recursiveRule.surrogateRule = rule
                return recursiveRule
            }
            return cachedRule
        // contents
        case .contents:
            guard let cachedRule = XML.leftHandRecursiveRules[self.rawValue] else {
                // Create recursive shell
                let recursiveRule = RecursiveRule(stubFor: self, with: [:])
                XML.leftHandRecursiveRules[self.rawValue] = recursiveRule
                // Create the rule we would normally generate
                let rule = [T.content._rule()].sequence(token: self)
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
        return XML.generatedLanguage.build(source: source)
    }
}

