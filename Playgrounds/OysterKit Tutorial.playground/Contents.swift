import Foundation
import OysterKit

/// Scanning
let letter = CharacterSet.letters.parse(as:StringToken("letter"))

print("Letters")
for token in [letter].stream("Hello"){
    print(token)
}

/// Choices
let punctuation = [".",",","!","?"].choice.parse(as: StringToken("punctuation"))

print("Letters and Punctuation")
for token in [letter, punctuation].stream("Hello!"){
    print(token)
}

/// Skipping
let space = CharacterSet.whitespaces.skip()
print("Letters,Punctuation, and Whitespace")
for token in [letter, punctuation, space].stream("Hello, World!"){
    print(token)
}

/// Repetition
let word = letter.require(.oneOrMore).parse(as: StringToken("word"))

print("Words,Punctuation, and Whitespace")
for token in [word, punctuation, space].stream("Hello, World!"){
    print(token)
}

/// Sequences
let properNoun = [CharacterSet.uppercaseLetters, CharacterSet.lowercaseLetters.require(.zeroOrMore)].sequence.parse(as: StringToken("Proper Noun"))
let classifiedWord = [properNoun,word].choice

print("Word classification")
for token in [classifiedWord, punctuation, space].stream("Jon was here!"){
    print(token)
}

do {
    print(try [[classifiedWord, punctuation, space].choice].parse("Jon was here!"))

} catch let error as ProcessingError {
    print(error.debugDescription)
}

