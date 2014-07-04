//
//  main.swift
//  Hello World
//
//  Copyright (c) 2014 Swift Studies. All rights reserved.
//

import OysterKit

var tokenizer = Tokenizer()

tokenizer.branch(
    OysterKit.whiteSpaces,
    OysterKit.punctuation,
    OysterKit.word,
    OysterKit.eot
)

tokenizer.tokenize("Hello, World!"){(token:Token)->Bool in
    println(token.description())
    return true
}

let testStrings = [
    "1.5" : "float",
    "1" : "integer",
    "-1" : "integer",
    "+1" : "integer",
    "+10" : "integer",
    "1.5e10" : "float",
    "-1.5e10": "float",
    "-1.5e-10": "float",
]

for (number:String,token:String) in testStrings{
    //            dump(tokenizer, number)
    println("Testing with "+number)
    let newTokenizer = Tokenizer(states: [
        OysterKit.number,
        OysterKit.eot
        ])
    var tokens:Array<Token> = newTokenizer.tokenize(number)
    
    let actualToken:Token = tokens[0]
    println(actualToken.description())
}


