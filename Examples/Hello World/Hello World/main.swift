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

