## OysterKit

<p align="center">
<img src="Resources/Artwork/Images/OysterKit%20180x180.png" height="180" alt="OysterKit">
<p align="center"><strong>A Swift Framework for Tokenizing, Parsing, and Interpreting Languages</strong></p>
</p>

<p align="center">
<a href="https://travis-ci.org/SwiftStudies/OysterKit">
<img src="https://travis-ci.org/SwiftStudies/OysterKit.svg?branch=master" alt="Build Status - Master">
</a>
<img src="https://codecov.io/gh/SwiftStudies/OysterKit/branch/master/graph/badge.svg" alt="codecov">
<img src="https://img.shields.io/badge/documentation-97%25-brightgreen.svg" alt="Documentation Coverage">
<img src="https://img.shields.io/badge/platforms-Linux%20%7C%20MacOS%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS-green.svg" alt="Platforms">
<img src="https://img.shields.io/pypi/l/Django.svg" alt="BSD">
<a href="https://codecov.io/gh/SwiftStudies/OysterKit">
</a>
</p>

OysterKit enables native Swift scanning, lexical analysis, and parsing capabilities as a pure Swift framework. Two additional elements are also provided in this package. The first is a second framework STLR which uses OysterKit to provide a plain text grammar specification language called STLR (Swift Tool for Language Recognition). Finally a command line tool, ````stlr```` can be used to automatically generate Swift source code for OysterKit for STLR grammars, as well as dynamically apply STLR grammars to a number of use-cases. The following documentation is available: 

 - [OysterKit API Documentation](https://rawgit.com/SwiftStudies/OysterKit/master/Documentation/OysterKit/index.html) Full API documentation for the OysterKit framework
 - [STLR API Documentation](https://rawgit.com/SwiftStudies/OysterKit/master/Documentation/STLR/index.html) Full API documentation for the STLR framework
 	- [STLR Language Reference](https://github.com/SwiftStudies/OysterKit/blob/master/Documentation/STLR.md) A guide with examples to using the STLR language to define grammars
 	- [Tutorials](https://github.com/SwiftStudies/OysterKit/tree/master/Documentation/Tutorials) Tutorials for using OysterKit and STLR for defining and exploiting grammars. 
 - [stlrc Command Line Tool reference](https://github.com/SwiftStudies/OysterKit/blob/master/Documentation/stlr-toolc.md) Instructions for using the ````stlrc```` command line tool. Note that some of the tutorials referenced above also provide some concrete usage examples.

__Please note__ all development is now for Swift 4.2 and beyond only. If you wish to use the last Swift 4.1 compatible release please use the ```swift/4.1``` branch 

## Key Features

  - **OysterKit** Provides support for scanning strings
	  - Fully supports direct and indirect left hand recursion in rules
	  - Provides support for parsing strings using defined rules as streams of tokens or constructing Abstract Syntax Trees (ASTs)
	  - All of the above provided as implementations of protocols allowing the replacement of any by your own components if you wish
	  - Create your own file decoders (using Swift 4's Encoding/Decoding framework `Encodable` and `Decodable`) 
  - **STLR** Provides support for defining scanning (terminal) and parsing rules
  	- A lexical analysis and parser definition language, STLR, which can be compiled at run-time in memory, or from stored files
  	- Complied STLR can be used immediately at run time, or through the generation of a Swift source file

## Examples


### Creating a rule and tokenizing a String
OysterKit can be used to create and use grammars very quickly and simply directly in Swift. Here are are few simple examples

	/// Scanning
	let letter = CharacterSet.letters.parse(as:StringToken("letter"))

	for token in [letter].tokenize("Hello"){
    	print(token)
	}
	
Instances `CharacterSet`, `String`, and `NSRegularExpression` can all be used as rules directly. To make a rule produce a token just use the `parse(as:TokenType)` function of a rule. A grammar is simply an array of rules, and you can use that grammar to tokenise a string. 

### Making choices

A choice rule is simply one where any of the rules contained can match to satisfy the `choice`. In this case the `punctuation` rule can be one of a number of strings. We can then tokenize

    /// Choices
    let punctuation = [".",",","!","?"].choice.parse(as: StringToken("punctuation"))
    
    for token in [letter, punctuation].tokenize("Hello!"){
        print(token)
    }

### Skipping Content
You don't always want to create tokens for everything. You can chain modifications to any rule together as rules have value based semantics... you don't change the original. 

    /// Skipping
    let space = CharacterSet.whitespaces.skip()
    
    for token in [letter, punctuation, space].tokenize("Hello, World!"){
        print(token)
    }

We use all three of our different rules to tokenize "Hello, World!", but notice that we call `skip()` on the `space` rule. That means no token will be created (and when we get to more complex parsing later... it also means that if this rule forms part of another more complex rule, the skipped rules at the beginning and end won't be included in the matched range. But more on that later). You'll only get `letter` and `punctuation` tokens iun this example, but you'll still match spaces. 

### Repetition

You can also tell a rule how many times it must match before generating a token. Here we create a `word` token which repeats our `letter` rule one or more times. 

    let word = letter.require(.oneOrMore).parse(as: StringToken("word"))
    
    for token in [word, punctuation, space].tokenize("Hello, World!"){
        print(token)
    }

There are standard ones for `one`,`noneOrOne`, `noneOrMore`, and `oneOrMore` but you can also specify a closed or open range (e.g. `.require(2...)` would match two or more. 

### Sequences

Rules can be made up of sequences of other rules. In this example we create a `properNoun` rule which requires an uppercase letter followed by zero or more lowercase letters. Note that we create a new rule from our previous `word` rule that generates a different token (`other`). Then we make our new `choice` generate the `word` token. We've just created a little hierarchy in our grammar. `word` will match `properNoun` or `other` (our old `word` rule). You'll see why this is useful later. When you stream you'll just get `word` (not `properNoun` or `other`). 

    // Sequences
    let properNoun = [CharacterSet.uppercaseLetters, CharacterSet.lowercaseLetters.require(.zeroOrMore)].sequence.parse(as: StringToken("properNoun"))
    let classifiedWord = [properNoun,word.parse(as: StringToken("other"))].choice.parse(as: StringToken("word"))
    
    print("Word classification")
    for token in [classifiedWord, punctuation, space].tokenize("Jon was here!"){
        print(token)
    }

### Parsing - Beyond Tokenization

Tokenizing is great, and there are many applications where it's enough (syntax highlighting anyone?), but if you are going to attempt anything like building an actual language, or want to parse a more complex data structure you are going to want to build an Abstract Syntax Tree. OysterKit can build HomogenousTree's from any grammar. Wait! Don't go. It's not that bad! Here it is in action. 

    do {
        print(try [[classifiedWord, punctuation, space].choice].parse("Jon was here!"))
    
    } catch let error as ProcessingError {
        print(error.debugDescription)
    }

Here we use `parse()` instead of `tokenize()`. We need to wrap it in a `do-catch` block because whereas with tokenization we just stopped streaming when something went wrong, we can get a lot more information when we parse including errors. This code simply tries to parse (note this time we are creating a single rule grammar, but that single rule is a `choice` of all our other rules) the same string as before, but this time it produces a tree. Here's what would be printed out

    root 
	    word 
		    properNoun - 'Jon'
	    word 
		    other - 'was'
	    word 
		    other - 'here'
	    punctuation - '!'

Now we can see our word classification. 

### Building Complex Heterogenous Abstract Syntax Trees

I know... I did it again... jargon. It's pretty simple though. Homogenous means "of the same kind", so a Homogenous tree is just one where every node in the tree is the same type. That's what the `parse` function creates. `build` can create heterogenous (data structures populated with different kinds of data) of data structures, such as Swift types. OysterKit uses the power of Swift make this really quite simple.

Out of the box you can `Decode` and `Decodable` type using an OysterKit grammar (and if you think this is powerful, wait until you've had a look at [STLR](https://github.com/SwiftStudies/OysterKit/blob/master/Documentation/STLR.md) and auto-generated the Swift source code instead of doing all of the typing you are about to see!). 

First, let's declare some data structures for words and sentances. 

    struct Word : Decodable, CustomStringConvertible {
        let properNoun : String?
        let other : String?
        
        var description: String {
            return properNoun != nil ? "properNoun: \(properNoun!)" : "other: \(other!)"
        }
    }
    
    struct Sentance : Decodable {
        let words : [Word]
        let punctuation : String
    }

Fairly straightforward (if inaccurate... you can normally have more punctuation than just at the end). Now we define a grammar that produces tokens with names that match the properties of our types, and OysterKit (and Swift) will do the rest. 

    do {
        let words = [classifiedWord, space.require(.zeroOrMore)].sequence.require(.oneOrMore).parse(as:StringToken("words"))
        let sentance = try [ [words, punctuation ].sequence ].build("Jon was here!", as: Sentance.self)
    
        print(sentance)
    } catch let error as ProcessingError {
        print(error.debugDescription)
    } catch {
        print(error)
    }

Instead of `parse()` we `build()`. We need an extra parameter here; you need to tell `build` what you want to build it `as`. 

	.build("Jon was here!", as: Sentance.self)
	
That tree we saw in the previous example can be exactly matched against our data-structure. 

### But what if I want a Heterogeneous Tree but don't want to go to all that effort? 

Luckily OysterKit comes hand in hand with STLR which is a language for writing grammars. You can either dynamically turn this into Swift in memory (perfect if you just want to `parse`) or use the final member of the trinity `stlrc` to generate the Swift not just for the rules, but the Swift data structures too. You can read [full documentation for STLR here](), but I wanted to leave you with an example of the STLR for the grammar we finished with, and the Swift it generates, but not before showing you the only Swift you'll need to write to use it

#### The only code you'll have to write

All you need to do is build an instance of the generated type...

    do {
	    let sentance = Sentance.build("Hello Jon!")
    } catch {
	    print(error)
    }

It's really that simple. OK, here's where it came from

#### The STLR

	grammar Sentance

	punctuation = "." | "," | "!" | "?"

	properNoun  = .uppercaseLetter .lowercaseLetter*
	other       = .letter+

	word        = properNoun | other
	words       = (word -.whitespace+)+

	sentance    = words punctuation

Yup. That's it. Here's the Swift that was generated. There seems to be a lot of it... but remember, you don't even need to look at it if you don't want to! When you do though, you should see all of the things you've learned in there

#### The Generated Swift

We can now use `stlrc` to compile the STLR into Swift. This simple command will do that

	stlrc generate -g Sentance.stlr -l swiftIR -ot ./
	
The above command will generate a Sentance.swift file in the current directory. You should see what it does if you change `-l swiftIR` to `-l SwiftPM`... but that's another story. Here's what's in Sentance.swift

	import Foundation
	import OysterKit

	/// Intermediate Representation of the grammar
	internal enum SentanceTokens : Int, TokenType, CaseIterable, Equatable {
	    typealias T = SentanceTokens

	    /// The tokens defined by the grammar
	    case `punctuation`, `properNoun`, `other`, `word`, `words`, `sentance`

	    /// The rule for the token
	    var rule : Rule {
		switch self {
		    /// punctuation
		    case .punctuation:
			return [".", ",", "!", "?"].choice.reference(.structural(token: self))

		    /// properNoun
		    case .properNoun:
			return [CharacterSet.uppercaseLetters,    CharacterSet.lowercaseLetters.require(.zeroOrMore)].sequence.reference(.structural(token: self))

		    /// other
		    case .other:
			return CharacterSet.letters.require(.oneOrMore).reference(.structural(token: self))

		    /// word
		    case .word:
			return [T.properNoun.rule,T.other.rule].choice.reference(.structural(token: self))

		    /// words
		    case .words:
			return [T.word.rule, -CharacterSet.whitespaces.require(.oneOrMore)].sequence.require(.oneOrMore).reference(.structural(token: self))

		    /// sentance
		    case .sentance:
			return [T.words.rule,T.punctuation.rule].sequence.reference(.structural(token: self))
		}
	    }

	    /// Create a language that can be used for parsing etc
	    public static var generatedRules: [Rule] {
		return [T.sentance.rule]
	    }
	}

	public struct Sentance : Codable {

	    // Punctuation
	    public enum Punctuation : Swift.String, Codable, CaseIterable {
		case period = ".",comma = ",",ping = "!",questionMark = "?"
	    }

	    // Word
	    public enum Word : Swift.String, Codable, CaseIterable {
		case properNoun,other
	    }

	    public typealias Words = [Word] 

	    /// Sentance 
	    public struct Sentance : Codable {
		public let words: Words
		public let punctuation: Punctuation
	    }
	    public let sentance : Sentance
	    
	    /**
	     Parses the supplied string using the generated grammar into a new instance of
	     the generated data structure

	     - Parameter source: The string to parse
	     - Returns: A new instance of the data-structure
	     */
	    public static func build(_ source : Swift.String) throws ->Sentance{
		let root = HomogenousTree(with: StringToken("root"), matching: source, children: [try AbstractSyntaxTreeConstructor().build(source, using: Sentance.generatedLanguage)])
		// print(root.description)
		return try ParsingDecoder().decode(Sentance.self, using: root)
	    }

	    public static var generatedLanguage : Grammar {return SentanceTokens.generatedRules}
	}

There are some interesting (and I think rather clever) things in there. Note that for the `Word` type STLR has been clever and determined that there are only a couple of possible values and that both of those are just Strings, so it's created an enum instead. It's done that for `Punctuation` as well, but that's a little easier as it was just a choice of simple strings. It's also determined that it doesn't really need to create a new type for Words, it can just use a `typealias`. 

I mention this because you will be interacting with this data structure, so I've spent a lot of time making sure it genertes easy to use Swift, that's strongly typed. This is going to make it easier for you to work with once building is complete. 

## Status
You will notice there are some warnings in this build. You should not be concerned by these as they are largely forward references to further clean up that can be done now that STLR is generating the Swift code for both Rules/Tokens as well as the data-structures for itself. Deprication is in full swing now as I start to move closer to 1.0 and want to get old code out. 

