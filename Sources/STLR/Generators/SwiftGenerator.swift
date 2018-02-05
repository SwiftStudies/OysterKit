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
import OysterKit

private func tabs(_ depth:Int)->String{
    return String(repeating: "\t", count: depth)
}

private extension String {
    mutating func add(depth: Int = 0, line:String){
        self = "\(self)\(tabs(depth))\(line)\n"
    }
    
    mutating func add(depth: Int = 0, comment:String){
        self = "\(self)\(tabs(depth))// \(comment)\n"
    }
    
    var swiftSafe : String {
        var result = self.replacingOccurrences(of: "\\", with: "\\\\")
        
        result = result.replacingOccurrences(of: "\"", with: "\\\"")
        
        return result
    }
    
    var trim : String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}

/**
 Captures the different platforms supported by Swift which will influence code generation
 */
public enum Platform{
    /// The Mac platform
    case macOS
    
    /// iOS
    case iOS
    
    /// Linux or other platforms
    case foundation
    
    fileprivate var colorType : String {
        switch self {
        case .macOS:
            return "NSColor"
        case .iOS:
            return "UIColor"
        case .foundation:
            return "(r:Float,g:Float,b:Float)"
            
        }
    }
    
    fileprivate var coreLibrary : String {
        switch self {
        case .macOS:
            return "Cocoa"
        case .iOS:
            return "UIKit"
        case .foundation:
            return "Foundation"
        }
    }
    
    /**
     Generates the appropriate Swift source for a color on this platform
     
     - Parameter: A tuple containing the RGB values for the color (each a float from 0-1)
     - Returns: A String containing the Swift source
    */
    func colorLiteral(rgb:(r:Float,g:Float,b:Float))->String{
        switch self {
        case .macOS,.iOS:
           return "#colorLiteral(red:\(rgb.r), green:\(rgb.g), blue:\(rgb.b), alpha: 1)"
        case .foundation:
            return "(r:\(rgb.r),g:\(rgb.g),b:\(rgb.b))"
        }
    }
}

/// Generates Swift code that implements the specified grammar in Swift using OysterKit
public extension STLRScope {
    /**
     Generates Swift code that uses OysterKit to implement the parsed grammar
     
     - Parameter grammar: The name of the class that will be generated
     - Parameter platform: The target platform for the class (note this will be depricated in a subsequent release so it is no longer required)
     - Parameter colors: A dictionary of colors that can be used by syntax coloring engines
     - Returns: A `String` containing the Swift source or `nil` if an error occured.
    */
    func swift(grammar name:String, platform : Platform = .macOS, colors : [String : (r:Float,g:Float,b:Float)]?  = nil)->String?{
        var output = ""
        
        var hasLeftHandRecursiveRules = false
                
        output.add(comment: "")
        output.add(comment: "STLR Generated Swift File")
        output.add(comment: "")
        output.add(comment: "Generated: \(Date.init(timeIntervalSinceNow: 0))")
        output.add(comment: "")
        output.add(line: "import \(platform.coreLibrary)")
        output.add(line: "import OysterKit")
        output.add(line: "")
        output.add(comment: "")
        output.add(comment: "\(name) Parser")
        output.add(comment: "")
        output.add(line: "enum \(name) : Int, Token {")
        output.add(line: "")
        output.add(depth: 1, comment: "Convenience alias")
        output.add(depth: 1, line: "private typealias T = \(name)")
        
        //
        // Token Definition
        //
        output.add(line: "")
        output.add(depth: 1, line:      "case _transient = -1, "+self.rules.flatMap({$0.identifier}).map({"`\($0)`"}).joined(separator: ", "))

        //
        // Rules
        //
        output.add(line: "")
        output.add(depth: 1, line:      "func _rule(_ annotations: RuleAnnotations = [ : ])->Rule {")
        output.add(depth: 2, line:          "switch self {")
        output.add(depth: 2, line:      "case ._transient:")
        output.add(depth: 3, line:          "return CharacterSet(charactersIn: \"\").terminal(token: T._transient)")
        for rule in rules {
            guard let identifier = rule.identifier else {
                continue
            }
            
            output.add(depth: 2, comment:   "\(identifier)")
            output.add(depth: 2, line:      "case .\(identifier):")

            let rawRule = rule.swift(depth: 3, from: self, creating: identifier.token, annotations: identifier.annotations).trim
            if rule.leftHandRecursive {
                hasLeftHandRecursiveRules = true
                output.add(depth: 3, line:          "guard let cachedRule = \(name).leftHandRecursiveRules[self.rawValue] else {")
                output.add(depth: 4, comment:           "Create recursive shell")
                output.add(depth: 4, line:              "let recursiveRule = RecursiveRule()")
                output.add(depth: 4, line:              "\(name).leftHandRecursiveRules[self.rawValue] = recursiveRule")

                output.add(depth: 4, comment:           "Create the rule we would normally generate")
                output.add(depth: 4, line:              "let rule = \(rawRule)")
                output.add(depth: 4, line:              "recursiveRule.surrogateRule = rule")
                output.add(depth: 4, line:              "return recursiveRule")
                output.add(depth: 3, line:          "}")
                output.add(depth: 3, line:          "return cachedRule")
            } else {
                output.add(depth: 3, line:          "return "+rawRule)
            }
            
        }
        output.add(depth: 2, line:          "}")
        output.add(depth: 1, line:    "}")

        //
        // Colors
        //
        var colorDictionaryLiteral : String?
        if let colors = colors , colors.keys.count > 0 {
            colorDictionaryLiteral = ""
            
            output.add(line: "")
            output.add(depth: 1, comment: "Color Definitions")
            output.add(depth: 1, line:      "fileprivate var color : \(platform.colorType)? {")
            output.add(depth: 2, line:          "switch self {")
            for rule in rules {
                guard let identifier = rule.identifier, let colorSpec = colors[identifier.name] else {
                    continue
                }
                
                output.add(depth: 2, line:      "case .\(identifier):\treturn \(platform.colorLiteral(rgb:colorSpec))")
                
                if !colorDictionaryLiteral!.isEmpty {
                    colorDictionaryLiteral! += ", "
                }
                
                colorDictionaryLiteral = colorDictionaryLiteral! + "\"\(identifier)\" : T.\(identifier).color!"
            }
            output.add(depth: 2, line:      "default:\treturn nil")
            
            output.add(depth: 2, line:          "}")
            output.add(depth: 1, line:    "}")
            
        }
        
        output.add(line:    "")

        //
        // Color Dictionary
        //
        if let colorDictionaryLiteral = colorDictionaryLiteral {
            output.add(line: "")
            output.add(depth: 1, comment: "Color Dictionary")
            output.add(depth: 1, line: "static var tokenNameColorIndex = [\(colorDictionaryLiteral)]")
        }
        
        //
        // Cache for Recursion
        //
        if hasLeftHandRecursiveRules {
            output.add(line: "")
            output.add(depth: 1, comment: "Cache for left-hand recursive rules")
            output.add(depth: 1, line: "private static var leftHandRecursiveRules = [ Int : Rule ]()")
        }
        
        output.add(line: "")
        output.add(depth: 1, comment: "Create a language that can be used for parsing etc")
        output.add(depth: 1, line: "public static var generatedLanguage : Parser {")
        
        //Note this will need to change to include annotations on the identifier where it says \($0)._rule() it should include $0.annotations.swift but without 
        //the , annotations:
        output.add(depth: 2, line: "return Parser(grammar: ["+rootRules.flatMap({$0.identifier}).map({"T.\($0)._rule()"}).joined(separator: ", ")+"])")
        output.add(depth: 1, line: "}")

        // Something to make it easy to create an AST
        output.add(line: "")
        output.add(depth: 1, comment:   "Convient way to apply your grammar to a string")
        output.add(depth: 1, line:      "public static func parse(source: String) -> DefaultHeterogeneousAST {")
        output.add(depth: 2, line:      "return \(name).generatedLanguage.build(source: source)")
        output.add(depth: 1, line:      "}")
        
        output.add(line: "}")
    
        return output
    }
}

/// Extends with Swift Generation
internal extension STLRScope.GrammarRule{
    
    func swift(depth:Int = 0, from ast:STLRScope, creating token:Token, annotations:STLRScope.ElementAnnotations)->String{
        let depth = depth + 1
        var result = ""

        guard let expression = expression else {
            result.add(depth: depth, comment: "FATAL ERROR: Rule's expression is nil")
            return result
        }
        
        result.add(depth: depth, line: expression.swift(depth: depth, from: ast, creating: token, annotations: annotations))
        return result
    }
}

private enum TransientToken : Int, Token, CustomStringConvertible {
    fileprivate var description: String{
        return "_transient"
    }
    
    case instance = 0
}

internal extension STLRScope.Expression{
    

    
    func swift(depth:Int = 0, from ast:STLRScope, creating token:Token, annotations: STLRScope.ElementAnnotations?)->String{
        let depth = depth + 1
        var result = ""
        
        switch self {
        case .element(let element):
            /* FIXME: IF THE ELEMENT IS AN IDENTIFIER YOU CAN END UP LOOSING THE TOKEN THAT WOULD HAVE BEEN CREATED BY THIS RULE
             WRAPPING THIS IN A RECURSIVE RULE MAY BE BETTER FOR IDENTIFIERS Identifier, Quantifier, Bool, ElementAnnotations*/
            if case let .identifier(_,quantifier, lookahead,_) = element , quantifier == .one && !lookahead {
                result.add(depth: depth, line: "[\(element.swift(depth: depth, from: ast, creating: token, annotations: annotations).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))].sequence(token: self)")
            } else {
                result.add(depth: depth, line: element.swift(depth: depth, from: ast, creating: token, annotations: annotations))
            }
        case .sequence(let elements):
            result.add(depth: depth, line: "[")
            for element in elements{
                result.add(depth: depth, line: element.swift(depth: depth+1, from: ast, creating: TransientToken.instance, annotations: nil).trim+",")
            }
            if let annotations = annotations {
                result.add(depth: depth, line: "].sequence(token: T.\(token), annotations: annotations.isEmpty ? \(annotations.swiftDictionary) : annotations)")
            } else {
                result.add(depth: depth, line: "].sequence(token: T.\(token))")
            }
        case .choice(let elements):
            if scannable {
                var strings = [String]()
                for element in elements{
                    if case .terminal(let terminal,_,_,_) = element , terminal.string != nil{
                        strings.append("\""+terminal.string!.swiftSafe+"\"")
                    }
                }
                let values = strings.joined(separator: ", ")
                if let annotations = annotations {
                    result.add(depth: depth, line: "ScannerRule.oneOf(token: T.\(token), [\(values)],\(annotations.swiftDictionary).merge(with: annotations))")
                } else {
                    result.add(depth: depth, line: "ScannerRule.oneOf(token: T.\(token), [\(values)],\(annotations?.swiftDictionary ?? "[:]").merge(with: annotations))")
                }
            } else {
                result.add(depth: depth, line: "[")
                for element in elements{
                    
                    result.add(depth: depth, line: element.swift(depth: depth+1, from: ast, creating: TransientToken.instance, annotations: nil).trim+",")
                }
                result.add(depth: depth, line: "].oneOf(token: T.\(token)\(annotations?.swiftNthParameter ?? ""))")
            }
        default:
            result.add(depth: depth, comment: "FATAL ERROR: \(self) Not implemented")
        }
        
        return result
    }
}

internal extension STLRScope.ElementAnnotation{
    var swift : String {
        switch self {
        case .pinned:
            return "RuleAnnotation.pinned"
        case .error:
            return "RuleAnnotation.error"
        case .void:
            return "RuleAnnotation.void"
        case .token:
            return "RuleAnnotation.token"
        case .transient:
            return "RuleAnnotation.transient"
        case .custom(let label):
            return "RuleAnnotation.custom(label: \"\(label)\")"
        }
    }
}

internal extension STLRScope.ElementAnnotationValue{
    var swift : String {
        switch  self {
        case .set:
            return "RuleAnnotationValue.set"
        case .bool(let value):
            return "RuleAnnotationValue.bool(\(value))"
        case .string(let value):
            return "RuleAnnotationValue.string(\"\(value)\")"
        case .int(let value):
            return "RuleAnnotationValue.int(\(value))"
        }
    }
}

internal extension STLRScope.ElementAnnotationInstance{
    var swift : String {
        return "\(annotation.swift) : \(value.swift)"
    }
}

internal extension STLRScope.Element{
    func swift(depth:Int = 0, from ast:STLRScope, creating token:Token, annotations:STLRScope.ElementAnnotations?)->String{
        let depth = depth + 1
        var result = ""
        
        var quantifierAnnotations   : STLRScope.ElementAnnotations?
        var elementAnnotations      : STLRScope.ElementAnnotations?
        
        if let annotations = annotations {
            elementAnnotations = self.elementAnnotations.merge(with: annotations)
            if quantifier != .one {
                quantifierAnnotations = self.quantifierAnnotations.merge(with: annotations)
            }
        } else {
            if !self.elementAnnotations.isEmpty{
                elementAnnotations = self.elementAnnotations
            }
        }
        
        let elementToken = quantifier == .one ? token       : TransientToken.instance
        
        switch self {
        case .group(let expression, let quantity, let lookahead,_):
            result.add(depth: depth+1, line: expression.swift(depth: depth + 1, from: ast, creating: elementToken, annotations: elementAnnotations).trim+quantity.swift(creating:token, annotations: quantifierAnnotations)+(lookahead ? ".lookahead()" : ""))
        case .terminal(let terminal, let quantity,let lookahead,_):
            result.add(depth: depth,
                       line: terminal.swift(depth:depth, from: ast, creating: elementToken, annotations: elementAnnotations, allowOveride: annotations != nil).trim+quantity.swift(creating:token, annotations: quantifierAnnotations)+(lookahead ? ".lookahead()" : ""))
        case .identifier(let identifier, let quantity,let lookahead,_):
            result.add(depth: depth, line: "T.\(identifier)._rule(\(elementAnnotations?.swiftArray ?? ""))"+quantity.swift(creating:token, annotations: quantifierAnnotations)+(lookahead ? ".lookahead()" : ""))
        }

        

        return result
    }
    
}

internal extension Collection where Self.Iterator.Element == STLRScope.ElementAnnotationInstance {

    var swiftDictionary : String {
        if count == 0 {
            return "[ : ]"
        }
        return "["+map({$0.swift}).joined(separator:",")+"]"
    }
    
    var swiftArray : String {
        if count == 0 {
            return ""
        }
        return "["+map({$0.swift}).joined(separator:",")+"]"
    }
    
    var swiftNthParameter : String {
        if count == 0 {
            return ", annotations: annotations"
        }
        return ", annotations: annotations.isEmpty ? "+swiftArray+" : annotations"
    }
}

internal extension STLRScope.Modifier{
    func swift(creating token:Token, annotations: STLRScope.ElementAnnotations?)->String{
        switch self {
        case .one:
            return ""
        case .not:
            return ".not(producing: T.\(token)\(annotations?.swiftNthParameter ?? ""))"
        case .void:
            let finalAnnotations = annotations?.merge(with: [STLRScope.ElementAnnotationInstance.init(STLRScope.ElementAnnotation.void)])
            return """
                .instance(with: TransientToken.labelled("\(token)-"), andAnnotations: \(finalAnnotations?.swiftNthParameter ?? ""))
            """
        case .transient:
            return ".instance(with: TransientToken.anonymous, andAnnotations: \(annotations?.swiftNthParameter ?? ""))"
        case .zeroOrOne:
            return ".optional(producing: T.\(token)\(annotations?.swiftNthParameter ?? ""))"
        case .zeroOrMore:
            return ".repeated(min: 0, producing: T.\(token)\(annotations?.swiftNthParameter ?? ""))"
        case .oneOrMore:
            return ".repeated(min: 1, producing: T.\(token)\(annotations?.swiftNthParameter ?? ""))"
        }
    }
}

internal extension STLRScope.Identifier{
    func swift(depth:Int = 0, from ast:STLRScope, creating token:Token)->String{
        guard let grammarRule = grammarRule else {
            return "FATAL ERROR: No rule associated with identifier \(token)"
        }
        
        return grammarRule.swift(depth: depth+1, from: ast, creating: token, annotations: annotations)
    }
}

internal extension STLRScope.TerminalCharacterSet{
    var swift : String {
        switch self{
        case .alphanumerics, .decimalDigits, .letters, .lowercaseLetters, .newlines, .whitespacesAndNewlines, .whitespaces, .uppercaseLetters:
            return "CharacterSet\(self)"
        case .customRange(_, let first, let last):
            let firstString = "\(first)".swiftSafe
            let lastString  = "\(last)".swiftSafe
            
            return "CharacterSet(charactersIn: \"\(firstString)\".unicodeScalars.first!...\"\(lastString)\".unicodeScalars.first!)"
        case .multipleSets(let characterSets):
            var first = true
            let union = characterSets.map({
                let close = first ? "" : ")"
                first = false
                
                let swiftCharacterSet = $0.swift
                
                return "\(swiftCharacterSet)\(close)"
            }).joined(separator: ".union(")
            
            return union
        case .customString(let string):
            return "CharacterSet(charactersIn: \"\(string.swiftSafe)\")"
        }
    }
}


internal extension STLRScope.Terminal{
    func swift(depth:Int = 0, from ast:STLRScope, creating token:Token, annotations: STLRScope.ElementAnnotations?, allowOveride: Bool)->String{
        let depth = depth + 1
        var result = ""
        
        let annotationParameter : String
        
        if let annotations = annotations {
            if allowOveride {
                annotationParameter = annotations.swiftNthParameter
            } else {
                annotationParameter = ", annotations: "+annotations.swiftArray
            }
        } else {
            annotationParameter = ""
        }
        
        switch (string,characterSet){
        case (let sv,_) where sv != nil:
            result.add(depth:depth, line:"\"\(sv!.swiftSafe)\".terminal(token: T.\(token)\(annotationParameter))")
        case (_, let terminalCharacterSet) where terminalCharacterSet != nil:
            return "\(terminalCharacterSet!.swift).terminal(token: T.\(token)\(annotationParameter))"
        default:
            return "❌ \(self) not implemented"
        }
        
        return result
    }
    
}
