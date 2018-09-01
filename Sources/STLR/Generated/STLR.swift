import Foundation
import OysterKit

/// Intermediate Representation of the grammar
internal enum STLRTokens : Int, TokenType, CaseIterable, Equatable {
    typealias T = STLRTokens
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
    case `whitespace`, `ows`, `quantifier`, `negated`, `lookahead`, `transient`, `void`, `stringQuote`, `terminalBody`, `stringBody`, `string`, `terminalString`, `characterSetName`, `characterSet`, `rangeOperator`, `characterRange`, `number`, `boolean`, `literal`, `annotation`, `annotations`, `customLabel`, `definedLabel`, `label`, `regexDelimeter`, `startRegex`, `endRegex`, `regexBody`, `regex`, `terminal`, `group`, `identifier`, `element`, `assignmentOperators`, `or`, `then`, `choice`, `notNewRule`, `sequence`, `expression`, `tokenType`, `standardType`, `customType`, `lhs`, `rule`, `moduleName`, `moduleImport`, `scopeName`, `grammar`, `modules`, `rules`
    
    /// The rule for the token
    var rule : Rule {
        switch self {
            /// whitespace
            case .whitespace:
                return T.regularExpression("^[:space:]+|/\\*(?:.|\\r?\\n)*?\\*/|//.*(?:\\r?\\n|$)").reference(.skipping)
                            
            /// ows
            case .ows:
                return T.whitespace.rule.require(.zeroOrMore).reference(.skipping)
                            
            /// quantifier
            case .quantifier:
                return [    "*",    "+",    "?",    "-"].choice.reference(.structural(token: self))
                            
            /// negated
            case .negated:
                return "!".reference(.structural(token: self))
                            
            /// lookahead
            case .lookahead:
                return ">>".reference(.structural(token: self))
                            
            /// transient
            case .transient:
                return "~".reference(.structural(token: self))
                            
            /// void
            case .void:
                return "-".reference(.structural(token: self))
                            
            /// stringQuote
            case .stringQuote:
                return "\"".reference(.structural(token: self))
                            
            /// terminalBody
            case .terminalBody:
                return T.regularExpression("^(\\\\.|[^\"\\\\\\n])+").reference(.structural(token: self))
                            
            /// stringBody
            case .stringBody:
                return T.regularExpression("^(\\\\.|[^\"\\\\\\n])*").reference(.structural(token: self))
                            
            /// string
            case .string:
                return [    -T.stringQuote.rule,    T.stringBody.rule,    -T.stringQuote.rule.annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string("Missing terminating quote")])].sequence.reference(.structural(token: self))
                            
            /// terminalString
            case .terminalString:
                return [    -T.stringQuote.rule,    T.terminalBody.rule.annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string("Terminals must have at least one character")]),    -T.stringQuote.rule.annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string("Missing terminating quote")])].sequence.reference(.structural(token: self))
                            
            /// characterSetName
            case .characterSetName:
                return [    "letter",    "uppercaseLetter",    "lowercaseLetter",    "alphaNumeric",    "decimalDigit",    "whitespaceOrNewline",    "whitespace",    "newline",    "backslash"].choice.reference(.structural(token: self))
                            
            /// characterSet
            case .characterSet:
                return [    -".",    T.characterSetName.rule.annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string("Unknown character set")])].sequence.reference(.structural(token: self))
                            
            /// rangeOperator
            case .rangeOperator:
                return [    "..",    ".".annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string("Expected ... in character range")])].sequence.reference(.skipping)
                            
            /// characterRange
            case .characterRange:
                return [    T.terminalString.rule,    T.rangeOperator.rule,    T.terminalString.rule.annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string("Range must be terminated")])].sequence.reference(.structural(token: self))
                            
            /// number
            case .number:
                return [    [        "-",        "+"].choice.require(.zeroOrOne),    CharacterSet.decimalDigits.require(.oneOrMore)].sequence.reference(.structural(token: self))
                            
            /// boolean
            case .boolean:
                return [    "true",    "false"].choice.reference(.structural(token: self))
                            
            /// literal
            case .literal:
                return [    T.string.rule,    T.number.rule,    T.boolean.rule].choice.reference(.structural(token: self))
                            
            /// annotation
            case .annotation:
                return [    "@",    T.label.rule.annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string("Expected an annotation label")]),    [        "(",        T.literal.rule.annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string("A value must be specified or the () omitted")]),        ")".annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string("Missing \')\'")])].sequence.require(.zeroOrOne)].sequence.reference(.structural(token: self))
                            
            /// annotations
            case .annotations:
                return [    T.annotation.rule,    T.ows.rule].sequence.require(.oneOrMore).reference(.structural(token: self))
                            
            /// customLabel
            case .customLabel:
                return [    [        CharacterSet.letters,        "_"].choice.annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string("Labels must start with a letter or _")]),    [        CharacterSet.letters,        CharacterSet.decimalDigits,        "_"].choice.require(.zeroOrMore)].sequence.reference(.structural(token: self))
                            
            /// definedLabel
            case .definedLabel:
                return [    "token",    "error",    "void",    "transient"].choice.reference(.structural(token: self))
                            
            /// label
            case .label:
                return [    T.definedLabel.rule,    T.customLabel.rule].choice.reference(.structural(token: self))
                            
            /// regexDelimeter
            case .regexDelimeter:
                return "/".reference(.skipping)
                            
            /// startRegex
            case .startRegex:
                return [    T.regexDelimeter.rule,    "*".lookahead().negate()].sequence.reference(.skipping)
                            
            /// endRegex
            case .endRegex:
                return T.regexDelimeter.rule.reference(.skipping)
                            
            /// regexBody
            case .regexBody:
                return [    T.regexDelimeter.rule,    T.whitespace.rule].sequence.require(.oneOrMore).negate().reference(.scanning)
                            
            /// regex
            case .regex:
                return [    T.startRegex.rule,    T.regexBody.rule,    T.endRegex.rule].sequence.reference(.structural(token: self))
                            
            /// terminal
            case .terminal:
                return [    T.characterSet.rule,    T.characterRange.rule,    T.terminalString.rule,    T.regex.rule].choice.reference(.structural(token: self))
                            
            /// group
            case .group:
                guard let cachedRule = T.leftHandRecursiveRules[self.rawValue] else {
                    // Create recursive shell
                    let recursiveRule = RecursiveRule(stubFor: Behaviour(.structural(token: self), cardinality: Cardinality.one), with: [:])
                    T.leftHandRecursiveRules[self.rawValue] = recursiveRule
                    // Create the rule we would normally generate
                    let rule = [    "(",    T.whitespace.rule.require(.zeroOrMore),    T.expression.rule,    T.whitespace.rule.require(.zeroOrMore),    ")".annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string("Expected \')\'")])].sequence.reference(.structural(token: self))
                                        
                    recursiveRule.surrogateRule = rule
                    return recursiveRule
                }
                
                return cachedRule
            
            /// identifier
            case .identifier:
                return T.regularExpression("^[:alpha:]\\w*|_\\w*").reference(.structural(token: self))
                            
            /// element
            case .element:
                guard let cachedRule = T.leftHandRecursiveRules[self.rawValue] else {
                    // Create recursive shell
                    let recursiveRule = RecursiveRule(stubFor: Behaviour(.structural(token: self), cardinality: Cardinality.one), with: [:])
                    T.leftHandRecursiveRules[self.rawValue] = recursiveRule
                    // Create the rule we would normally generate
                    let rule = [    T.annotations.rule.require(.zeroOrOne),    [        T.lookahead.rule,        T.transient.rule,        T.void.rule].choice.require(.zeroOrOne),    T.negated.rule.require(.zeroOrOne),    [        T.group.rule,        T.terminal.rule,        [            T.identifier.rule,            [                T.ows.rule,                "="].sequence.lookahead().negate()].sequence].choice,    T.quantifier.rule.require(.zeroOrOne)].sequence.reference(.structural(token: self))
                                        
                    recursiveRule.surrogateRule = rule
                    return recursiveRule
                }
                
                return cachedRule
            
            /// assignmentOperators
            case .assignmentOperators:
                return [    "=",    "+=",    "|="].choice.reference(.structural(token: self))
                            
            /// or
            case .or:
                return [    T.whitespace.rule.require(.zeroOrMore),    "|",    T.whitespace.rule.require(.zeroOrMore)].sequence.reference(.skipping)
                            
            /// then
            case .then:
                return [    [        T.whitespace.rule.require(.zeroOrMore),        "+",        T.whitespace.rule.require(.zeroOrMore)].sequence,    T.whitespace.rule.require(.oneOrMore)].choice.reference(.skipping)
                            
            /// choice
            case .choice:
                guard let cachedRule = T.leftHandRecursiveRules[self.rawValue] else {
                    // Create recursive shell
                    let recursiveRule = RecursiveRule(stubFor: Behaviour(.structural(token: self), cardinality: Cardinality.one), with: [:])
                    T.leftHandRecursiveRules[self.rawValue] = recursiveRule
                    // Create the rule we would normally generate
                    let rule = [    T.element.rule,    [        T.or.rule,        T.element.rule.annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string("Expected terminal, identifier, or group")])].sequence.require(.oneOrMore)].sequence.reference(.structural(token: self))
                                        
                    recursiveRule.surrogateRule = rule
                    return recursiveRule
                }
                
                return cachedRule
            
            /// notNewRule
            case .notNewRule:
                return [    T.annotations.rule.require(.zeroOrOne),    T.identifier.rule,    T.whitespace.rule.require(.zeroOrMore),    [        ":",        T.whitespace.rule.require(.zeroOrMore),        CharacterSet.letters.require(.oneOrMore),        T.whitespace.rule.require(.zeroOrMore)].sequence.require(.zeroOrOne),    T.assignmentOperators.rule].sequence.negate().reference(.skipping)
                            
            /// sequence
            case .sequence:
                guard let cachedRule = T.leftHandRecursiveRules[self.rawValue] else {
                    // Create recursive shell
                    let recursiveRule = RecursiveRule(stubFor: Behaviour(.structural(token: self), cardinality: Cardinality.one), with: [:])
                    T.leftHandRecursiveRules[self.rawValue] = recursiveRule
                    // Create the rule we would normally generate
                    let rule = [    T.element.rule,    [        T.then.rule,        T.notNewRule.rule.lookahead(),        T.element.rule.annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string("Expected terminal, identifier, or group")])].sequence.require(.oneOrMore)].sequence.reference(.structural(token: self))
                                        
                    recursiveRule.surrogateRule = rule
                    return recursiveRule
                }
                
                return cachedRule
            
            /// expression
            case .expression:
                guard let cachedRule = T.leftHandRecursiveRules[self.rawValue] else {
                    // Create recursive shell
                    let recursiveRule = RecursiveRule(stubFor: Behaviour(.structural(token: self), cardinality: Cardinality.one), with: [:])
                    T.leftHandRecursiveRules[self.rawValue] = recursiveRule
                    // Create the rule we would normally generate
                    let rule = [    T.choice.rule,    T.sequence.rule,    T.element.rule].choice.reference(.structural(token: self))
                                        
                    recursiveRule.surrogateRule = rule
                    return recursiveRule
                }
                
                return cachedRule
            
            /// tokenType
            case .tokenType:
                return [    T.standardType.rule,    T.customType.rule].choice.reference(.structural(token: self))
                            
            /// standardType
            case .standardType:
                return [    "Int",    "Double",    "String",    "Bool"].choice.reference(.structural(token: self))
                            
            /// customType
            case .customType:
                return [    [        "_",        CharacterSet.uppercaseLetters].choice,    [        "_",        CharacterSet.letters,        CharacterSet.decimalDigits].choice.require(.zeroOrMore)].sequence.reference(.structural(token: self))
                            
            /// lhs
            case .lhs:
                return [    T.whitespace.rule.require(.zeroOrMore),    T.annotations.rule.require(.zeroOrOne),    T.transient.rule.require(.zeroOrOne),    T.void.rule.require(.zeroOrOne),    T.identifier.rule,    T.whitespace.rule.require(.zeroOrMore),    [        -":",        -T.whitespace.rule.require(.zeroOrMore),        T.tokenType.rule,        -T.whitespace.rule.require(.zeroOrMore)].sequence.require(.zeroOrOne),    T.assignmentOperators.rule].sequence.reference(.scanning)
                            
            /// rule
            case .rule:
                return [    T.lhs.rule,    T.whitespace.rule.require(.zeroOrMore),    T.expression.rule.annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string("Expected expression")]),    T.whitespace.rule.require(.zeroOrMore)].sequence.reference(.structural(token: self))
                            
            /// moduleName
            case .moduleName:
                return [    [        CharacterSet.letters,        "_"].choice,    [        CharacterSet.letters,        "_",        CharacterSet.decimalDigits].choice.require(.zeroOrMore)].sequence.reference(.structural(token: self))
                            
            /// moduleImport
            case .moduleImport:
                return [    T.ows.rule,    -"import",    -CharacterSet.whitespaces.require(.oneOrMore).annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string("Expected white space followed by module name")]),    T.moduleName.rule.annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string("Expected module name")]),    -T.whitespace.rule.require(.oneOrMore).annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string("Expected newline")])].sequence.reference(.structural(token: self))
                            
            /// scopeName
            case .scopeName:
                return [    -"grammar",    -T.whitespace.rule,    T.ows.rule,    ~[        CharacterSet.letters,        [            CharacterSet.letters,            CharacterSet.decimalDigits].choice.require(.zeroOrMore)].sequence,    -T.whitespace.rule.annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string("Unexpected input")]),    -T.ows.rule].sequence.reference(.structural(token: self))
                            
            /// grammar
            case .grammar:
                return [    -T.whitespace.rule.require(.zeroOrMore),    T.scopeName.rule.annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string("You must declare the name of the grammar before any other declarations (e.g. grammar <your-grammar-name>)")]),    T.modules.rule.require(.zeroOrOne).annotatedWith([:]),    T.rules.rule.annotatedWith([:])].sequence.reference(.structural(token: self))
                            
            /// modules
            case .modules:
                return T.moduleImport.rule.require(.oneOrMore).reference(.structural(token: self), annotations: [:])
                            
            /// rules
            case .rules:
                return T.rule.rule.require(.oneOrMore).annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string("Expected at least one rule")]).reference(.structural(token: self), annotations: [:])
                            
        }
    }
    
    /// Cache for left-hand recursive rules
    private static var leftHandRecursiveRules = [ Int : Rule ]()
    
    /// Create a language that can be used for parsing etc
    public static var generatedRules: [Rule] {
        return [T.grammar.rule]
    }
}

public struct STLR : Codable {
    
    // Quantifier
    public enum Quantifier : Swift.String, Codable, CaseIterable {
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
    public enum CharacterSetName : Swift.String, Codable, CaseIterable {
        case letter,uppercaseLetter,lowercaseLetter,alphaNumeric,decimalDigit,whitespaceOrNewline,whitespace,newline,backslash
    }
    
    /// CharacterSet 
    public struct CharacterSet : Codable {
        public let characterSetName: CharacterSetName
    }
    
    public typealias CharacterRange = [TerminalString] 
    
    // Boolean
    public enum Boolean : Swift.String, Codable, CaseIterable {
        case `true` = "true",`false` = "false"
    }
    
    // Literal
    public enum Literal : Codable {
        case number(number:Int)
        case boolean(boolean:Boolean)
        case string(string:String)
        
        enum CodingKeys : Swift.String, CodingKey {
            case number,boolean,string
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            if let number = try? container.decode(Int.self, forKey: .number){
            	self = .number(number: number)
            	return
            } else if let boolean = try? container.decode(Boolean.self, forKey: .boolean){
            	self = .boolean(boolean: boolean)
            	return
            } else if let string = try? container.decode(String.self, forKey: .string){
            	self = .string(string: string)
            	return
            }
            throw DecodingError.valueNotFound(Expression.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Tried to decode one of Int,Boolean,String but found none of those types"))
        }
        public func encode(to encoder:Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .number(let number):
                try container.encode(number, forKey: .number)
            case .boolean(let boolean):
                try container.encode(boolean, forKey: .boolean)
            case .string(let string):
                try container.encode(string, forKey: .string)
            }
        }
    }
    
    /// Annotation 
    public struct Annotation : Codable {
        public let label: Label
        public let literal: Literal?
    }
    
    public typealias Annotations = [Annotation] 
    
    // DefinedLabel
    public enum DefinedLabel : Swift.String, Codable, CaseIterable {
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
        
        /// Default initializer
        public init(expression:Expression){
            self.expression = expression
                        
        }
    
    }
    
    /// Element 
    public class Element : Codable {
        public let identifier: Swift.String?
        public let transient: Swift.String?
        public let terminal: Terminal?
        public let quantifier: Quantifier?
        public let lookahead: Swift.String?
        public let group: Group?
        public let void: Swift.String?
        public let annotations: Annotations?
        public let negated: Swift.String?
        
        /// Default initializer
        public init(annotations:Annotations?, group:Group?, identifier:Swift.String?, lookahead:Swift.String?, negated:Swift.String?, quantifier:Quantifier?, terminal:Terminal?, transient:Swift.String?, void:Swift.String?){
            self.annotations = annotations
            self.group = group
            self.identifier = identifier
            self.lookahead = lookahead
            self.negated = negated
            self.quantifier = quantifier
            self.terminal = terminal
            self.transient = transient
            self.void = void
                        
        }
    
    }
    
    // AssignmentOperators
    public enum AssignmentOperators : Swift.String, Codable, CaseIterable {
        case equals = "=",plusEquals = "+=",pipeEquals = "|="
    }
    
    public typealias Choice = [Element] 
    
    public typealias Sequence = [Element] 
    
    // Expression
    public enum Expression : Codable {
        case choice(choice:Choice)
        case sequence(sequence:Sequence)
        case element(element:Element)
        
        enum CodingKeys : Swift.String, CodingKey {
            case choice,sequence,element
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            if let choice = try? container.decode(Choice.self, forKey: .choice){
            	self = .choice(choice: choice)
            	return
            } else if let sequence = try? container.decode(Sequence.self, forKey: .sequence){
            	self = .sequence(sequence: sequence)
            	return
            } else if let element = try? container.decode(Element.self, forKey: .element){
            	self = .element(element: element)
            	return
            }
            throw DecodingError.valueNotFound(Expression.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Tried to decode one of Choice,Sequence,Element but found none of those types"))
        }
        public func encode(to encoder:Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .choice(let choice):
                try container.encode(choice, forKey: .choice)
            case .sequence(let sequence):
                try container.encode(sequence, forKey: .sequence)
            case .element(let element):
                try container.encode(element, forKey: .element)
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
    public enum StandardType : Swift.String, Codable, CaseIterable {
        case int = "Int",double = "Double",string = "String",bool = "Bool"
    }
    
    /// Rule 
    public struct Rule : Codable {
        public let identifier: Swift.String
        public let tokenType: TokenType?
        public let expression: Expression
        public let transient: Swift.String?
        public let assignmentOperators: AssignmentOperators
        public let void: Swift.String?
        public let annotations: Annotations?
    }
    
    /// ModuleImport 
    public struct ModuleImport : Codable {
        public let moduleName: Swift.String
    }
    
    /// Grammar 
    public struct Grammar : Codable {
        public let scopeName: Swift.String
        public let rules: Rules
        public let modules: Modules?
    }
    
    public typealias Modules = [ModuleImport] 
    
    public typealias Rules = [Rule] 
    public let grammar : Grammar
    /**
     Parses the supplied string using the generated grammar into a new instance of
     the generated data structure
    
     - Parameter source: The string to parse
     - Returns: A new instance of the data-structure
     */
    public static func build(_ source : Swift.String) throws ->STLR{
        let root = HomogenousTree(with: LabelledToken(withLabel: "root"), matching: source, children: [try AbstractSyntaxTreeConstructor().build(source, using: STLR.generatedLanguage)])
        // print(root.description)
        return try ParsingDecoder().decode(STLR.self, using: root)
    }
    
    public static var generatedLanguage : Language {return Parser(grammar:STLRTokens.generatedRules)}
}
