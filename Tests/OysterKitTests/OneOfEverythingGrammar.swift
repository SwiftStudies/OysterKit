// 
// STLR Generated Swift File
// 
// Generated: 2018-02-09 00:00:03 +0000
// 
import Foundation
import OysterKit

enum OneOfEverythingGrammar : Int, Token {
    typealias T = OneOfEverythingGrammar
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
    case `ws`, `boolean`, `integer`, `byte`, `word`, `longWord`, `longLongWord`, `unsignedInteger`, `unsignedByte`, `unsignedWord`, `unsignedLongWord`, `unsignedLongLongWord`, `float`, `double`, `string`, `oneOfEverything`
    
    /// The rule for the token
    var rule : Rule {
        switch self {
        /// ws
        case .ws:
            return -[
                CharacterSet.whitespacesAndNewlines.require(.zeroOrMore)
                ].sequence
            
        /// boolean
        case .boolean:
            return [["true","false"].choice, T.ws.rule].sequence.reference(.structural(token: self))
            
        /// integer
        case .integer:
            return [CharacterSet.decimalDigits.require(.oneOrMore), T.ws.rule].sequence.reference(.structural(token: self))
        /// byte
        case .byte:
            return [CharacterSet.decimalDigits.require(.oneOrMore), T.ws.rule].sequence.reference(.structural(token: self))
        /// word
        case .word:
            return [CharacterSet.decimalDigits.require(.oneOrMore), T.ws.rule].sequence.reference(.structural(token: self))
        /// longWord
        case .longWord:
            return [CharacterSet.decimalDigits.require(.oneOrMore), T.ws.rule].sequence.reference(.structural(token: self))
        /// longLongWord
        case .longLongWord:
            return [CharacterSet.decimalDigits.require(.oneOrMore), T.ws.rule].sequence.reference(.structural(token: self))
        /// unsignedInteger
        case .unsignedInteger:
            return [CharacterSet.decimalDigits.require(.oneOrMore), T.ws.rule].sequence.reference(.structural(token: self))
        /// unsignedByte
        case .unsignedByte:
            return [CharacterSet.decimalDigits.require(.oneOrMore), T.ws.rule].sequence.reference(.structural(token: self))
        /// unsignedWord
        case .unsignedWord:
            return [CharacterSet.decimalDigits.require(.oneOrMore), T.ws.rule].sequence.reference(.structural(token: self))
        /// unsignedLongWord
        case .unsignedLongWord:
            return [CharacterSet.decimalDigits.require(.oneOrMore), T.ws.rule].sequence.reference(.structural(token: self))
        /// unsignedLongLongWord
        case .unsignedLongLongWord:
            return [CharacterSet.decimalDigits.require(.oneOrMore), T.ws.rule].sequence.reference(.structural(token: self))
        /// float
        case .float:
            return [
                [
                    CharacterSet.decimalDigits.require(.oneOrMore),
                    ".".require(.one),
                    CharacterSet.decimalDigits.require(.oneOrMore),
                    T.ws.rule.require(.one)].sequence
                
                ].sequence.parse(as: self)
            
        /// double
        case .double:
            return [
                [
                    CharacterSet.decimalDigits.require(.oneOrMore),
                    ".".require(.one),
                    CharacterSet.decimalDigits.require(.oneOrMore),
                    T.ws.rule.require(.one)].sequence
                
                ].sequence.parse(as: self)
            
        /// string
        case .string:
            return [
                [
                    CharacterSet.letters.require(.oneOrMore),
                    T.ws.rule.require(.one)].sequence
                
                ].sequence.parse(as: self)
            
        /// oneOfEverything
        case .oneOfEverything:
            return [
                [
                    T.boolean.rule.require(.one),
                    T.integer.rule.require(.one),
                    T.byte.rule.require(.one),
                    T.word.rule.require(.one),
                    T.longWord.rule.require(.one),
                    T.longLongWord.rule.require(.one),
                    T.unsignedInteger.rule.require(.one),
                    T.unsignedByte.rule.require(.one),
                    T.unsignedWord.rule.require(.one),
                    T.unsignedLongWord.rule.require(.one),
                    T.unsignedLongLongWord.rule.require(.one),
                    T.float.rule.require(.one),
                    T.double.rule.require(.one),
                    T.string.rule.require(.one),
                    T.string.rule.require(.optionally),
                    T.ws.rule.require(.one)].sequence
                
                ].sequence.parse(as: self)
            
        }
    }

    /// Create a language that can be used for parsing etc
    public static var grammar: [Rule] {
        return [T.oneOfEverything.rule]
    }
}

