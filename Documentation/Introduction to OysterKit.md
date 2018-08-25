# Introduction to OysterKit

In this short document we will endeavor to provide guidance on building rules and parsers directly within code. It should be noted that whilst this is very useful when experimenting, far more benefit can be derived from using STLR to build your language. This will enable automatic code generation for Swift, including the abstract syntax tree.

However, it is often useful to see the underlying mechanics being applied, and this document will introduce the key concepts.

## Parsing source with your grammar

The remaining sections will discuss how rules can be built, but whatever you are building, you will at some point want to parse a string with your grammar. This can be done in a small block of Swift

    let source = "<your source>"            // Replace with your source
    let rules  = [rule1, rule2, ...]        // Replace with your rules

    do {
        let tree = try AbstractSyntaxTreeConstructor().build(source, using: Parser(grammar: [rules]))
        print(tree)
    } catch {
        print("Error: \(error)")
    }

You will find this little block very useful in testing what you build.

## Scanning Rules

Scanning rules can be applied to all terminals (```String```, ```CharacterSet```, ```NSRegularExpression```, and arrays of any of those types) and the following functions are provided through extensions. Arrays are treated as squences (that is each terminal must be matched successfully in order and the cardinality specified is applied to the sequence not the individual elements)

### skip(_ cardinality:Cardinality)
Creates a rule that will skip the specified number of matches of that terminal

### scan(_ cardinality:Cardinality)
Creates a rule that will scan the specified number of matches of that terminal

### token(token:Token, cardinality:Cardinality)
Creates a rule that will scan and create a token for the specified number of matches of that terminal

## Rule Operators

A number of rule modifiers are provided that provide a short-hand for modifying existing rules and creating new instances with different properties. The same rules of precidence are applied as defined by STLR, that is: 

1. Negation
2. Cardinality
3. Annotations
4. Structure, Scanning, and Skipping
5. Lookahead

The implication of this is that if you apply lookahead to a rule, all other operators on that rule will be applied before lookahead behaviour is applied. For example:

    >>CharacterSet.letters.scan(.oneOrMore)
    
Will lookahead for repeated letters. 

These operators are provided both as new or overloaded swift operators or as functions on appropriate types. 

### ! Operator
Applies negation to the rule

    !CharacterSet.letters.scan()
    
Will scan for a single character that is not a letter. Negating a negated rule results in a negated rule (it does not toggle).

### >> Operator
Applies lookahead behaviour to the rule

    >>"hello".scan()
    
Will match, but not advance the scanner, if ```hello``` is present at the scan head

### - Opeartor
Applies skipping behaviour to the rule

    -"hello".token(myToken)
    
Will result in no token being produced and the scan head skipping to the end of ```hello```

### ~ Operator
Applies scanning behaviour to the rule

Applies skipping behaviour to the rule

    ~"hello".token(myToken)

Will result in no token being produced and the scan head moving to the end of ```hello```

### Token.if(_rule:Rule)
Applies structural token producing behaviour to the rule

    myToken.if("hello".scan)

Would result in a token being created

### Rule.annotatedWith(_ annotations:RuleAnnotations)
Creates a new rule annotated with the specified annotations

### Rule.one
Creates a new rule with a cardinality of one

### Rule.optional
Creates a new rule which matches 0 or 1 matches of the rule

### Rule.zeroOrMore
Creates a new rule which matches any number of matches of the rule

### Rule.oneOrMore
Creates a new rule which matches one or more matches of the rule

### Cardinality.of(_ rule)
Creates a new rule with the specified cardinality

### Array<Rule>.oneOf

Creates a choice rule (any one of the contained rules matches this rule)

### Array<Rule>.sequence

Creates a rule where each sub-rule must be matched in order

## Usage Guide

These operators are designed to allow you to chain together a series of calls to rapidly build rules directly in 
your code. There are some simple guidelines that can be followed to make sure that your rules are highly 
readable. 

1. Tokens are key to any parser. These can be easily defined as ```Int``` enumerations.
2. Not all of the rules you may wish to use several times will generate tokens, these can be
defined as static properties of the enumeration
3. Start with the core of the rule (for example, matches one or more letters) and chain operators and functions
to it
4. Create a function to generate a rule for each of your tokens. 

Here is an example of a simple grammar that uses this methodology

    // Define an enumeration, that conforms to Token. There is no additional work to do
    enum MyGrammar : Int, Token {
        //Define a case for each token. Make sure to start at 1
        case word = 1, sentance, punctuation
        
        //Define static variables for non-token creating rules that are used in many 
        //other rules. 
        static let whitespace = CharacterSet.whitespaces.skip(.oneOrMore)
        static let nextWords  = ~[whitespace, MyGrammar.word.rule()].sequence.zeroOrMore
        
        //Define a function that generates a rule for each token
        func rule()->Rule{
            switch self {
            case .word:
                return CharacterSet.letters.token(self, .oneOrMore)
            case .punctuation:
                return [".".scan(),"!".scan(),"?".scan()].token(self)
            case .sentance:
                return [.word.rule(),[nextWords, .punctuation.rule()].choice].token(self)
            }
        }
    }



