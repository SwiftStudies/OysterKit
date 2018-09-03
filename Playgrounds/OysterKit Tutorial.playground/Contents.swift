import Foundation
import OysterKit

/// Scanning
let letter = CharacterSet.letters.parse(as:StringToken("letter"))

print("Letters")
for token in [letter].tokenize("Hello"){
    print(token)
}

/// Choices
let punctuation = [".",",","!","?"].choice.parse(as: StringToken("punctuation"))

print("Letters and Punctuation")
for token in [letter, punctuation].tokenize("Hello!"){
    print(token)
}

/// Skipping
let space = CharacterSet.whitespaces.skip()
print("Letters,Punctuation, and Whitespace")
for token in [letter, punctuation, space].tokenize("Hello, World!"){
    print(token)
}

/// Repetition
let word = letter.require(.oneOrMore).parse(as: StringToken("word"))

print("Words,Punctuation, and Whitespace")
for token in [word, punctuation, space].tokenize("Hello, World!"){
    print(token)
}

/// Sequences
let properNoun = [CharacterSet.uppercaseLetters, CharacterSet.lowercaseLetters.require(.zeroOrMore)].sequence.parse(as: StringToken("properNoun"))
let classifiedWord = [properNoun,word.parse(as: StringToken("other"))].choice.parse(as: StringToken("word"))

print("Word classification")
for token in [classifiedWord, punctuation, space].tokenize("Jon was here!"){
    print(token)
}

/// Parsing
do {
    print(try [[classifiedWord, punctuation, space].choice].parse("Jon was here!"))

} catch let error as ProcessingError {
    print(error.debugDescription)
}


/// Building a data-structure
struct Word : Decodable, CustomStringConvertible {
    let properNoun : String?
    let other : String?
    
    var description: String {
        return properNoun != nil ? "properNoun: \(properNoun!)" : "other: \(other!)"
    }
}

struct Sentence : Decodable {
    let words : [Word]
    let punctuation : String
}

do {
    let words = [classifiedWord, space.require(.zeroOrMore)].sequence.require(.oneOrMore).parse(as:StringToken("words"))
    let sentence = try [ [words, punctuation ].sequence ].build("Jon was here!", as: Sentence.self)

    print(sentence)
} catch let error as ProcessingError {
    print(error.debugDescription)
} catch {
    print(error)
}


