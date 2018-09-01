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
    typealias T = XMLGenerated
    
    // Cache for compiled regular expressions
    private static var regularExpressionCache = [String : NSRegularExpression]()
    
    /// Returns a pre-compiled pattern from the cache, or if not in the cache builds
    /// the pattern, caches and returns the regular expression
    ///
    /// - Parameter pattern: The pattern the should be built
    /// - Returns: A compiled version of the pattern
    ///
    private static func regularExpression(_ pattern:String)->NSRegularExpression{
        if let cached = regularExpressionCache[pattern] {
            return cached
        }
        do {
            let new = try NSRegularExpression(pattern: pattern, options: [])
            regularExpressionCache[pattern] = new
            return new
        } catch {
            fatalError("Failed to compile pattern /\(pattern)/\n\(error)")
        }
    }
    /// The tokens defined by the grammar
    case `ws`, `identifier`, `singleQuote`, `doubleQuote`, `value`, `attribute`, `attributes`, `data`, `openTag`, `closeTag`, `inlineTag`, `nestingTag`, `tag`, `contents`, `xml`
    
    /// The rule for the token
    var rule : Rule {
        switch self {
        /// ws
        case .ws:
            return -[
                CharacterSet.whitespacesAndNewlines.require(.one)
                ].sequence
            
        /// identifier
        case .identifier:
            return [
                [
                    CharacterSet.letters.require(.one),
                    [
                        CharacterSet.letters.require(.one),
                        [
                            "-".require(.one),
                            CharacterSet.letters.require(.one)].sequence
                        ].choice
                    ].sequence
                
                ].sequence.parse(as: self)
            
        /// singleQuote
        case .singleQuote:
            return [
                "\'".require(.one)
                ].sequence.parse(as: self)
            
        /// doubleQuote
        case .doubleQuote:
            return [
                "\\\"".require(.one)
                ].sequence.parse(as: self)
            
        /// value
        case .value:
            return [
                [
                    [
                        -T.singleQuote.rule.require(.one),
                        !T.singleQuote.rule.require(.zeroOrMore),
                        -T.singleQuote.rule.require(.one)].sequence
                    ,
                    [
                        -T.doubleQuote.rule.require(.one),
                        !T.doubleQuote.rule.require(.zeroOrMore),
                        -T.doubleQuote.rule.require(.one)].sequence
                    ].choice
                
                ].sequence.parse(as: self)
            
        /// attribute
        case .attribute:
            return [
                [
                    T.ws.rule.require(.oneOrMore),
                    T.identifier.rule.require(.one),
                    [
                        T.ws.rule.require(.zeroOrMore),
                        -"=".require(.one),
                        T.ws.rule.require(.zeroOrMore),
                        T.value.rule.require(.one)].sequence
                    ].sequence
                
                ].sequence.parse(as: self)
            
        /// attributes
        case .attributes:
            return [
                T.attribute.rule.require(.oneOrMore)
                ].sequence.parse(as: self)
            
        /// data
        case .data:
            return [
                !"<".require(.oneOrMore)
                ].sequence.parse(as: self)
            
        /// openTag
        case .openTag:
            return [
                [
                    T.ws.rule.require(.zeroOrMore),
                    -"<".require(.one),
                    T.identifier.rule.require(.one),
                    [
                        T.attributes.rule.require(.one),
                        T.ws.rule.require(.zeroOrMore)].choice
                    ,
                    -">".require(.one)].sequence
                
                ].sequence.parse(as: self)
            
        /// closeTag
        case .closeTag:
            return -[
                [
                    T.ws.rule.require(.zeroOrMore),
                    -"</".require(.one),
                    T.identifier.rule.require(.one),
                    T.ws.rule.require(.zeroOrMore),
                    -">".require(.one)].sequence
                
                ].sequence
            
        /// inlineTag
        case .inlineTag:
            return [
                [
                    T.ws.rule.require(.zeroOrMore),
                    -"<".require(.one),
                    T.identifier.rule.require(.one),
                    [
                        T.attribute.rule.require(.oneOrMore),
                        T.ws.rule.require(.zeroOrMore)].choice
                    ,
                    -"/>".require(.one)].sequence
                
                ].sequence.parse(as: self)
            
        /// nestingTag
        case .nestingTag:
            return [
                [
                    ~T.openTag.rule.require(.one),
                    T.contents.rule.require(.one),
                    T.closeTag.rule.require(.one)].sequence
                
                ].sequence.parse(as: self)
            
        /// tag
        case .tag:
            return [
                [
                    ~T.nestingTag.rule.require(.one),
                    ~T.inlineTag.rule.require(.one)].choice
                
                ].sequence.parse(as: self)
            
        /// contents
        case .contents:
            return [
                [
                    T.data.rule.require(.one),
                    T.tag.rule.require(.one)].choice
                
                ].sequence.parse(as: self)
            
        /// xml
        case .xml:
            return [
                T.tag.rule.require(.one)
                ].sequence.parse(as: self)
            
        }
    }
    
    /// Create a language that can be used for parsing etc
    public static var grammar: [Rule] {
        return [T.xml.rule]
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

    func testCache() {
        let astConstructor = AbstractSyntaxTreeConstructor()
        
        astConstructor.initializeCache(depth: 3, breadth: 3)
    }
}
