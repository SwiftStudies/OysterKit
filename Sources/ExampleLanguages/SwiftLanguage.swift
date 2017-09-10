//
// STLR Generated Swift File
//
// Generated: 2016-08-19 10:49:16 +0000
//
import Foundation
import OysterKit

//
// SwiftParser Parser
//
public class SwiftParser : Parser{
    
    // Convenience alias
    private typealias GrammarToken = Tokens
    
    // Token & Rules Definition
    enum Tokens : Int, Token {
        case _transient, whitespace, symbol, comment, number, stringQuote, escapedCharacter, stringCharacter, string, keyword, variable
        
        func _rule(_ annotations: RuleAnnotations = [ : ])->Rule {
            switch self {
            case ._transient:
                return CharacterSet(charactersIn: "").terminal(token: GrammarToken._transient)
            // whitespace
            case .whitespace:
                return CharacterSet.whitespacesAndNewlines.terminal(token: GrammarToken._transient).repeated(min: 0, producing: GrammarToken.whitespace)
            // symbol
            case .symbol:
                return CharacterSet(charactersIn: ".{}[]:=,()-><?#!").terminal(token: GrammarToken.symbol)
            // comment
            case .comment:
                return [
                    "//".terminal(token: GrammarToken._transient),
                    CharacterSet.newlines.terminal(token: GrammarToken._transient).not(producing: GrammarToken._transient).repeated(min: 0, producing: GrammarToken._transient),
                    ].sequence(token: GrammarToken.comment)
            // number
            case .number:
                return [
                    CharacterSet.decimalDigits.terminal(token: GrammarToken._transient).repeated(min: 1, producing: GrammarToken._transient),
                    [
                        ".".terminal(token: GrammarToken._transient),
                        CharacterSet.decimalDigits.terminal(token: GrammarToken._transient),
                        ].sequence(token: GrammarToken._transient).optional(producing: GrammarToken._transient),
                    ].sequence(token: GrammarToken.number)
            // stringQuote
            case .stringQuote:
                return "\"".terminal(token: GrammarToken.stringQuote)
            // escapedCharacter
            case .escapedCharacter:
                return [
                    "\\".terminal(token: GrammarToken._transient),
                    CharacterSet(charactersIn: "\"rnt\\").terminal(token: GrammarToken._transient),
                    ].sequence(token: GrammarToken.escapedCharacter)
            // stringCharacter
            case .stringCharacter:
                return [
                    GrammarToken.escapedCharacter._rule(),
                    [
                        GrammarToken.stringQuote._rule(),
                        CharacterSet.newlines.terminal(token: GrammarToken._transient),
                        ].oneOf(token: GrammarToken._transient).not(producing: GrammarToken._transient),
                    ].oneOf(token: GrammarToken.stringCharacter)
            // string
            case .string:
                return [
                    "\"".terminal(token: GrammarToken._transient),
                    GrammarToken.stringCharacter._rule().repeated(min: 0, producing: GrammarToken._transient),
                    "\"".terminal(token: GrammarToken._transient),
                    ].sequence(token: GrammarToken.string)
            // keyword
            case .keyword:
                return [
                    ScannerRule.oneOf(token: GrammarToken._transient, ["private", "class", "func", "var", "guard", "let", "static", "init", "case", "typealias", "enum"],[:]),
                    CharacterSet.whitespacesAndNewlines.terminal(token: GrammarToken._transient).repeated(min: 0, producing: GrammarToken._transient),
                    ].sequence(token: GrammarToken.keyword)
            // variable
            case .variable:
                return CharacterSet.letters.union(CharacterSet(charactersIn: "_")).terminal(token: GrammarToken._transient).repeated(min: 1, producing: GrammarToken.variable)
            }
        }
                
    }
    

    
    // Initialize the parser with the base rule set
    public init(){
        super.init(grammar: [GrammarToken.whitespace._rule(), GrammarToken.symbol._rule(), GrammarToken.comment._rule(), GrammarToken.number._rule(), GrammarToken.string._rule(), GrammarToken.keyword._rule(), GrammarToken.variable._rule()])
    }
}
