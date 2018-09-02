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
import OysterKit
import STLR

class HierarchyTests: XCTestCase {

    #warning("Test disabled pending implementation")
//    func testExample() {
//        return
//        
//        guard let grammarSource = try? String(contentsOfFile: "/Volumes/Personal/SPM/XMLDecoder/XML.stlr") else {
//            fatalError("Could not load grammar")
//        }
//        
//        let xmlLanguage : Grammar
//        
//        do {
//            xmlLanguage = try ProductionSTLR.build(grammarSource).grammar.dynamicRules
//
//        } catch {
//            fatalError("Could not create language")
//        }
//        
//        let xmlSource = """
//<message subject='Hello, OysterKit!' priority="High">
//    It's really <i>good</i> to meet you,
//    <p />
//    I hope you are settling in OK, let me know if you need anything.
//    <p />
//    Phatom Testers
//</message>
//"""
//        for _ in xmlLanguage.grammar {
////            print("Rule:\n\t\(rule)")
//        }
//
//        do {
//            _ = try AbstractSyntaxTreeConstructor().build(xmlSource, using: XML.grammar.language)
////            print(tree.description)
//        } catch {
////            print(error)
//            XCTFail("Could not parse source"); return
//        }
//        
////        print(STLRParser.init(source: grammarSource).ast.swift(grammar: "XML")!)
//    }
    
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
import OysterKit

//
// XML Parser
//
enum XML : Int, TokenType {
    typealias T = XML
    
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
