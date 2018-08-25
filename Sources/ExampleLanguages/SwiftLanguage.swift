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
                return ~CharacterSet(charactersIn: "")
            // whitespace
            case .whitespace:
                return ~CharacterSet.whitespacesAndNewlines.require(.oneOrMore).parse(as: self)
            // symbol
            case .symbol:
                return CharacterSet(charactersIn: ".{}[]:=,()-><?#!").parse(as: self)
            // comment
            case .comment:
                return [
                    ~"//",
                    !CharacterSet.newlines.require(.oneOrMore),
                    ].sequence.parse(as: self)
            // number
            case .number:
                return [
                    CharacterSet.decimalDigits.require(.oneOrMore),
                    [
                        ~".",
                        CharacterSet.decimalDigits.require(.oneOrMore),
                        ].sequence.require(.optionally),
                    ].sequence.parse(as: self)
            // stringQuote
            case .stringQuote:
                return "\"".parse(as: self)
            // escapedCharacter
            case .escapedCharacter:
                return [
                    ~"\\",
                    ~CharacterSet(charactersIn: "\"rnt\\"),
                    ].sequence.parse(as: self)
            // stringCharacter
            case .stringCharacter:
                return [
                            GrammarToken.escapedCharacter._rule(),
                            ![
                                GrammarToken.stringQuote._rule(),
                                CharacterSet.newlines.require(.one),
                            ].sequence,
                       ].sequence.parse(as:self)
            // string
            case .string:
                return [
                    ~"\"",
                    GrammarToken.stringCharacter._rule().require(.noneOrMore),
                    ~"\"",
                    ].sequence.parse(as: self)
            // keyword
            case .keyword:
                return [
                    ["private", "class", "func", "var", "guard", "let", "static", "init", "case", "typealias", "enum"].choice,
                    CharacterSet.whitespacesAndNewlines.require(.noneOrMore),
                    ].sequence.parse(as:self)
            // variable
            case .variable:
                return CharacterSet.letters.union(CharacterSet(charactersIn: "_")).require(.oneOrMore).parse(as: self)
            }
        }
                
    }
    

    
    // Initialize the parser with the base rule set
    public init(){
        super.init(grammar: [GrammarToken.whitespace._rule(), GrammarToken.symbol._rule(), GrammarToken.comment._rule(), GrammarToken.number._rule(), GrammarToken.string._rule(), GrammarToken.keyword._rule(), GrammarToken.variable._rule()])
    }
}
