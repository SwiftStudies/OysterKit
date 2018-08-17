//    Copyright (c) 2016, RED When Excited
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

import Foundation

/// Generates Swift Source for the rules in a grammar
extension _STLR {
    /**
     Generates Swift code that uses OysterKit to implement the parsed grammar
     
     - Parameter grammar: The name of the class that will be generated
     - Parameter platform: The target platform for the class (note this will be depricated in a subsequent release so it is no longer required)
     - Parameter colors: A dictionary of colors that can be used by syntax coloring engines
     - Returns: A `String` containing the Swift source or `nil` if an error occured.
     */
    func swift(in file:TextFile){
        let grammarName = "FixMe"
        
        file.print("typealias T = \(grammarName)Tokens")
        file.print("fileprivate enum \(grammarName)Tokens : Int, Token, Language {").indent()
        
        // Include regular expression caching
        file.printBlock(regularExpressionBlock)
        
        // The tokens
        file.print("","/// The tokens defined by the grammar","case "+grammar.rules.compactMap({$0.identifier}).map({"`\($0)`"}).joined(separator: ", "))
        
        //
        // Rules
        //
        file.print("","var rule : BehaviouralRule {").indent()
        file.print(         "switch self {").indent()
        for rule in grammar.rules {
            file.print("/// \(rule.identifier)","case .\(rule.identifier):").indent()

            if grammar.isDirectLeftHandRecursive(identifier: rule.identifier) {
                file.print(       "guard let cachedRule = T.leftHandRecursiveRules[self.rawValue] else {").indent()
                file.print(           "// Create recursive shell")
                file.print(           "let recursiveRule = RecursiveRule(stubFor: self, with: annotations.isEmpty ? [ : ] : annotations)")
                file.print(           "T.leftHandRecursiveRules[self.rawValue] = recursiveRule")
                file.print(           "// Create the rule we would normally generate")
                file.printBlock(      "let rule = \(rule.swift(in: TextFile()).content)")
                file.print(           "recursiveRule.surrogateRule = rule")
                file.print(           "return recursiveRule").outdent()
                file.print(       "}")
                file.print(       "return cachedRule")
            } else {
                file.printBlock("return \(rule.swift(in: TextFile()).content)")
            }
            file.outdent().print("")
            
        }
        file.outdent().print("}").outdent().print("}")
        
        //
        // Cache for Recursion
        //
        if grammar.rules.filter({self.grammar.isDirectLeftHandRecursive(identifier: $0.identifier)}).count > 0 {
            file.print("","/// Cache for left-hand recursive rules","private static var leftHandRecursiveRules = [ Int : BehaviouralRule ]()")
        }
        
        let rootRules = grammar.rules.filter({grammar.isRoot(identifier: $0.identifier)})
        file.print("","/// Create a language that can be used for parsing etc")
        file.print("public static var generatedLanguage : Parser {").indent()
        file.print("return Parser(grammar: ["+rootRules.compactMap({$0.identifier}).map({"T.\($0).rule"}).joined(separator: ", ")+"])")
        file.outdent().print("}")
                
        file.outdent().print("}")
    }
}

extension _STLR.Rule {
    @discardableResult
    func swift(in file:TextFile)->TextFile{
        file.print("\"\".skip()")
        return file
    }
}

extension _STLR.Expression {
    @discardableResult
    func swift(in file:TextFile)->TextFile{
//        switch self {
//        case .element(let element):
//            <#code#>
//        case .sequence(let sequence):
//            file.print("[").indent()
//
//            sequence.map({""}).joined(",\n")
//
//            for element in sequence {
//
//            }
//            file.outdent().print("]")
//        case .choice(let choice):
//            <#code#>
//        }
        file.print("\"\".skip()")
        return file
    }
}

fileprivate extension TextFile {
    convenience init(){
        self.init("Temp")
    }
    
    @discardableResult
    func printFile(_ file:TextFile)->TextFile{
        printBlock(file.content)
        return file
    }
    
    @discardableResult
    func printBlock(_ block:String)->TextFile{
        for line in block.split(separator: "\n",omittingEmptySubsequences:false){
            self.print(String(line))
        }
        
        return self
    }
}

/**
 *  Regular Expression Block
 */

fileprivate let regularExpressionBlock = """
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
            fatalError("Failed to compile pattern /\\(pattern)/\\n\\(error)")
        }
    }
    """
