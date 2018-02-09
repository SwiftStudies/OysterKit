// 
// STLR Generated Swift File
// 
// Generated: 2018-02-09 00:00:03 +0000
// 
#if os(macOS)
import Cocoa
#elseif os(iOS)
import UIKit
#else
import Foundation
#endif
import OysterKit

// 
// OneOfEverythingGrammar Parser
// 
enum OneOfEverythingGrammar : Int, Token {

	// Convenience alias
	private typealias T = OneOfEverythingGrammar

	case _transient = -1, `ws`, `boolean`, `integer`, `byte`, `word`, `longWord`, `longLongWord`, `unsignedInteger`, `unsignedByte`, `unsignedWord`, `unsignedLongWord`, `unsignedLongLongWord`, `float`, `double`, `string`, `oneOfEverything`

	func _rule(_ annotations: RuleAnnotations = [ : ])->Rule {
		switch self {
		case ._transient:
			return CharacterSet(charactersIn: "").terminal(token: T._transient)
		// ws
		case .ws:
			return CharacterSet.whitespacesAndNewlines.terminal(token: T._transient, annotations: annotations.isEmpty ? [RuleAnnotation.void : RuleAnnotationValue.set] : annotations).repeated(min: 0, producing: T.ws, annotations: annotations.isEmpty ? [RuleAnnotation.void : RuleAnnotationValue.set] : annotations)
		// boolean
		case .boolean:
			return [
					ScannerRule.oneOf(token: T._transient, ["true", "false"],[:].merge(with: annotations)),
					T.ws._rule([RuleAnnotation.void : RuleAnnotationValue.set]),
					].sequence(token: T.boolean, annotations: annotations.isEmpty ? [ : ] : annotations)
		// integer
		case .integer:
			return [
					CharacterSet.decimalDigits.terminal(token: T._transient).repeated(min: 1, producing: T._transient),
					T.ws._rule([RuleAnnotation.void : RuleAnnotationValue.set]),
					].sequence(token: T.integer, annotations: annotations.isEmpty ? [ : ] : annotations)
		// byte
		case .byte:
			return [
					CharacterSet.decimalDigits.terminal(token: T._transient).repeated(min: 1, producing: T._transient),
					T.ws._rule([RuleAnnotation.void : RuleAnnotationValue.set]),
					].sequence(token: T.byte, annotations: annotations.isEmpty ? [ : ] : annotations)
		// word
		case .word:
			return [
					CharacterSet.decimalDigits.terminal(token: T._transient).repeated(min: 1, producing: T._transient),
					T.ws._rule([RuleAnnotation.void : RuleAnnotationValue.set]),
					].sequence(token: T.word, annotations: annotations.isEmpty ? [ : ] : annotations)
		// longWord
		case .longWord:
			return [
					CharacterSet.decimalDigits.terminal(token: T._transient).repeated(min: 1, producing: T._transient),
					T.ws._rule([RuleAnnotation.void : RuleAnnotationValue.set]),
					].sequence(token: T.longWord, annotations: annotations.isEmpty ? [ : ] : annotations)
		// longLongWord
		case .longLongWord:
			return [
					CharacterSet.decimalDigits.terminal(token: T._transient).repeated(min: 1, producing: T._transient),
					T.ws._rule([RuleAnnotation.void : RuleAnnotationValue.set]),
					].sequence(token: T.longLongWord, annotations: annotations.isEmpty ? [ : ] : annotations)
		// unsignedInteger
		case .unsignedInteger:
			return [
					CharacterSet.decimalDigits.terminal(token: T._transient).repeated(min: 1, producing: T._transient),
					T.ws._rule([RuleAnnotation.void : RuleAnnotationValue.set]),
					].sequence(token: T.unsignedInteger, annotations: annotations.isEmpty ? [ : ] : annotations)
		// unsignedByte
		case .unsignedByte:
			return [
					CharacterSet.decimalDigits.terminal(token: T._transient).repeated(min: 1, producing: T._transient),
					T.ws._rule([RuleAnnotation.void : RuleAnnotationValue.set]),
					].sequence(token: T.unsignedByte, annotations: annotations.isEmpty ? [ : ] : annotations)
		// unsignedWord
		case .unsignedWord:
			return [
					CharacterSet.decimalDigits.terminal(token: T._transient).repeated(min: 1, producing: T._transient),
					T.ws._rule([RuleAnnotation.void : RuleAnnotationValue.set]),
					].sequence(token: T.unsignedWord, annotations: annotations.isEmpty ? [ : ] : annotations)
		// unsignedLongWord
		case .unsignedLongWord:
			return [
					CharacterSet.decimalDigits.terminal(token: T._transient).repeated(min: 1, producing: T._transient),
					T.ws._rule([RuleAnnotation.void : RuleAnnotationValue.set]),
					].sequence(token: T.unsignedLongWord, annotations: annotations.isEmpty ? [ : ] : annotations)
		// unsignedLongLongWord
		case .unsignedLongLongWord:
			return [
					CharacterSet.decimalDigits.terminal(token: T._transient).repeated(min: 1, producing: T._transient),
					T.ws._rule([RuleAnnotation.void : RuleAnnotationValue.set]),
					].sequence(token: T.unsignedLongLongWord, annotations: annotations.isEmpty ? [ : ] : annotations)
		// float
		case .float:
			return [
					CharacterSet.decimalDigits.terminal(token: T._transient).repeated(min: 1, producing: T._transient),
					".".terminal(token: T._transient),
					CharacterSet.decimalDigits.terminal(token: T._transient).repeated(min: 1, producing: T._transient),
					T.ws._rule([RuleAnnotation.void : RuleAnnotationValue.set]),
					].sequence(token: T.float, annotations: annotations.isEmpty ? [ : ] : annotations)
		// double
		case .double:
			return [
					CharacterSet.decimalDigits.terminal(token: T._transient).repeated(min: 1, producing: T._transient),
					".".terminal(token: T._transient),
					CharacterSet.decimalDigits.terminal(token: T._transient).repeated(min: 1, producing: T._transient),
					T.ws._rule([RuleAnnotation.void : RuleAnnotationValue.set]),
					].sequence(token: T.double, annotations: annotations.isEmpty ? [ : ] : annotations)
		// string
		case .string:
			return [
					CharacterSet.letters.terminal(token: T._transient).repeated(min: 1, producing: T._transient),
					T.ws._rule([RuleAnnotation.void : RuleAnnotationValue.set]),
					].sequence(token: T.string, annotations: annotations.isEmpty ? [ : ] : annotations)
		// oneOfEverything
		case .oneOfEverything:
			return [
					T.boolean._rule(),
					T.integer._rule(),
					T.byte._rule(),
					T.word._rule(),
					T.longWord._rule(),
					T.longLongWord._rule(),
					T.unsignedInteger._rule(),
					T.unsignedByte._rule(),
					T.unsignedWord._rule(),
					T.unsignedLongWord._rule(),
					T.unsignedLongLongWord._rule(),
					T.float._rule(),
					T.double._rule(),
					T.string._rule(),
					T.string._rule().optional(producing: T._transient),
					T.ws._rule([RuleAnnotation.void : RuleAnnotationValue.set]),
					].sequence(token: T.oneOfEverything, annotations: annotations.isEmpty ? [ : ] : annotations)
		}
	}


	// Create a language that can be used for parsing etc
	public static var generatedLanguage : Parser {
		return Parser(grammar: [T.oneOfEverything._rule()])
	}

	// Convient way to apply your grammar to a string
	public static func parse(source: String) throws -> HomogenousTree {
		return try AbstractSyntaxTreeConstructor().build(source, using: generatedLanguage)
	}
}
