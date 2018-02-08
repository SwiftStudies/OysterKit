// 
// STLR Generated Swift File
// 
// Generated: 2018-02-08 22:12:30 +0000
// 
import Cocoa
import OysterKit

// 
// OneOfEverythingGrammar Parser
// 
enum OneOfEverythingGrammar : Int, Token {

	// Convenience alias
	private typealias T = OneOfEverythingGrammar

	case _transient = -1, `ws`, `boolean`

	func _rule(_ annotations: RuleAnnotations = [ : ])->Rule {
		switch self {
		case ._transient:
			return CharacterSet(charactersIn: "").terminal(token: T._transient)
		// ws
		case .ws:
			return CharacterSet.whitespacesAndNewlines.terminal(token: T._transient, annotations: annotations).repeated(min: 1, producing: T.ws, annotations: annotations)
		// boolean
		case .boolean:
			return ScannerRule.oneOf(token: T.boolean, ["true", "false"],[ : ].merge(with: annotations))
		}
	}


	// Create a language that can be used for parsing etc
	public static var generatedLanguage : Parser {
		return Parser(grammar: [T.ws._rule(), T.boolean._rule()])
	}

	// Convient way to apply your grammar to a string
	public static func parse(source: String) -> DefaultHeterogeneousAST {
		return OneOfEverythingGrammar.generatedLanguage.build(source: source)
	}
}
