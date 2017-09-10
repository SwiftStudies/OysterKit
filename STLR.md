# STLR - A Native Swift Lexer and Parser Generation Language

OysterKit provides a framework for lexical analysis and parsing the resultant tokens into an intermediate representation (such as an Abstract Syntax Tree, or a stream of validated tokens). STLR builds on this by providing a language that can be used to create parsers using the OysterKit framework. This can be done by loading and "compiling" files or to directly create rules from strings in your code. 

Once compiled (in memory) STLR can then create a parser directly in memory, or generate Swift source code to capture the language you have defined. 

## Defining a rule in STLR

Rules can be defined very simply 

_token-identifier_ = _expression_

For example, if we wanted to define a simple token `digit` that was any decimal digit (there are much more efficient ways of doing this using STLR, but this is given as an illustrative example). 

    digit = "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" 
    
A token, `digit` is defined as being any one of the strings separated by the `|` character. We can also define sequences, very simply. This token can then be refrenced by another token definition. For example, 

    threeDigitNumber = digit digit digit
    
When STLR compiles this it creates a rule for each token. 

## Expressions 

Expressions are made up of elements and other expressions. Elements can be terminals, groups, or identifiers and can have one or more modifiers that alter the meaning of the element (such as `!` or not) or the number of the element that is expected (for example `+` means one or more). 

We'll start by looking at groups, as these are the most fundamental elements.

### Groups
Groups are composed as a sequence or choice of other elements. For example 

     "http" ":" "//"
     
Captures a sequence of strings (or terminals) that would match `http://`. If we wanted to specify this as a choice we would use the or operator `|`.

    "a" | "b" | "c"
    
Would match `a` or `b` or `c` in a string. When you wish to combine these two group types, you may use brackets to do so. For example we might refine our first sequence to match either `http` or `https` by nesting a choice at the start of the group. 

    ("http" | "https") ":" "//"
   
 Would match either `http://` or `https://` 
 
 ### Terminals



