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

Terminals are specific characters or sequences of characters, such as a string. String are simply defined by wrapping the desired text in quotations marks, eg: `"http:"`. 

If you wish to include special characters, or indeed a quotation mark, you can insert escaped characters using the backslash. At this point the following escapes are supported: 

  - `\"` A quotation mark "
  - `\r` A carrige return
  - `\n` A new line
  - `\t` A tab

More will be added in the future. 

You can also use predefined character sets that match multiple characters. These are prefixed by a `.` and followed by the character set name. The following character sets are available at the moment:

  - `.decimalDigits` All decimal digits from 0 to 9
  - `.letters` All letters 
  - `.uppercaseLetters` All uppercase letters
  - `.lowercaseLetters` All lowercase letters
  - `.alphaNumerics` All letters and digits
  - `.whitespaces` All whitespaces. For example tabs and spaces. 
  - `.newlines` All newline characters, matching for example both newline and carriage return
  - `.whitespacesAndNewlines` All white space and newline characters
  
For example, a rule to capture a co-ordinate might be

    coord = .decimalDigits "," .decimalDigits
    
This would match `3,4` for example. 

### Identifiers 

We can also reference other tokens in a sequence or choice by using their identifier (or name). For example we might define a token for our different web protocols earlier and use it in a rule for a URL. 

    protocol = "http" | "https"
    url      = protocol "://" //I'll finish this later
    
When matching with `url` the rule will first evaluate the `protocol` rule and then if matched continue through the sequence. This allows complex rules to be built up. 

STLR fully supports left-hand recursion, meaning a rule can refer directly or indirectly to itself. However you should be aware that you must always advance the scanner position before doing so (otherwise you will enter an infinite loop). 

## Modifiers

We often want to change how an element is matched. For example repeating it, or just checking it is there without advancing the scanner position (lookahead). The following modifiers are available before or after any element (terminal, group, or identifier). 

  - `?` Optional (0 or 1 instances of the element): This might be used to simplify our protocol rule for example `protocol = "http" "s"?`. This is much closer to how we think about it, `http` followed optionally by an `s`. It is added as a suffic to the element. 
  - `*` Optional repeated (0 or any number of instances of the element): This is used when an element does not have to be there, but any number of them will be greedly consumed during matching. It is added as a suffic to the element. 
  - `+` Required repeated (1 or any number of instances of the element): This is used when an element MUST exist, and then once one has been matched, any number of subsequence instances will be greedily consumed. It is added as a suffic to the element. 
  - `!` Not: This is used to invert the match and is prefixed to the element and can be combined with any of the suffix operators. For example to scan until a newline we could specify `!.newlines*`. This would scan up to, but not including, the first newline character found
  - `>>` Look ahead: This is used when you want to lookahead (for example, skip the next three characters, but check the fourth). It is prefixed to the element and like the not modifier can be combined with any suffix modifier. Regardless of matching or failure the scanner position will not be changed. However the sequence will only continue to be evaluated if it is met. 
  
