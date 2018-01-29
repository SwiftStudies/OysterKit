//: Playground - noun: a place where people can play

import Foundation
import STLR
import OysterKit

guard let source = try? String(contentsOfFile: "/Volumes/Personal/SPM/XMLDecoder/XML.stlr") else {
    print("Could not load grammar")
    exit(0)
}


let stlrParser = STLRParser.init(source: source)

let tree = AbstractSyntaxTree<HomogenousTree>(with: "<hello><world>Again</world></hello>").parse(using: stlrParser.ast.runtimeLanguage!)

print(tree?.description ?? "Failed")

//print(stlrParser.ast.swift(grammar: "XMLTest")!)

//tree.children[0].children[0]
