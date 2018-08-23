import Foundation
import OysterKit

/// Intermediate Representation of the grammar
internal enum STLRTokens : Int, Token, CaseIterable, Equatable {
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
    case `whitespace`, `ows`, `quantifier`, `negated`, `lookahead`, `transient`, `void`, `stringQuote`, `terminalBody`, `stringBody`, `string`, `terminalString`, `characterSetName`, `characterSet`, `rangeOperator`, `characterRange`, `number`, `boolean`, `literal`, `annotation`, `annotations`, `customLabel`, `definedLabel`, `label`, `regexDelimeter`, `startRegex`, `endRegex`, `regexBody`, `regex`, `terminal`, `group`, `identifier`, `element`, `assignmentOperators`, `or`, `then`, `choice`, `notNewRule`, `sequence`, `expression`, `tokenType`, `standardType`, `customType`, `lhs`, `rule`, `moduleName`, `moduleImport`, `scopeName`, `grammar`, `import`, `modules`, `rules`
    
    /// The rule for the token
    var rule : BehaviouralRule {
        switch self {
            /// whitespace
            case .whitespace:
                return T.regularExpression("^[:space:]+|/\\*(?:.|\\r?\\n)*?\\*/|//.*(?:\\r?\\n|$)").require(.one).skip()
                            
            /// ows
            case .ows:
                return T.whitespace.rule.require(.noneOrMore).skip()
                            
            /// quantifier
            case .quantifier:
                return [    "*".require(.one),    "+".require(.one),    "?".require(.one),    "-".require(.one)].choice.parse(as:self)
                            
            /// negated
            case .negated:
                return "!".require(.one).parse(as:self)
                            
            /// lookahead
            case .lookahead:
                return ">>".require(.one).parse(as:self)
                            
            /// transient
            case .transient:
                return "~".require(.one).parse(as:self)
                            
            /// void
            case .void:
                return "-".require(.one).parse(as:self)
                            
            /// stringQuote
            case .stringQuote:
                return "\"".require(.one).parse(as:self)
                            
            /// terminalBody
            case .terminalBody:
                return T.regularExpression("^(\\\\.|[^\"\\\\\\n])+").require(.one).parse(as:self)
                            
            /// stringBody
            case .stringBody:
                return T.regularExpression("^(\\\\.|[^\"\\\\\\n])*").require(.one).parse(as:self)
                            
            /// string
            case .string:
                return [    -T.stringQuote.rule.require(.one),    T.stringBody.rule.require(.one),    -T.stringQuote.rule.require(.one).annotatedWith(T.stringQuote.rule.annotations.merge(with:[RuleAnnotation.error:RuleAnnotationValue.string("Missing terminating quote")]))].sequence.parse(as:self)
                            
            /// terminalString
            case .terminalString:
                return [    -T.stringQuote.rule.require(.one),    T.terminalBody.rule.require(.one).annotatedWith(T.terminalBody.rule.annotations.merge(with:[RuleAnnotation.error:RuleAnnotationValue.string("Terminals must have at least one character")])),    -T.stringQuote.rule.require(.one).annotatedWith(T.stringQuote.rule.annotations.merge(with:[RuleAnnotation.error:RuleAnnotationValue.string("Missing terminating quote")]))].sequence.parse(as:self)
                            
            /// characterSetName
            case .characterSetName:
                return [    "letter".require(.one),    "uppercaseLetter".require(.one),    "lowercaseLetter".require(.one),    "alphaNumeric".require(.one),    "decimalDigit".require(.one),    "whitespaceOrNewline".require(.one),    "whitespace".require(.one),    "newline".require(.one),    "backslash".require(.one)].choice.parse(as:self)
                            
            /// characterSet
            case .characterSet:
                return [    ".".require(.one),    T.characterSetName.rule.require(.one).annotatedWith(T.characterSetName.rule.annotations.merge(with:[RuleAnnotation.error:RuleAnnotationValue.string("Unknown character set")]))].sequence.parse(as:self)
                            
            /// rangeOperator
            case .rangeOperator:
                return [    "..".require(.one),    ".".require(.one).annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string("Expected ... in character range")])].sequence.skip()
                            
            /// characterRange
            case .characterRange:
                return [    T.terminalString.rule.require(.one),    T.rangeOperator.rule.require(.one),    T.terminalString.rule.require(.one).annotatedWith(T.terminalString.rule.annotations.merge(with:[RuleAnnotation.error:RuleAnnotationValue.string("Range must be terminated")]))].sequence.parse(as:self)
                            
            /// number
            case .number:
                return [    [        "-".require(.one),        "+".require(.one)].choice    ,    CharacterSet.decimalDigits.require(.oneOrMore)].sequence.parse(as:self)
                            
            /// boolean
            case .boolean:
                return [    "true".require(.one),    "false".require(.one)].choice.parse(as:self)
                            
            /// literal
            case .literal:
                return [    T.string.rule.require(.one),    T.number.rule.require(.one),    T.boolean.rule.require(.one)].choice.parse(as:self)
                            
            /// annotation
            case .annotation:
                return [    "@".require(.one),    T.label.rule.require(.one).annotatedWith(T.label.rule.annotations.merge(with:[RuleAnnotation.error:RuleAnnotationValue.string("Expected an annotation label")])),    [        "(".require(.one),        T.literal.rule.require(.one).annotatedWith(T.literal.rule.annotations.merge(with:[RuleAnnotation.error:RuleAnnotationValue.string("A value must be specified or the () omitted")])),        ")".require(.one).annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string("Missing \')\'")])].sequence    ].sequence.parse(as:self)
                            
            /// annotations
            case .annotations:
                return [    T.annotation.rule.require(.one),    T.ows.rule.require(.one)].sequence.parse(as:self)
                            
            /// customLabel
            case .customLabel:
                return [    [        CharacterSet.letters.require(.one),        "_".require(.one)].choice.annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string("Labels must start with a letter or _")])    ,    [        CharacterSet.letters.require(.one),        CharacterSet.decimalDigits.require(.one),        "_".require(.one)].choice    ].sequence.parse(as:self)
                            
            /// definedLabel
            case .definedLabel:
                return [    "token".require(.one),    "error".require(.one),    "void".require(.one),    "transient".require(.one)].choice.parse(as:self)
                            
            /// label
            case .label:
                return [    T.definedLabel.rule.require(.one),    T.customLabel.rule.require(.one)].choice.parse(as:self)
                            
            /// regexDelimeter
            case .regexDelimeter:
                return "/".require(.one).skip()
                            
            /// startRegex
            case .startRegex:
                return [    T.regexDelimeter.rule.require(.one),    "*".require(.one).lookahead().negate(),    "/".require(.one).lookahead().negate()].sequence.skip()
                            
            /// endRegex
            case .endRegex:
                return T.regexDelimeter.rule.require(.one).skip()
                            
            /// regexBody
            case .regexBody:
                return [    T.regexDelimeter.rule.require(.one),    T.whitespace.rule.require(.one)].sequence.scan()
                            
            /// regex
            case .regex:
                return [    T.startRegex.rule.require(.one),    T.regexBody.rule.require(.one),    T.endRegex.rule.require(.one)].sequence.parse(as:self)
                            
            /// terminal
            case .terminal:
                return [    T.characterSet.rule.require(.one),    T.characterRange.rule.require(.one),    T.terminalString.rule.require(.one),    T.regex.rule.require(.one)].choice.parse(as:self)
                            
            /// group
            case .group:
                guard let cachedRule = T.leftHandRecursiveRules[self.rawValue] else {
                    // Create recursive shell
                    let recursiveRule = BehaviouralRecursiveRule(stubFor: Behaviour(.structural(token: self), cardinality: Cardinality.one), with: [:])
                    T.leftHandRecursiveRules[self.rawValue] = recursiveRule
                    // Create the rule we would normally generate
                    let rule = [    "(".require(.one),    T.whitespace.rule.require(.noneOrMore),    T.expression.rule.require(.one),    T.whitespace.rule.require(.noneOrMore),    ")".require(.one).annotatedWith([RuleAnnotation.error:RuleAnnotationValue.string("Expected \')\'")])].sequence.parse(as:self)
                                        
                    recursiveRule.surrogateRule = rule
                    return recursiveRule
                }
                
                return cachedRule
            
            /// identifier
            case .identifier:
                return T.regularExpression("^[:alpha:]\\w*|_\\w*").require(.one).parse(as:self)
                            
            /// element
            case .element:
                guard let cachedRule = T.leftHandRecursiveRules[self.rawValue] else {
                    // Create recursive shell
                    let recursiveRule = BehaviouralRecursiveRule(stubFor: Behaviour(.structural(token: self), cardinality: Cardinality.one), with: [:])
                    T.leftHandRecursiveRules[self.rawValue] = recursiveRule
                    // Create the rule we would normally generate
                    let rule = [    T.annotations.rule.require(.optionally),    [        T.lookahead.rule.require(.one),        T.transient.rule.require(.one),        T.void.rule.require(.one)].choice    ,    T.negated.rule.require(.optionally),    [        T.group.rule.require(.one),        T.terminal.rule.require(.one),        [            T.identifier.rule.require(.one),            [                T.ows.rule.require(.one),                "=".require(.one)].sequence            ].sequence        ].choice    ,    T.quantifier.rule.require(.optionally)].sequence.parse(as:self)
                                        
                    recursiveRule.surrogateRule = rule
                    return recursiveRule
                }
                
                return cachedRule
            
            /// assignmentOperators
            case .assignmentOperators:
                return [    "=".require(.one),    "+=".require(.one),    "|=".require(.one)].choice.parse(as:self)
                            
            /// or
            case .or:
                return [    T.whitespace.rule.require(.noneOrMore),    "|".require(.one),    T.whitespace.rule.require(.noneOrMore)].sequence.skip()
                            
            /// then
            case .then:
                return [    [        T.whitespace.rule.require(.noneOrMore),        "+".require(.one),        T.whitespace.rule.require(.noneOrMore)].sequence    ,    T.whitespace.rule.require(.oneOrMore)].choice.skip()
                            
            /// choice
            case .choice:
                guard let cachedRule = T.leftHandRecursiveRules[self.rawValue] else {
                    // Create recursive shell
                    let recursiveRule = BehaviouralRecursiveRule(stubFor: Behaviour(.structural(token: self), cardinality: Cardinality.one), with: [:])
                    T.leftHandRecursiveRules[self.rawValue] = recursiveRule
                    // Create the rule we would normally generate
                    let rule = [    T.element.rule.require(.one),    [        T.or.rule.require(.one),        T.element.rule.require(.one).annotatedWith(T.element.rule.annotations.merge(with:[RuleAnnotation.error:RuleAnnotationValue.string("Expected terminal, identifier, or group")]))].sequence    ].sequence.parse(as:self)
                                        
                    recursiveRule.surrogateRule = rule
                    return recursiveRule
                }
                
                return cachedRule
            
            /// notNewRule
            case .notNewRule:
                return [    T.annotations.rule.require(.optionally),    T.identifier.rule.require(.one),    T.whitespace.rule.require(.noneOrMore),    [        ":".require(.one),        T.whitespace.rule.require(.noneOrMore),        CharacterSet.letters.require(.oneOrMore),        T.whitespace.rule.require(.noneOrMore)].sequence    ,    T.assignmentOperators.rule.require(.one)].sequence.parse(as:self)
                            
            /// sequence
            case .sequence:
                guard let cachedRule = T.leftHandRecursiveRules[self.rawValue] else {
                    // Create recursive shell
                    let recursiveRule = BehaviouralRecursiveRule(stubFor: Behaviour(.structural(token: self), cardinality: Cardinality.one), with: [:])
                    T.leftHandRecursiveRules[self.rawValue] = recursiveRule
                    // Create the rule we would normally generate
                    let rule = [    T.element.rule.require(.one),    [        T.then.rule.require(.one),        T.notNewRule.rule.require(.one).lookahead(),        T.element.rule.require(.one).annotatedWith(T.element.rule.annotations.merge(with:[RuleAnnotation.error:RuleAnnotationValue.string("Expected terminal, identifier, or group")]))].sequence    ].sequence.parse(as:self)
                                        
                    recursiveRule.surrogateRule = rule
                    return recursiveRule
                }
                
                return cachedRule
            
            /// expression
            case .expression:
                guard let cachedRule = T.leftHandRecursiveRules[self.rawValue] else {
                    // Create recursive shell
                    let recursiveRule = BehaviouralRecursiveRule(stubFor: Behaviour(.structural(token: self), cardinality: Cardinality.one), with: [:])
                    T.leftHandRecursiveRules[self.rawValue] = recursiveRule
                    // Create the rule we would normally generate
                    let rule = [    T.choice.rule.require(.one),    T.sequence.rule.require(.one),    T.element.rule.require(.one)].choice.parse(as:self)
                                        
                    recursiveRule.surrogateRule = rule
                    return recursiveRule
                }
                
                return cachedRule
            
            /// tokenType
            case .tokenType:
                return [    T.standardType.rule.require(.one),    T.customType.rule.require(.one)].choice.parse(as:self)
                            
            /// standardType
            case .standardType:
                return [    "Int".require(.one),    "Double".require(.one),    "String".require(.one),    "Bool".require(.one)].choice.parse(as:self)
                            
            /// customType
            case .customType:
                return [    [        "_".require(.one),        CharacterSet.uppercaseLetters.require(.one)].choice    ,    [        "_".require(.one),        CharacterSet.letters.require(.one),        CharacterSet.decimalDigits.require(.one)].choice    ].sequence.parse(as:self)
                            
            /// lhs
            case .lhs:
                return [    T.whitespace.rule.require(.noneOrMore),    T.annotations.rule.require(.optionally),    T.transient.rule.require(.optionally),    T.void.rule.require(.optionally),    T.identifier.rule.require(.one),    T.whitespace.rule.require(.noneOrMore),    [        -":".require(.one),        -T.whitespace.rule.require(.noneOrMore),        T.tokenType.rule.require(.one),        -T.whitespace.rule.require(.noneOrMore)].sequence    ,    T.assignmentOperators.rule.require(.one)].sequence.scan()
                            
            /// rule
            case .rule:
                return [    T.lhs.rule.require(.one),    T.whitespace.rule.require(.noneOrMore),    T.expression.rule.require(.one).annotatedWith(T.expression.rule.annotations.merge(with:[RuleAnnotation.error:RuleAnnotationValue.string("Expected expression")])),    T.whitespace.rule.require(.noneOrMore)].sequence.parse(as:self)
                            
            /// moduleName
            case .moduleName:
                return [    [        CharacterSet.letters.require(.one),        "_".require(.one)].choice    ,    [        CharacterSet.letters.require(.one),        "_".require(.one),        CharacterSet.decimalDigits.require(.one)].choice    ].sequence.parse(as:self)
                            
            /// moduleImport
            case .moduleImport:
                return [    T.whitespace.rule.require(.noneOrMore),    T.import.rule.require(.one).annotatedWith(T.import.rule.annotations.merge(with:[:])),    CharacterSet.whitespaces.require(.oneOrMore),    T.moduleName.rule.require(.one),    T.whitespace.rule.require(.oneOrMore)].sequence.parse(as:self)
                            
            /// scopeName
            case .scopeName:
                return [    -"grammar".require(.one),    -T.whitespace.rule.require(.one),    T.ows.rule.require(.one),    [        CharacterSet.letters.require(.one),        [            CharacterSet.letters.require(.one),            CharacterSet.decimalDigits.require(.one)].choice        ].sequence    ,    -T.whitespace.rule.require(.one),    -T.ows.rule.require(.one)].sequence.parse(as:self)
                            
            /// grammar
            case .grammar:
                return [    -T.whitespace.rule.require(.noneOrMore),    T.scopeName.rule.require(.one).annotatedWith(T.scopeName.rule.annotations.merge(with:[RuleAnnotation.error:RuleAnnotationValue.string("You must declare the name of the grammar before any other declarations (e.g. grammar <your-grammar-name>)")])),    T.modules.rule.require(.optionally).annotatedWith(T.modules.rule.annotations.merge(with:[:])),    T.rules.rule.require(.one).annotatedWith(T.rules.rule.annotations.merge(with:[:]))].sequence.parse(as:self)
                            
            /// import
            case .import:
                return "import".require(.one).annotatedWith([:]).parse(as:self)
                            
            /// modules
            case .modules:
                return T.moduleImport.rule.require(.oneOrMore).parse(as:self)
                            
            /// rules
            case .rules:
                return T.rule.rule.require(.oneOrMore).annotatedWith(T.rule.rule.annotations.merge(with:[RuleAnnotation.error:RuleAnnotationValue.string("Expected at least one rule")])).parse(as:self)
                            
        }
    }
    
    /// Cache for left-hand recursive rules
    private static var leftHandRecursiveRules = [ Int : BehaviouralRule ]()
    
    /// Create a language that can be used for parsing etc
    public static var generatedRules: [BehaviouralRule] {
        return [T.grammar.rule]
    }
}

public struct STLR : Codable {
    
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
        case number(number:Int)
        case string(string:String)
        case boolean(boolean:Boolean)
        
        enum CodingKeys : Swift.String, CodingKey {
            case number,string,boolean
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            if let number = try? container.decode(Int.self, forKey: .number){
            	self = .number(number: number)
            	return
            } else if let string = try? container.decode(String.self, forKey: .string){
            	self = .string(string: string)
            	return
            } else if let boolean = try? container.decode(Boolean.self, forKey: .boolean){
            	self = .boolean(boolean: boolean)
            	return
            }
            throw DecodingError.valueNotFound(Expression.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Tried to decode one of Int,String,Boolean but found none of those types"))
        }
        public func encode(to encoder:Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .number(let number):
                try container.encode(number, forKey: .number)
            case .string(let string):
                try container.encode(string, forKey: .string)
            case .boolean(let boolean):
                try container.encode(boolean, forKey: .boolean)
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
        case regex(regex:Swift.String)
        case characterSet(characterSet:CharacterSet)
        case characterRange(characterRange:CharacterRange)
        case terminalString(terminalString:TerminalString)
        
        enum CodingKeys : Swift.String, CodingKey {
            case regex,characterSet,characterRange,terminalString
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            if let regex = try? container.decode(Swift.String.self, forKey: .regex){
            	self = .regex(regex: regex)
            	return
            } else if let characterSet = try? container.decode(CharacterSet.self, forKey: .characterSet){
            	self = .characterSet(characterSet: characterSet)
            	return
            } else if let characterRange = try? container.decode(CharacterRange.self, forKey: .characterRange){
            	self = .characterRange(characterRange: characterRange)
            	return
            } else if let terminalString = try? container.decode(TerminalString.self, forKey: .terminalString){
            	self = .terminalString(terminalString: terminalString)
            	return
            }
            throw DecodingError.valueNotFound(Expression.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Tried to decode one of Swift.String,CharacterSet,CharacterRange,TerminalString but found none of those types"))
        }
        public func encode(to encoder:Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .regex(let regex):
                try container.encode(regex, forKey: .regex)
            case .characterSet(let characterSet):
                try container.encode(characterSet, forKey: .characterSet)
            case .characterRange(let characterRange):
                try container.encode(characterRange, forKey: .characterRange)
            case .terminalString(let terminalString):
                try container.encode(terminalString, forKey: .terminalString)
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
        public let transient: Swift.String?
        public let identifier: Swift.String?
        public let negated: Swift.String?
        public let quantifier: Quantifier?
        public let terminal: Terminal?
        public let group: Group?
        public let lookahead: Swift.String?
        public let void: Swift.String?
        public let annotations: Annotations?
        
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
        public let transient: Swift.String?
        public let assignmentOperators: AssignmentOperators
        public let expression: Expression
        public let tokenType: TokenType?
        public let identifier: Swift.String
        public let void: Swift.String?
        public let annotations: Annotations?
    }
    
    /// ModuleImport 
    public struct ModuleImport : Codable {
        public let `import`: Swift.String
        public let moduleName: Swift.String
    }
    
    /// Grammar 
    public struct Grammar : Codable {
        public let modules: Modules?
        public let rules: Rules
        public let scopeName: Swift.String
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
