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
public extension STLR {
    /**
     Generates Swift code that uses OysterKit to implement the parsed grammar
     
     - Parameter grammar: The name of the class that will be generated
     - Parameter platform: The target platform for the class (note this will be depricated in a subsequent release so it is no longer required)
     - Parameter colors: A dictionary of colors that can be used by syntax coloring engines
     - Returns: A `String` containing the Swift source or `nil` if an error occured.
     */
    public func swift(in file:TextFile){
        let grammarName = grammar.scopeName
        
        file.print("internal enum \(grammarName)Tokens : Int, Token, CaseIterable, Equatable {").indent()
        file.print("typealias T = \(grammarName)Tokens")

        // Include regular expression caching
        file.printBlock(regularExpressionBlock)
        
        // The tokens
        file.print("","/// The tokens defined by the grammar","case "+grammar.allRules.compactMap({$0.identifier}).map({"`\($0)`"}).joined(separator: ", "))
        
        //
        // Rules
        //
        file.print("","/// The rule for the token","var rule : Rule {").indent()
        file.print(         "switch self {").indent()
        for rule in grammar.allRules {
            file.print("/// \(rule.identifier)","case .\(rule.identifier):").indent()

            if grammar.isLeftHandRecursive(identifier: rule.identifier) {
                let behaviour = "Behaviour(.structural(token: self), cardinality: Cardinality.one)"
                
                file.print(       "guard let cachedRule = T.leftHandRecursiveRules[self.rawValue] else {").indent()
                file.print(           "// Create recursive shell")
                file.print(           "let recursiveRule = RecursiveRule(stubFor: \(behaviour), with: \(rule.annotations?.swift ?? "[:]"))")
                file.print(           "T.leftHandRecursiveRules[self.rawValue] = recursiveRule")
                file.print(           "// Create the rule we would normally generate")
                file.printBlock(      "let rule = \(rule.swift(in: TextFile(), grammar: grammar).content)").print("")
                file.print(           "recursiveRule.surrogateRule = rule")
                file.print(           "return recursiveRule").outdent()
                file.print(       "}","")
                file.print(       "return cachedRule")
                
            } else {
                file.printBlock("return \(rule.swift(in: TextFile(), grammar: grammar).content)")
            }
            file.outdent().print("")
            
        }
        file.outdent().print("}").outdent().print("}")
        
        //
        // Cache for Recursion
        //
        if grammar.rules.filter({self.grammar.isLeftHandRecursive(identifier: $0.identifier)}).count > 0 {
            file.print("","/// Cache for left-hand recursive rules","private static var leftHandRecursiveRules = [ Int : Rule ]()")
        }
        
        let rootRules = grammar.rules.filter({grammar.isRoot(identifier: $0.identifier)})
        file.print("","/// Create a language that can be used for parsing etc")
        file.print("public static var generatedRules: [Rule] {").indent()
        file.print("return ["+rootRules.compactMap({$0.identifier}).map({"T.\($0).rule"}).joined(separator: ", ")+"]")
        file.outdent().print("}")
                
        file.outdent().print("}")
    }
}

extension STLR.Rule {
    @discardableResult
    func swift(in file:TextFile, grammar:STLR.Grammar)->TextFile{
        var suffix : String = ".reference("
        if isVoid {
            suffix += ".skipping"
        } else if isTransient {
            suffix += ".scanning"
        } else {
            suffix += ".structural(token: self)"
        }
        if let annotations = annotations {
            suffix += ", annotations: \(annotations.swift))"
        } else {
            suffix += ")"
        }
        file.printFile(terminator:"",expression.swift(in: TextFile(), grammar: grammar)).print(suffix)
        return file
    }
}

extension STLR.Expression {
    @discardableResult
    func swift(in file:TextFile, grammar:STLR.Grammar)->TextFile{
        switch self {
        case .element(let element):
            file.printFile(element.swift(in: TextFile(), grammar: grammar))
        case .sequence(let sequence):
            file.print("[").indent()
            file.printBlock(sequence.map({$0.swift(in: TextFile(), grammar: grammar).content}).joined(separator: ",\n"))
            file.outdent().print("].sequence")
        case .choice(let choice):
            file.print("[").indent()
            file.printBlock(choice.map({$0.swift(in: TextFile(), grammar: grammar).content}).joined(separator: ",\n"))
            file.outdent().print("].choice")
        }
        return file
    }
}

fileprivate func identifiersAndTerminals(for element:STLR.Element, in file:TextFile, grammar:STLR.Grammar)->TextFile{
    file.print(terminator: "", element.isTransient  ? "~" : (element.isVoid       ? "-" : ""))
    
    if let terminal = element.terminal {
        file.print(terminator: "", terminal.swift())
    } else if let identifier = element.identifier {
        file.print(terminator: "", "T.\(identifier).rule")
    } else if let group = element.group {
        let expression = String(group.expression.swift(in: TextFile(), grammar: grammar).content.dropLast())
        file.print(terminator: "", expression)
    }
    
    if case let .structural(token) = element.kind, element.identifier ?? "" != "\(token)" {
        file.print(terminator: "",".parse(as: T.\(token))")
    }
    skipStructure:
        
    switch element.cardinality {
    case .one:
        break
//        file.print(terminator: "",".require(.one)")
    case .oneOrMore:
        file.print(terminator: "",".require(.oneOrMore)")
    case .noneOrMore:
        file.print(terminator: "",".require(.noneOrMore)")
    case .optionally:
        file.print(terminator: "",".require(.optionally)")
    default:
        file.print(terminator: "","[\(element.cardinality.minimumMatches)...\(element.cardinality.maximumMatches == nil ? "" : "\(element.cardinality.maximumMatches!)")]")
    }
    
    if element.isLookahead {
        file.print(terminator: "", ".lookahead()")
    }
    if element.isNegated {
        file.print(terminator: "", ".negate()")
    }
    
    if let annotations = element.annotations?.swift, !annotations.isEmpty {
        file.print(terminator: "", ".annotatedWith("+annotations+")")
    }
    
    return file
}

extension STLR.Element {
    @discardableResult
    func swift(in file:TextFile, grammar:STLR.Grammar)->TextFile{
        if let token = token {
            let pseudoElement = STLR.Element(annotations: annotations?.filter({!$0.label.isToken}), group: nil, identifier: "\(token)", lookahead: lookahead, negated: negated, quantifier: quantifier, terminal: nil, transient: transient, void: void)
            return identifiersAndTerminals(for: pseudoElement, in: file, grammar: grammar)
        }
        
        return identifiersAndTerminals(for: self, in: file, grammar: grammar)
    }
}

extension Array where Element == STLR.Annotation {
    var swift : String {
        if isEmpty {
            return "[:]"
        }
        return "["+map({$0.swift}).joined(separator:",")+"]"
    }
}

extension STLR.Label {
    var swift : String {
        var result = "."
        switch self {
        case .definedLabel(let definedLabel):
            switch definedLabel {
            case .token, .error, .void, .transient:
                result += "\(definedLabel)"
            }
        case .customLabel(let customLabel):
            result += "custom(label:\"\(customLabel.asSwiftString.dropFirst().dropLast())\")"
        }
        return result
    }
}

extension STLR.Literal {
    var swift : String {
        switch self {
        case .string(let string):
            return ".string(\(string.stringBody.asSwiftString))"
        case .number(let number):
            return ".int(\(number))"
        case .boolean(let boolean):
            return ".bool(\(boolean))"
        }
    }
}

extension STLR.Annotation {
    var swift : String {
        return "RuleAnnotation\(label.swift):RuleAnnotationValue\(literal?.swift ?? ".set")"
    }
}

extension STLR.Terminal {
    @discardableResult
    func swift()->String{
        switch self {
            
        case .characterSet(let characterSet):
            switch characterSet.characterSetName {
            case .whitespaceOrNewline:
                return "CharacterSet.whitespacesAndNewlines"
            case .backslash:
                return "\\".asSwiftString
            default:
                return "CharacterSet\(self)s"
            }
        case .regex(let regex):
            let regex = ("^"+regex).debugDescription
            return "T.regularExpression(\(regex))"
        case .terminalString(let terminalString):
            return terminalString.terminalBody.unescaped.debugDescription
        case .characterRange(let characterRange):
            let firstString = "\(characterRange[0].terminalBody)".asSwiftString
            let lastString  = "\(characterRange[1].terminalBody)".asSwiftString
            
            return "CharacterSet(charactersIn: \(firstString).unicodeScalars.first!...\(lastString).unicodeScalars.first!)"
        }
    }
}

internal extension TextFile {
    convenience init(){
        self.init("Temp")
    }
    
    @discardableResult
    func printFile(terminator:String = "\n", _ file:TextFile)->TextFile{
        printBlock(terminator: terminator, file.content)
        return self
    }
    
    @discardableResult
    func printBlock(terminator:String = "\n", _ block:String)->TextFile{
        var lines = block.split(separator: "\n",omittingEmptySubsequences:false).map({String($0)})
        
        while let line = lines.first {
            _ = lines.removeFirst()
            self.print(terminator: lines.isEmpty ? "" : terminator, String(line))
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
