import Foundation
import OysterKit

enum IRTokens : Int, Token {
    
    // Convenience alias
    private typealias T = IRTokens
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
    
    case _transient = -1, `whitespace`, `ows`, `quantifier`, `negated`, `transient`, `void`, `lookahead`, `stringQuote`, `terminalBody`, `stringBody`, `string`, `terminalString`, `characterSetName`, `characterSet`, `rangeOperator`, `characterRange`, `number`, `boolean`, `literal`, `annotation`, `annotations`, `customLabel`, `definedLabel`, `label`, `regexDelimeter`, `startRegex`, `endRegex`, `regexBody`, `regex`, `terminal`, `group`, `identifier`, `element`, `assignmentOperators`, `or`, `then`, `choice`, `notNewRule`, `sequence`, `expression`, `lhs`, `rule`, `moduleName`, `import`, `moduleImport`, `mark`, `grammar`
    
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
            return ScannerRule.oneOf(token: T.quantifier, ["*", "+", "?", "-"],[ : ].merge(with: annotations))
        // negated
        case .negated:
            return "!".terminal(token: T.negated, annotations: annotations)
        // transient
        case .transient:
            return "~".terminal(token: T.transient, annotations: annotations)
        // void
        case .void:
            return "-".terminal(token: T.void, annotations: annotations)
        // lookahead
        case .lookahead:
            return ">>".terminal(token: T.lookahead, annotations: annotations)
        // stringQuote
        case .stringQuote:
            return "\"".terminal(token: T.stringQuote, annotations: annotations)
        // terminalBody
        case .terminalBody:
            return ScannerRule.regularExpression(token: T.terminalBody, regularExpression: T.regularExpression("^(\\\\.|[^\"\\\\\\n])+"), annotations: annotations)
        // stringBody
        case .stringBody:
            return ScannerRule.regularExpression(token: T.stringBody, regularExpression: T.regularExpression("^(\\\\.|[^\"\\\\\\n])*"), annotations: annotations)
        // string
        case .string:
            return [
                T.stringQuote._rule([RuleAnnotation.void : RuleAnnotationValue.set]),
                T.stringBody._rule(),
                T.stringQuote._rule([RuleAnnotation.error : RuleAnnotationValue.string("Missing terminating quote"),RuleAnnotation.void : RuleAnnotationValue.set]),
                ].sequence(token: T.string, annotations: annotations.isEmpty ? [ : ] : annotations)
        // terminalString
        case .terminalString:
            return [
                T.stringQuote._rule([RuleAnnotation.void : RuleAnnotationValue.set]),
                T.terminalBody._rule([RuleAnnotation.error : RuleAnnotationValue.string("Terminals must have at least one character")]),
                T.stringQuote._rule([RuleAnnotation.error : RuleAnnotationValue.string("Missing terminating quote"),RuleAnnotation.void : RuleAnnotationValue.set]),
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
                ScannerRule.oneOf(token: T._transient, ["-", "+"],[:].merge(with: annotations)).optional(producing: T._transient),
                CharacterSet.decimalDigits.terminal(token: T._transient).repeated(min: 1, producing: T._transient),
                ].sequence(token: T.number, annotations: annotations.isEmpty ? [ : ] : annotations)
        // boolean
        case .boolean:
            return ScannerRule.oneOf(token: T.boolean, ["true", "false"],[ : ].merge(with: annotations))
        // literal
        case .literal:
            return [
                T.string._rule(),
                T.number._rule(),
                T.boolean._rule(),
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
                [
                    CharacterSet.letters.terminal(token: T._transient),
                    "_".terminal(token: T._transient),
                    ].oneOf(token: T._transient, annotations: annotations.isEmpty ? [RuleAnnotation.error : RuleAnnotationValue.string("Labels must start with a letter or _")] : annotations),
                [
                    CharacterSet.letters.terminal(token: T._transient),
                    CharacterSet.decimalDigits.terminal(token: T._transient),
                    "_".terminal(token: T._transient),
                    ].oneOf(token: T._transient).repeated(min: 0, producing: T._transient),
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
                T.regexDelimeter._rule([RuleAnnotation.void : RuleAnnotationValue.set]),
                "*".terminal(token: T._transient).not(producing: T._transient).lookahead(),
                "/".terminal(token: T._transient).not(producing: T._transient).lookahead(),
                ].sequence(token: T.startRegex, annotations: annotations.isEmpty ? [RuleAnnotation.void : RuleAnnotationValue.set] : annotations)
        // endRegex
        case .endRegex:
            return [T.regexDelimeter._rule([RuleAnnotation.void : RuleAnnotationValue.set])].sequence(token: self)
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
            guard let cachedRule = IRTokens.leftHandRecursiveRules[self.rawValue] else {
                // Create recursive shell
                let recursiveRule = RecursiveRule(stubFor: self, with: annotations.isEmpty ? [ : ] : annotations)
                IRTokens.leftHandRecursiveRules[self.rawValue] = recursiveRule
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
            guard let cachedRule = IRTokens.leftHandRecursiveRules[self.rawValue] else {
                // Create recursive shell
                let recursiveRule = RecursiveRule(stubFor: self, with: annotations.isEmpty ? [ : ] : annotations)
                IRTokens.leftHandRecursiveRules[self.rawValue] = recursiveRule
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
            guard let cachedRule = IRTokens.leftHandRecursiveRules[self.rawValue] else {
                // Create recursive shell
                let recursiveRule = RecursiveRule(stubFor: self, with: annotations.isEmpty ? [ : ] : annotations)
                IRTokens.leftHandRecursiveRules[self.rawValue] = recursiveRule
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
                T.assignmentOperators._rule(),
                ].sequence(token: T._transient, annotations: annotations.isEmpty ? [ : ] : annotations).not(producing: T.notNewRule, annotations: annotations)
        // sequence
        case .sequence:
            guard let cachedRule = IRTokens.leftHandRecursiveRules[self.rawValue] else {
                // Create recursive shell
                let recursiveRule = RecursiveRule(stubFor: self, with: annotations.isEmpty ? [ : ] : annotations)
                IRTokens.leftHandRecursiveRules[self.rawValue] = recursiveRule
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
            guard let cachedRule = IRTokens.leftHandRecursiveRules[self.rawValue] else {
                // Create recursive shell
                let recursiveRule = RecursiveRule(stubFor: self, with: annotations.isEmpty ? [ : ] : annotations)
                IRTokens.leftHandRecursiveRules[self.rawValue] = recursiveRule
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
        // lhs
        case .lhs:
            return [
                T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                T.annotations._rule().optional(producing: T._transient),
                T.transient._rule().optional(producing: T._transient),
                T.void._rule().optional(producing: T._transient),
                T.identifier._rule(),
                T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
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
                [
                    CharacterSet.letters.terminal(token: T._transient),
                    "_".terminal(token: T._transient),
                    ].oneOf(token: T._transient),
                [
                    CharacterSet.letters.terminal(token: T._transient),
                    "_".terminal(token: T._transient),
                    CharacterSet.decimalDigits.terminal(token: T._transient),
                    ].oneOf(token: T._transient).repeated(min: 0, producing: T._transient),
                ].sequence(token: T.moduleName, annotations: annotations.isEmpty ? [ : ] : annotations)
        // import
        case .import:
            return "import".terminal(token: T.import, annotations: annotations)
        // moduleImport
        case .moduleImport:
            return [
                T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
                T.import._rule(),
                CharacterSet.whitespaces.terminal(token: T._transient).repeated(min: 1, producing: T._transient),
                T.moduleName._rule(),
                T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 1, producing: T._transient),
                ].sequence(token: T.moduleImport, annotations: annotations.isEmpty ? [ : ] : annotations)
        // mark
        case .mark:
            return [
                " ".terminal(token: T._transient).not(producing: T._transient),
                " ".terminal(token: T._transient),
                ].oneOf(token: T.mark, annotations: annotations).lookahead()
        // grammar
        case .grammar:
            return [
                T.mark._rule(),
                T.moduleImport._rule().repeated(min: 0, producing: T._transient),
                T.rule._rule().repeated(min: 1, producing: T._transient),
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


/// Intermediate Representation of the grammar
struct IR : Decodable {
    /// String
    struct String : Decodable {
        let stringBody : Swift.String
    }
    /// TerminalString
    struct TerminalString : Decodable {
        let terminalBody : Swift.String
    }
    /// CharacterSet
    struct CharacterSet : Decodable {
        let characterSetName : Swift.String
    }
    /// CharacterRange
    struct CharacterRange : Decodable {
        let terminalString : [TerminalString]
    }
    /// Literal
    struct Literal : Decodable {
        let number : Swift.String?
        let boolean : Swift.String?
        let string : String?
    }
    /// Annotation
    struct Annotation : Decodable {
        let label : Label
        let literal : Literal?
    }
    /// Annotations
    struct Annotations : Decodable {
        let annotation : [Annotation]
    }
    /// Label
    struct Label : Decodable {
        let customLabel : Swift.String?
        let definedLabel : Swift.String?
    }
    /// Terminal
    struct Terminal : Decodable {
        let regex : Swift.String?
        let characterRange : CharacterRange?
        let characterSet : CharacterSet?
        let terminalString : TerminalString?
    }
    /// Group
    class Group : Decodable {
        let expression : Expression
    }
    /// Element
    class Element : Decodable {
        let negated : Swift.String?
        let group : Group?
        let terminal : Terminal?
        let quantifier : Swift.String?
        let transient : Swift.String?
        let identifier : Swift.String?
        let lookahead : Swift.String?
        let annotations : Annotations?
        let void : Swift.String?
    }
    /// Choice
    class Choice : Decodable {
        let element : [Element]
    }
    /// Sequence
    class Sequence : Decodable {
        let element : [Element]
    }
    /// Expression
    class Expression : Decodable {
        let element : Element?
        let choice : Choice?
        let sequence : Sequence?
    }
    /// Rule
    struct Rule : Decodable {
        let expression : Expression
    }
    /// ModuleImport
    struct ModuleImport : Decodable {
        let `import` : Swift.String
        let moduleName : Swift.String
    }
    /// Grammar
    struct Grammar : Decodable {
        let mark : Swift.String
        let moduleImport : [ModuleImport]
        let rule : [Rule]
    }
    /// Structure
    let grammar : Grammar
}