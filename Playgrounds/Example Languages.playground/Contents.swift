//: Playground - noun: a place where people can play

import Foundation
import STLR
import OysterKit

guard let source = try? String(contentsOfFile: "/Volumes/Personal/SPM/OysterKit/Sources/ExampleLanguages/Grammars/XML.stlr") else {
    print("Could not load grammar")
    exit(0)
}


let stlrParser = STLRParser.init(source: source)

stlrParser.grammar[0].produces


let ast : DefaultHeterogeneousAST = stlrParser.ast.runtimeLanguage!.build(source: "<hello attr='eh>world</hello>")

for error in ast.errors {
    print(" - \(error)")
}

ast.errors

//print(stlrParser.ast.swift(grammar: "XMLTest")!)
