// 
// STLR Generated Swift File
// 
// Generated: 2017-12-07 02:44:18 +0000
// 
import Cocoa

// 
// STLR Parser
//
/// The automatically generated STLR grammar
enum STLR : Int, Token {

	// Convenience alias
	private typealias T = STLR

	case _transient = -1, `singleLineComment`, `multilineComment`, `comment`, `whitespace`, `ows`, `quantifier`, `negated`, `transient`, `lookahead`, `stringQuote`, `escapedCharacter`, `stringCharacter`, `terminalBody`, `stringBody`, `string`, `terminalString`, `characterSetName`, `characterSet`, `rangeOperator`, `characterRange`, `number`, `boolean`, `literal`, `annotation`, `annotations`, `customLabel`, `definedLabel`, `label`, `terminal`, `group`, `identifier`, `element`, `assignmentOperators`, `or`, `then`, `choice`, `notNewRule`, `sequence`, `expression`, `lhs`, `rule`, `moduleName`, `moduleImport`, `mark`, `grammar`

	func _rule(_ annotations: RuleAnnotations = [ : ])->Rule {
		switch self {
		case ._transient:
			return CharacterSet(charactersIn: "").terminal(token: T._transient)
		// singleLineComment
		case .singleLineComment:
			return [
					"//".terminal(token: T._transient),
					CharacterSet.newlines.terminal(token: T._transient).not(producing: T._transient).repeated(min: 0, producing: T._transient),
					CharacterSet.newlines.terminal(token: T._transient),
					].sequence(token: T.singleLineComment, annotations: annotations.isEmpty ? [ : ] : annotations)
		// multilineComment
		case .multilineComment:
			guard let cachedRule = STLR.leftHandRecursiveRules[self.rawValue] else {
				// Create recursive shell
				let recursiveRule = RecursiveRule()
				STLR.leftHandRecursiveRules[self.rawValue] = recursiveRule
				// Create the rule we would normally generate
				let rule = [
					"/*".terminal(token: T._transient),
					[
									T.multilineComment._rule(),
									"*/".terminal(token: T._transient).not(producing: T._transient),
									].oneOf(token: T._transient).repeated(min: 0, producing: T._transient),
					"*/".terminal(token: T._transient),
					].sequence(token: T.multilineComment, annotations: annotations.isEmpty ? [ : ] : annotations)
				recursiveRule.surrogateRule = rule
				return recursiveRule
			}
			return cachedRule
		// comment
		case .comment:
			return [
					T.singleLineComment._rule(),
					T.multilineComment._rule(),
					].oneOf(token: T.comment, annotations: annotations)
		// whitespace
		case .whitespace:
			return [
					T.comment._rule(),
					CharacterSet.whitespacesAndNewlines.terminal(token: T._transient),
					].oneOf(token: T.whitespace, annotations: annotations.isEmpty ? [RuleAnnotation.void : RuleAnnotationValue.set] : annotations)
		// ows
		case .ows:
			return T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T.ows, annotations: annotations)
		// quantifier
		case .quantifier:
			return CharacterSet(charactersIn: "*+?-").terminal(token: T.quantifier, annotations: annotations)
		// negated
		case .negated:
			return "!".terminal(token: T.negated, annotations: annotations)
		// transient
		case .transient:
			return "-".terminal(token: T.transient, annotations: annotations)
		// lookahead
		case .lookahead:
			return ">>".terminal(token: T.lookahead, annotations: annotations)
		// stringQuote
		case .stringQuote:
			return "\"".terminal(token: T.stringQuote, annotations: annotations)
		// escapedCharacter
		case .escapedCharacter:
			return [
					"\\".terminal(token: T._transient),
					CharacterSet(charactersIn: "\"rnt\\").terminal(token: T._transient),
					].sequence(token: T.escapedCharacter, annotations: annotations.isEmpty ? [ : ] : annotations)
		// stringCharacter
		case .stringCharacter:
			return [
					T.escapedCharacter._rule(),
					[
									T.stringQuote._rule(),
									CharacterSet.newlines.terminal(token: T._transient),
									].oneOf(token: T._transient).not(producing: T._transient),
					].oneOf(token: T.stringCharacter, annotations: annotations.isEmpty ? [RuleAnnotation.void : RuleAnnotationValue.set] : annotations)
		// terminalBody
		case .terminalBody:
			return T.stringCharacter._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 1, producing: T.terminalBody, annotations: annotations)
		// stringBody
		case .stringBody:
			return T.stringCharacter._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T.stringBody, annotations: annotations)
		// string
		case .string:
			return [
					"\"".terminal(token: T._transient),
					T.stringBody._rule(),
					"\"".terminal(token: T._transient, annotations: [RuleAnnotation.error : RuleAnnotationValue.string("Missing terminating quote")]),
					].sequence(token: T.string, annotations: annotations.isEmpty ? [ : ] : annotations)
		// terminalString
		case .terminalString:
			return [
					"\"".terminal(token: T._transient),
					T.terminalBody._rule([RuleAnnotation.error : RuleAnnotationValue.string("Terminals must have at least one character")]),
					"\"".terminal(token: T._transient, annotations: [RuleAnnotation.error : RuleAnnotationValue.string("Missing terminating quote")]),
					].sequence(token: T.terminalString, annotations: annotations.isEmpty ? [ : ] : annotations)
		// characterSetName
		case .characterSetName:
			return ScannerRule.oneOf(token: T.characterSetName, ["letters", "uppercaseLetters", "lowercaseLetters", "alphaNumerics", "decimalDigits", "whitespacesAndNewlines", "whitespaces", "newlines", "backslash"],[ : ].merge(with: annotations))
		// characterSet
		case .characterSet:
			return [
								".".terminal(token: T._transient),
								T.characterSetName._rule([RuleAnnotation.error : RuleAnnotationValue.string("Unknown character set")]),
								].sequence(token: T.characterSet, annotations: annotations.isEmpty ? [ : ] : annotations)
		// rangeOperator
		case .rangeOperator:
			return [
					".".terminal(token: T._transient),
					"..".terminal(token: T._transient, annotations: [RuleAnnotation.error : RuleAnnotationValue.string("Expected ... in character range")]),
					].sequence(token: T.rangeOperator, annotations: annotations.isEmpty ? [ : ] : annotations)
		// characterRange
		case .characterRange:
			return [
					T.terminalString._rule(),
					T.rangeOperator._rule(),
					T.terminalString._rule([RuleAnnotation.error : RuleAnnotationValue.string("Range must be terminated")]),
					].sequence(token: T.characterRange, annotations: annotations.isEmpty ? [ : ] : annotations)
		// number
		case .number:
			return [
					CharacterSet(charactersIn: "-+").terminal(token: T._transient).optional(producing: T._transient),
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
								T.ows._rule(),
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
		// terminal
		case .terminal:
			return [
					T.characterSet._rule(),
					T.characterRange._rule(),
					T.terminalString._rule(),
					].oneOf(token: T.terminal, annotations: annotations)
		// group
		case .group:
			guard let cachedRule = STLR.leftHandRecursiveRules[self.rawValue] else {
				// Create recursive shell
				let recursiveRule = RecursiveRule()
				STLR.leftHandRecursiveRules[self.rawValue] = recursiveRule
				// Create the rule we would normally generate
				let rule = [
					"(".terminal(token: T._transient),
					T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
					T.expression._rule(),
					T.whitespace._rule([RuleAnnotation.void : RuleAnnotationValue.set]).repeated(min: 0, producing: T._transient),
					")".terminal(token: T._transient, annotations: [RuleAnnotation.error : RuleAnnotationValue.string("Expected ')'")]),
					].sequence(token: T.group, annotations: annotations.isEmpty ? [ : ] : annotations)
				recursiveRule.surrogateRule = rule
				return recursiveRule
			}
			return cachedRule
		// identifier
		case .identifier:
			return [
					CharacterSet.letters.union(CharacterSet(charactersIn: "_")).terminal(token: T._transient),
					CharacterSet.letters.union(CharacterSet.decimalDigits).union(CharacterSet(charactersIn: "_")).terminal(token: T._transient).repeated(min: 0, producing: T._transient),
					].sequence(token: T.identifier, annotations: annotations.isEmpty ? [ : ] : annotations)
		// element
		case .element:
			guard let cachedRule = STLR.leftHandRecursiveRules[self.rawValue] else {
				// Create recursive shell
				let recursiveRule = RecursiveRule()
				STLR.leftHandRecursiveRules[self.rawValue] = recursiveRule
				// Create the rule we would normally generate
				let rule = [
					T.annotations._rule().optional(producing: T._transient),
					[
									T.lookahead._rule(),
									T.transient._rule(),
									].oneOf(token: T._transient).optional(producing: T._transient),
					T.negated._rule().optional(producing: T._transient),
					[
									T.group._rule(),
									T.terminal._rule(),
									T.identifier._rule(),
									].oneOf(token: T._transient),
					T.quantifier._rule().optional(producing: T._transient),
					].sequence(token: T.element, annotations: annotations.isEmpty ? [ : ] : annotations)
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
			guard let cachedRule = STLR.leftHandRecursiveRules[self.rawValue] else {
				// Create recursive shell
				let recursiveRule = RecursiveRule()
				STLR.leftHandRecursiveRules[self.rawValue] = recursiveRule
				// Create the rule we would normally generate
				let rule = [
					T.element._rule(),
					[
									T.or._rule([RuleAnnotation.void : RuleAnnotationValue.set]),
									T.element._rule([RuleAnnotation.error : RuleAnnotationValue.string("Expected terminal, identifier, or group")]),
									].sequence(token: T._transient).repeated(min: 1, producing: T._transient),
					].sequence(token: T.choice, annotations: annotations.isEmpty ? [ : ] : annotations)
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
			guard let cachedRule = STLR.leftHandRecursiveRules[self.rawValue] else {
				// Create recursive shell
				let recursiveRule = RecursiveRule()
				STLR.leftHandRecursiveRules[self.rawValue] = recursiveRule
				// Create the rule we would normally generate
				let rule = [
					T.element._rule(),
					[
									T.then._rule([RuleAnnotation.void : RuleAnnotationValue.set]),
									T.notNewRule._rule().lookahead(),
									T.element._rule([RuleAnnotation.error : RuleAnnotationValue.string("Expected terminal, identifier, or group")]),
									].sequence(token: T._transient).repeated(min: 1, producing: T._transient),
					].sequence(token: T.sequence, annotations: annotations.isEmpty ? [ : ] : annotations)
				recursiveRule.surrogateRule = rule
				return recursiveRule
			}
			return cachedRule
		// expression
		case .expression:
			guard let cachedRule = STLR.leftHandRecursiveRules[self.rawValue] else {
				// Create recursive shell
				let recursiveRule = RecursiveRule()
				STLR.leftHandRecursiveRules[self.rawValue] = recursiveRule
				// Create the rule we would normally generate
				let rule = [
					T.choice._rule(),
					T.sequence._rule(),
					T.element._rule(),
					].oneOf(token: T.expression, annotations: annotations)
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

	// Color Definitions
	fileprivate var color : NSColor? {
		switch self {
		case .grammar:	return #colorLiteral(red:0.0, green:0.0, blue:0.0, alpha: 1)
		default:	return nil
		}
	}


	// Color Dictionary
	static var tokenNameColorIndex = ["grammar" : T.grammar.color!]

	// Cache for left-hand recursive rules
	private static var leftHandRecursiveRules = [ Int : Rule ]()

	// Create a language that can be used for parsing etc
	public static var generatedLanguage : Parser {
		return Parser(grammar: [T.grammar._rule()])
	}

	// Convient way to apply your grammar to a string
	public static func parse(source: String) -> DefaultHeterogeneousAST {
		return STLR.generatedLanguage.build(source: source)
	}
}
