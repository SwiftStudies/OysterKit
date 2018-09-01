import Foundation
import OysterKit

/// Scanning
let letter = CharacterSet.letters.parse(as:StringToken("letter"))

print("Letters")
for token in TokenStream("Hello", using: Parser(grammar: [letter])){
    print(token)
}

/// Choices
let punctuation = [".",",","!","?"].choice.parse(as: StringToken("punctuation"))

print("Letters and Punctuation")
for token in TokenStream("Hello!", using: Parser(grammar: [letter, punctuation])){
    print(token)
}

/// Skipping
let space = CharacterSet.whitespaces.skip()
print("Letters,Punctuation, and Whitespace")
for token in TokenStream("Hello, World!", using: Parser(grammar: [letter, punctuation, space])){
    print(token)
}

/// Repetition
let word = letter.require(.oneOrMore).parse(as: StringToken("word"))

print("Words,Punctuation, and Whitespace")
for token in TokenStream("Hello, World!", using: Parser(grammar: [word, punctuation, space])){
    print(token)
}

/// Sequences
let properNoun = [CharacterSet.uppercaseLetters, CharacterSet.lowercaseLetters.require(.zeroOrMore)].sequence.parse(as: StringToken("Proper Noun"))
let classifiedWord = [properNoun,word].choice

print("Word classification")
for token in TokenStream("Jon was here!", using: Parser(grammar: [classifiedWord, punctuation, space])){
    print(token)
}

try! AbstractSyntaxTreeConstructor(with: "Jon was here!").build(using: Parser(grammar: [[classifiedWord, punctuation, space].choice]))
