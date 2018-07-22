import Foundation
import OysterKit

/// Intermediate Representation of the grammar
fileprivate enum STLRRules : Int, Token {
    
    // Convenience alias
    private typealias T = STLRRules
    // Cache for compiled regular expressions
    private static var regularExpressionCache = [String : NSRegularExpression]()
    
    // Returns a pre-compiled pattern from the cache, or if not in the cache builds
    // the pattern, caches and returns the regular expression
    //
    //  - Parameter pattern: The pattern the should be built
    //  - Returns: A compiled version of the pattern
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
    
    case _transient = -1, `whitespace`, `ows`, `quantifier`, `negated`, `lookahead`, `transient`, `void`, `terminalBody`, `stringBody`, `string`, `terminalString`, `characterSetName`, `characterSet`, `rangeOperator`, `characterRange`, `number`, `boolean`, `literal`, `annotation`, `annotations`, `customLabel`, `definedLabel`, `label`, `regexDelimeter`, `startRegex`, `endRegex`, `regexBody`, `regex`, `terminal`, `group`, `identifier`, `element`, `assignmentOperators`, `or`, `then`, `choice`, `notNewRule`, `sequence`, `expression`, `tokenType`, `standardType`, `customType`, `lhs`, `rule`, `moduleName`, `moduleImport`, `scopeName`, `modules`, `rules`, `grammar`
    
    func _rule(_ annotations: RuleAnnotations = [ : ])->Rule {
        switch self {
        case ._transient:
            return CharacterSet(charactersIn: "").terminal(token: T._transient)
        // whitespace
        case .whitespace:
            return ScannerRule.regularExpression(token: T.whitespace, regularExpression: T.regularExpression("^[:space:]+|/\\*(?:.|\\r?\\n)*?\\*/|//.*(?:\\r?\\n|$)"), annotations: annotations.isEmpty ? [RuleAnnotation.void : RuleAnnotationValue.set] : annotations)
        // ows
        case .ows:
            return T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T.ows, annotations: annotations.isEmpty ? [RuleAnnotation.void : RuleAnnotationValue.set] : annotations)
        // quantifier
        case .quantifier:
            return CharacterSet(charactersIn: "*+?-").terminal(token: T.quantifier, annotations: annotations)
        // negated
        case .negated:
            return "!".terminal(token: T.negated, annotations: annotations)
        // lookahead
        case .lookahead:
            return ">>".terminal(token: T.lookahead, annotations: annotations)
        // transient
        case .transient:
            return "~".terminal(token: T.transient, annotations: annotations)
        // void
        case .void:
            return "-".terminal(token: T.void, annotations: annotations)
        // terminalBody
        case .terminalBody:
            return ScannerRule.regularExpression(token: T.terminalBody, regularExpression: T.regularExpression("^(\\\\.|[^\"\\\\\\n])+"), annotations: annotations)
        // stringBody
        case .stringBody:
            return ScannerRule.regularExpression(token: T.stringBody, regularExpression: T.regularExpression("^(\\\\.|[^\"\\\\\\n])*"), annotations: annotations)
        // string
        case .string:
            return [
                "\"".terminal(token: T._transient, annotations: [RuleAnnotation.void : RuleAnnotationValue.set]),
                T.stringBody._rule(),
                "\"".terminal(token: T._transient, annotations: [RuleAnnotation.error : RuleAnnotationValue.string("Missing terminating quote"),RuleAnnotation.void : RuleAnnotationValue.set]),
                ].sequence(token: T.string, annotations: annotations.isEmpty ? [ : ] : annotations)
        // terminalString
        case .terminalString:
            return [
                "\"".terminal(token: T._transient, annotations: [RuleAnnotation.void : RuleAnnotationValue.set]),
                T.terminalBody._rule([RuleAnnotation.error : RuleAnnotationValue.string("Terminals must have at least one character")]),
                "\"".terminal(token: T._transient, annotations: [RuleAnnotation.error : RuleAnnotationValue.string("Missing terminating quote"),RuleAnnotation.void : RuleAnnotationValue.set]),
                ].sequence(token: T.terminalString, annotations: annotations.isEmpty ? [ : ] : annotations)
        // characterSetName
        case .characterSetName:
            return ScannerRule.oneOf(token: T.characterSetName, ["letter", "uppercaseLetter", "lowercaseLetter", "alphaNumeric", "decimalDigit", "whitespaceOrNewline", "whitespace", "newline", "backslash"],[ : ].merge(with: annotations))
        // characterSet
        case .characterSet:
            return [
                ".".terminal(token: T._transient),
                T.characterSetName._rule([RuleAnnotation.error : RuleAnnotationValue.string("Unknown character set")]),
                ].sequence(token: T.characterSet, annotations: annotations.isEmpty ? [ : ] : annotations)
        // rangeOperator
        case .rangeOperator:
            return [
                "..".terminal(token: T._transient),
                ".".terminal(token: T._transient, annotations: [RuleAnnotation.error : RuleAnnotationValue.string("Expected ... in character range")]),
                ].sequence(token: T.rangeOperator, annotations: annotations.isEmpty ? [RuleAnnotation.void : RuleAnnotationValue.set] : annotations)
        // characterRange
        case .characterRange:
            return [
                T.terminalString._rule(),
                T.rangeOperator._rule([RuleAnnotation.void : RuleAnnotationValue.set]),
                T.terminalString._rule([RuleAnnotation.error : RuleAnnotationValue.string("Range must be terminated")]),
                ].sequence(token: T.characterRange, annotations: annotations.isEmpty ? [ : ] : annotations)
        // number
        case .number:
            return [
                CharacterSet(charactersIn: "-+").terminal(token: T._transient).optional(producing: T._transient),
                CharacterSet.decimalDigits.terminal(token: T._transient).repeated(min: 1, producing: T._transient),
                ].sequence(token: T.number, annotations: annotations.isEmpty ? [RuleAnnotation.type : RuleAnnotationValue.string("Int")] : annotations)
        // boolean
        case .boolean:
            return ScannerRule.oneOf(token: T.boolean, ["true", "false"],[RuleAnnotation.type : RuleAnnotationValue.string("Bool")].merge(with: annotations))
        // literal
        case .literal:
            return [
                T.string._rule(),
                T.number._rule([RuleAnnotation.type : RuleAnnotationValue.string("Int")]),
                T.boolean._rule([RuleAnnotation.type : RuleAnnotationValue.string("Bool")]),
                ].oneOf(token: T.literal, annotations: annotations)
        // annotation
        case .annotation:
            return [
                "@".terminal(token: T._transient),
                T.label._rule([RuleAnnotation.error : RuleAnnotationValue.string("Expected an annotation label")]),
                [
                    "(".terminal(token: T._transient),
                    T.literal._rule([RuleAnnotation.error : RuleAnnotationValue.string("A value must be specified or the () omitted")]),
                    ")".terminal(token: T._transient, annotations: [RuleAnnotation.error : RuleAnnotationValue.string("Missing ')'")]),
                    ].sequence(token: T._transient).optional(producing: T._transient),
                ].sequence(token: T.annotation, annotations: annotations.isEmpty ? [ : ] : annotations)
        // annotations
        case .annotations:
            return [
                T.annotation._rule(),
                T.ows._rule([RuleAnnotation.void : RuleAnnotationValue.set]),
                ].sequence(token: T._transient, annotations: annotations.isEmpty ? [ : ] : annotations).repeated(min: 1, producing: T.annotations, annotations: annotations)
        // customLabel
        case .customLabel:
            return [
                CharacterSet.letters.union(CharacterSet(charactersIn: "_")).terminal(token: T._transient),
                CharacterSet.letters.union(CharacterSet.decimalDigits).union(CharacterSet(charactersIn: "_")).terminal(token: T._transient).repeated(min: 0, producing: T._transient),
                ].sequence(token: T.customLabel, annotations: annotations.isEmpty ? [ : ] : annotations)
        // definedLabel
        case .definedLabel:
            return ScannerRule.oneOf(token: T.definedLabel, ["token", "error", "void", "transient"],[ : ].merge(with: annotations))
        // label
        case .label:
            return [
                T.definedLabel._rule(),
                T.customLabel._rule(),
                ].oneOf(token: T.label, annotations: annotations)
        // regexDelimeter
        case .regexDelimeter:
            return "/".terminal(token: T.regexDelimeter, annotations: annotations.isEmpty ? [RuleAnnotation.void : RuleAnnotationValue.set] : annotations)
        // startRegex
        case .startRegex:
            return [
                "/".terminal(token: T._transient, annotations: [RuleAnnotation.void : RuleAnnotationValue.set]),
                "*".terminal(token: T._transient).not(producing: T._transient).lookahead(),
                "/".terminal(token: T._transient).not(producing: T._transient).lookahead(),
                ].sequence(token: T.startRegex, annotations: annotations.isEmpty ? [RuleAnnotation.void : RuleAnnotationValue.set] : annotations)
        // endRegex
        case .endRegex:
            return "/".terminal(token: T.endRegex, annotations: annotations.isEmpty ? [RuleAnnotation.void : RuleAnnotationValue.set] : annotations)
        // regexBody
        case .regexBody:
            return [
                T.regexDelimeter._rule([RuleAnnotation.void : RuleAnnotationValue.set]),
                T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]),
                ].sequence(token: T._transient, annotations: annotations.isEmpty ? [RuleAnnotation.transient : RuleAnnotationValue.set] : annotations).not(producing: T._transient, annotations: annotations.isEmpty ? [RuleAnnotation.transient : RuleAnnotationValue.set] : annotations).repeated(min: 1, producing: T.regexBody, annotations: annotations.isEmpty ? [RuleAnnotation.transient : RuleAnnotationValue.set] : annotations)
        // regex
        case .regex:
            return [
                T.startRegex._rule([RuleAnnotation.void : RuleAnnotationValue.set]),
                T.regexBody._rule([RuleAnnotation.transient : RuleAnnotationValue.set]),
                T.endRegex._rule([RuleAnnotation.void : RuleAnnotationValue.set]),
                ].sequence(token: T.regex, annotations: annotations.isEmpty ? [ : ] : annotations)
        // terminal
        case .terminal:
            return [
                T.characterSet._rule(),
                T.characterRange._rule(),
                T.terminalString._rule(),
                T.regex._rule(),
                ].oneOf(token: T.terminal, annotations: annotations)
        // group
        case .group:
            guard let cachedRule = STLRRules.leftHandRecursiveRules[self.rawValue] else {
                // Create recursive shell
                let recursiveRule = RecursiveRule(stubFor: self, with: annotations.isEmpty ? [ : ] : annotations)
                STLRRules.leftHandRecursiveRules[self.rawValue] = recursiveRule
                // Create the rule we would normally generate
                let rule = [
                    "(".terminal(token: T._transient),
                    T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                    T.expression._rule(),
                    T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                    ")".terminal(token: T._transient, annotations: [RuleAnnotation.error : RuleAnnotationValue.string("Expected ')'")]),
                    ].sequence(token: T._transient)
                recursiveRule.surrogateRule = rule
                return recursiveRule
            }
            return cachedRule
        // identifier
        case .identifier:
            return ScannerRule.regularExpression(token: T.identifier, regularExpression: T.regularExpression("^[:alpha:]\\w*|_\\w*"), annotations: annotations)
        // element
        case .element:
            guard let cachedRule = STLRRules.leftHandRecursiveRules[self.rawValue] else {
                // Create recursive shell
                let recursiveRule = RecursiveRule(stubFor: self, with: annotations.isEmpty ? [ : ] : annotations)
                STLRRules.leftHandRecursiveRules[self.rawValue] = recursiveRule
                // Create the rule we would normally generate
                let rule = [
                    T.annotations._rule().optional(producing: T._transient),
                    [
                        T.lookahead._rule(),
                        T.transient._rule(),
                        T.void._rule(),
                        ].oneOf(token: T._transient).optional(producing: T._transient),
                    T.negated._rule().optional(producing: T._transient),
                    [
                        T.group._rule(),
                        T.terminal._rule(),
                        [
                            T.identifier._rule(),
                            [
                                T.ows._rule([RuleAnnotation.void : RuleAnnotationValue.set]),
                                "=".terminal(token: T._transient),
                                ].sequence(token: T._transient).not(producing: T._transient).lookahead(),
                            ].sequence(token: T._transient),
                        ].oneOf(token: T._transient),
                    T.quantifier._rule().optional(producing: T._transient),
                    ].sequence(token: T._transient)
                recursiveRule.surrogateRule = rule
                return recursiveRule
            }
            return cachedRule
        // assignmentOperators
        case .assignmentOperators:
            return ScannerRule.oneOf(token: T.assignmentOperators, ["=", "+=", "|="],[ : ].merge(with: annotations))
        // or
        case .or:
            return [
                T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                "|".terminal(token: T._transient),
                T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                ].sequence(token: T.or, annotations: annotations.isEmpty ? [RuleAnnotation.void : RuleAnnotationValue.set] : annotations)
        // then
        case .then:
            return [
                [
                    T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                    "+".terminal(token: T._transient),
                    T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                    ].sequence(token: T._transient),
                T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 1, producing: T._transient),
                ].oneOf(token: T.then, annotations: annotations.isEmpty ? [RuleAnnotation.void : RuleAnnotationValue.set] : annotations)
        // choice
        case .choice:
            guard let cachedRule = STLRRules.leftHandRecursiveRules[self.rawValue] else {
                // Create recursive shell
                let recursiveRule = RecursiveRule(stubFor: self, with: annotations.isEmpty ? [ : ] : annotations)
                STLRRules.leftHandRecursiveRules[self.rawValue] = recursiveRule
                // Create the rule we would normally generate
                let rule = [
                    T.element._rule(),
                    [
                        T.or._rule([RuleAnnotation.void : RuleAnnotationValue.set]),
                        T.element._rule([RuleAnnotation.error : RuleAnnotationValue.string("Expected terminal, identifier, or group")]),
                        ].sequence(token: T._transient).repeated(min: 1, producing: T._transient),
                    ].sequence(token: T._transient)
                recursiveRule.surrogateRule = rule
                return recursiveRule
            }
            return cachedRule
        // notNewRule
        case .notNewRule:
            return [
                T.annotations._rule().optional(producing: T._transient),
                T.identifier._rule(),
                T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                [
                    ":".terminal(token: T._transient),
                    T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                    CharacterSet.letters.terminal(token: T._transient).repeated(min: 1, producing: T._transient),
                    T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                    ].sequence(token: T._transient).optional(producing: T._transient),
                T.assignmentOperators._rule(),
                ].sequence(token: T._transient, annotations: annotations.isEmpty ? [ : ] : annotations).not(producing: T.notNewRule, annotations: annotations)
        // sequence
        case .sequence:
            guard let cachedRule = STLRRules.leftHandRecursiveRules[self.rawValue] else {
                // Create recursive shell
                let recursiveRule = RecursiveRule(stubFor: self, with: annotations.isEmpty ? [ : ] : annotations)
                STLRRules.leftHandRecursiveRules[self.rawValue] = recursiveRule
                // Create the rule we would normally generate
                let rule = [
                    T.element._rule(),
                    [
                        T.then._rule([RuleAnnotation.void : RuleAnnotationValue.set]),
                        T.notNewRule._rule().lookahead(),
                        T.element._rule([RuleAnnotation.error : RuleAnnotationValue.string("Expected terminal, identifier, or group")]),
                        ].sequence(token: T._transient).repeated(min: 1, producing: T._transient),
                    ].sequence(token: T._transient)
                recursiveRule.surrogateRule = rule
                return recursiveRule
            }
            return cachedRule
        // expression
        case .expression:
            guard let cachedRule = STLRRules.leftHandRecursiveRules[self.rawValue] else {
                // Create recursive shell
                let recursiveRule = RecursiveRule(stubFor: self, with: annotations.isEmpty ? [ : ] : annotations)
                STLRRules.leftHandRecursiveRules[self.rawValue] = recursiveRule
                // Create the rule we would normally generate
                let rule = [
                    T.choice._rule(),
                    T.sequence._rule(),
                    T.element._rule(),
                    ].oneOf(token: T._transient)
                recursiveRule.surrogateRule = rule
                return recursiveRule
            }
            return cachedRule
        // tokenType
        case .tokenType:
            return [
                T.standardType._rule(),
                T.customType._rule(),
                ].oneOf(token: T.tokenType, annotations: annotations)
        // standardType
        case .standardType:
            return ScannerRule.oneOf(token: T.standardType, ["Int", "Double", "String", "Bool"],[ : ].merge(with: annotations))
        // customType
        case .customType:
            return [
                CharacterSet.uppercaseLetters.union(CharacterSet(charactersIn: "_")).terminal(token: T._transient),
                CharacterSet.letters.union(CharacterSet.decimalDigits).union(CharacterSet(charactersIn: "_")).terminal(token: T._transient).repeated(min: 0, producing: T._transient),
                ].sequence(token: T.customType, annotations: annotations.isEmpty ? [ : ] : annotations)
        // lhs
        case .lhs:
            return [
                T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                T.annotations._rule().optional(producing: T._transient),
                T.transient._rule().optional(producing: T._transient),
                T.void._rule().optional(producing: T._transient),
                T.identifier._rule(),
                T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                [
                    ":".terminal(token: T._transient, annotations: [RuleAnnotation.void : RuleAnnotationValue.set]),
                    T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                    T.tokenType._rule(),
                    T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                    ].sequence(token: T._transient).optional(producing: T._transient),
                T.assignmentOperators._rule(),
                ].sequence(token: T.lhs, annotations: annotations.isEmpty ? [RuleAnnotation.transient : RuleAnnotationValue.set] : annotations)
        // rule
        case .rule:
            return [
                T.lhs._rule([RuleAnnotation.transient : RuleAnnotationValue.set]),
                T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                T.expression._rule([RuleAnnotation.error : RuleAnnotationValue.string("Expected expression")]),
                T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                ].sequence(token: T.rule, annotations: annotations.isEmpty ? [ : ] : annotations)
        // moduleName
        case .moduleName:
            return [
                CharacterSet.letters.union(CharacterSet(charactersIn: "_")).terminal(token: T._transient),
                CharacterSet.letters.union(CharacterSet.decimalDigits).union(CharacterSet(charactersIn: "_")).terminal(token: T._transient).repeated(min: 0, producing: T._transient),
                ].sequence(token: T.moduleName, annotations: annotations.isEmpty ? [ : ] : annotations)
        // moduleImport
        case .moduleImport:
            return [
                T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                "import".terminal(token: T._transient),
                CharacterSet.whitespaces.terminal(token: T._transient).repeated(min: 1, producing: T._transient),
                T.moduleName._rule(),
                T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 1, producing: T._transient),
                ].sequence(token: T.moduleImport, annotations: annotations.isEmpty ? [ : ] : annotations)
        // scopeName
        case .scopeName:
            return [
                [
                    "grammar".terminal(token: T._transient),
                    T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                    ].sequence(token: T._transient, annotations: annotations.isEmpty ? [RuleAnnotation.void : RuleAnnotationValue.set] : annotations),
                [
                    CharacterSet.letters.terminal(token: T._transient),
                    CharacterSet.letters.union(CharacterSet.decimalDigits).terminal(token: T._transient).repeated(min: 0, producing: T._transient),
                    ].sequence(token: T._transient),
                T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                ].sequence(token: T.scopeName, annotations: annotations.isEmpty ? [ : ] : annotations)
        // modules
        case .modules:
            return T.moduleImport._rule().repeated(min: 0, producing: T.modules, annotations: annotations)
        // rules
        case .rules:
            return T.rule._rule().repeated(min: 1, producing: T.rules, annotations: annotations.isEmpty ? [RuleAnnotation.error : RuleAnnotationValue.string("Expected at least one rule")] : annotations)
        // grammar
        case .grammar:
            return [
                T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                T.scopeName._rule([RuleAnnotation.error : RuleAnnotationValue.string("You must declare the name of the grammar before any other declarations (e.g. grammar <your-grammar-name>)")]),
                T.modules._rule(),
                T.rules._rule(),
                ].sequence(token: T.grammar, annotations: annotations.isEmpty ? [ : ] : annotations)
        }
    }
    
    
    // Cache for left-hand recursive rules
    private static var leftHandRecursiveRules = [ Int : Rule ]()
    
    // Create a language that can be used for parsing etc
    public static var generatedLanguage : Parser {
        return Parser(grammar: [T.grammar._rule()])
    }
    
    // Convient way to apply your grammar to a string
    public static func parse(source: String) throws -> HomogenousTree {
        return try AbstractSyntaxTreeConstructor().build(source, using: generatedLanguage)
    }
}

public struct _STLR : Codable {
    
    // Quantifier
    public enum Quantifier : Swift.String, Codable {
        case star = "*",plus = "+",questionMark = "?",dash = "-"
    }
    
    /// String
    public struct String : Codable {
        public let stringBody: Swift.String
    }
    
    /// TerminalString
    public struct TerminalString : Codable {
        public let terminalBody: Swift.String
    }
    
    // CharacterSetName
    public enum CharacterSetName : Swift.String, Codable {
        case letter,uppercaseLetter,lowercaseLetter,alphaNumeric,decimalDigit,whitespaceOrNewline,whitespace,newline,backslash
    }
    
    /// CharacterSet
    public struct CharacterSet : Codable {
        public let characterSetName: CharacterSetName
    }
    
    public typealias CharacterRange = [TerminalString]
    
    // Boolean
    public enum Boolean : Swift.String, Codable {
        case `true` = "true",`false` = "false"
    }
    
    // Literal
    public enum Literal : Codable {
        case string(string:String)
        case number(number:Int)
        case boolean(boolean:Boolean)
        
        enum CodingKeys : Swift.String, CodingKey {
            case string,number,boolean
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            if let string = try? container.decode(String.self, forKey: .string){
                self = .string(string: string)
                return
            } else if let number = try? container.decode(Int.self, forKey: .number){
                self = .number(number: number)
                return
            } else if let boolean = try? container.decode(Boolean.self, forKey: .boolean){
                self = .boolean(boolean: boolean)
                return
            }
            throw DecodingError.valueNotFound(Expression.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Tried to decode one of String,Int,Boolean but found none of those types"))
        }
        public func encode(to encoder:Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .string(let string):
                try container.encode(string, forKey: .string)
            case .number(let number):
                try container.encode(number, forKey: .number)
            case .boolean(let boolean):
                try container.encode(boolean, forKey: .boolean)
            }
        }
    }
    
    /// Annotation
    public struct Annotation : Codable {
        public let literal: Literal?
        public let label: Label
    }
    
    public typealias Annotations = [Annotation]
    
    // DefinedLabel
    public enum DefinedLabel : Swift.String, Codable {
        case token,error,void,transient
    }
    
    // Label
    public enum Label : Codable {
        case definedLabel(definedLabel:DefinedLabel)
        case customLabel(customLabel:Swift.String)
        
        enum CodingKeys : Swift.String, CodingKey {
            case definedLabel,customLabel
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            if let definedLabel = try? container.decode(DefinedLabel.self, forKey: .definedLabel){
                self = .definedLabel(definedLabel: definedLabel)
                return
            } else if let customLabel = try? container.decode(Swift.String.self, forKey: .customLabel){
                self = .customLabel(customLabel: customLabel)
                return
            }
            throw DecodingError.valueNotFound(Expression.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Tried to decode one of DefinedLabel,Swift.String but found none of those types"))
        }
        public func encode(to encoder:Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .definedLabel(let definedLabel):
                try container.encode(definedLabel, forKey: .definedLabel)
            case .customLabel(let customLabel):
                try container.encode(customLabel, forKey: .customLabel)
            }
        }
    }
    
    // Terminal
    public enum Terminal : Codable {
        case characterSet(characterSet:CharacterSet)
        case regex(regex:Swift.String)
        case terminalString(terminalString:TerminalString)
        case characterRange(characterRange:CharacterRange)
        
        enum CodingKeys : Swift.String, CodingKey {
            case characterSet,regex,terminalString,characterRange
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            if let characterSet = try? container.decode(CharacterSet.self, forKey: .characterSet){
                self = .characterSet(characterSet: characterSet)
                return
            } else if let regex = try? container.decode(Swift.String.self, forKey: .regex){
                self = .regex(regex: regex)
                return
            } else if let terminalString = try? container.decode(TerminalString.self, forKey: .terminalString){
                self = .terminalString(terminalString: terminalString)
                return
            } else if let characterRange = try? container.decode(CharacterRange.self, forKey: .characterRange){
                self = .characterRange(characterRange: characterRange)
                return
            }
            throw DecodingError.valueNotFound(Expression.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Tried to decode one of CharacterSet,Swift.String,TerminalString,CharacterRange but found none of those types"))
        }
        public func encode(to encoder:Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .characterSet(let characterSet):
                try container.encode(characterSet, forKey: .characterSet)
            case .regex(let regex):
                try container.encode(regex, forKey: .regex)
            case .terminalString(let terminalString):
                try container.encode(terminalString, forKey: .terminalString)
            case .characterRange(let characterRange):
                try container.encode(characterRange, forKey: .characterRange)
            }
        }
    }
    
    /// Group
    public class Group : Codable {
        public let expression: Expression
    }
    
    /// Element
    public class Element : Codable {
        public let group: Group?
        public let annotations: Annotations?
        public let void: Swift.String?
        public let lookahead: Swift.String?
        public let negated: Swift.String?
        public let identifier: Swift.String?
        public let quantifier: Quantifier?
        public let transient: Swift.String?
        public let terminal: Terminal?
    }
    
    // AssignmentOperators
    public enum AssignmentOperators : Swift.String, Codable {
        case equals = "=",plusEquals = "+=",pipeEquals = "|="
    }
    
    public typealias Choice = [Element]
    
    public typealias Sequence = [Element]
    
    // Expression
    public enum Expression : Codable {
        case element(element:Element)
        case sequence(sequence:Sequence)
        case choice(choice:Choice)
        
        enum CodingKeys : Swift.String, CodingKey {
            case element,sequence,choice
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            if let element = try? container.decode(Element.self, forKey: .element){
                self = .element(element: element)
                return
            } else if let sequence = try? container.decode(Sequence.self, forKey: .sequence){
                self = .sequence(sequence: sequence)
                return
            } else if let choice = try? container.decode(Choice.self, forKey: .choice){
                self = .choice(choice: choice)
                return
            }
            throw DecodingError.valueNotFound(Expression.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Tried to decode one of Element,Sequence,Choice but found none of those types"))
        }
        public func encode(to encoder:Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .element(let element):
                try container.encode(element, forKey: .element)
            case .sequence(let sequence):
                try container.encode(sequence, forKey: .sequence)
            case .choice(let choice):
                try container.encode(choice, forKey: .choice)
            }
        }
    }
    
    // TokenType
    public enum TokenType : Codable {
        case standardType(standardType:StandardType)
        case customType(customType:Swift.String)
        
        enum CodingKeys : Swift.String, CodingKey {
            case standardType,customType
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            if let standardType = try? container.decode(StandardType.self, forKey: .standardType){
                self = .standardType(standardType: standardType)
                return
            } else if let customType = try? container.decode(Swift.String.self, forKey: .customType){
                self = .customType(customType: customType)
                return
            }
            throw DecodingError.valueNotFound(Expression.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Tried to decode one of StandardType,Swift.String but found none of those types"))
        }
        public func encode(to encoder:Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .standardType(let standardType):
                try container.encode(standardType, forKey: .standardType)
            case .customType(let customType):
                try container.encode(customType, forKey: .customType)
            }
        }
    }
    
    // StandardType
    public enum StandardType : Swift.String, Codable {
        case int = "Int",double = "Double",string = "String",bool = "Bool"
    }
    
    /// Rule
    public struct Rule : Codable {
        public let assignmentOperators: AssignmentOperators
        public let annotations: Annotations?
        public let identifier: Swift.String
        public let void: Swift.String?
        public let expression: Expression
        public let transient: Swift.String?
        public let tokenType: TokenType?
    }
    
    /// ModuleImport
    public struct ModuleImport : Codable {
        public let moduleName: Swift.String
    }
    
    public typealias Modules = [ModuleImport]
    
    public typealias Rules = [Rule]
    
    /// Grammar
    public struct Grammar : Codable {
        public let modules: Modules?
        public let rules: Rules
        public let scopeName: Swift.String
    }
    public let grammar : Grammar
    /**
     Parses the supplied string using the generated grammar into a new instance of
     the generated data structure
     
     - Parameter source: The string to parse
     - Returns: A new instance of the data-structure
     */
    public static func build(_ source : Swift.String) throws ->_STLR{
        let root = HomogenousTree(with: LabelledToken(withLabel: "root"), matching: source, children: [try AbstractSyntaxTreeConstructor().build(source, using: STLRRules.generatedLanguage)])
        // print(root.description)
        return try ParsingDecoder().decode(_STLR.self, using: root)
    }
    
    public static let generatedLanguage = STLRRules.generatedLanguage
}
