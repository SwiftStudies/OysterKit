//: Playground - noun: a place where people can play

import Foundation
import STLR
import OysterKit

guard let source = try? String(contentsOfFile: "/Volumes/Personal/SPM/XMLDecoder/XML.stlr") else {
    print("Could not load grammar")
    exit(0)
}


let stlrParser = STLRParser.init(source: source)

let tree = HomogenousAbstractSyntaxTreeConstructor(with: "<hello><world>Again</world></hello>").parse(using: stlrParser.ast.runtimeLanguage!)

print(tree?.description ?? "Failed")

class XTest : Decodable {
    let openTag : String
    let nestingTag : XTest?
    let data : String?
}

guard let xml = try? XTest.parse(source: "<hello><world>Again</world></hello>", using: stlrParser.ast.runtimeLanguage!) else {
    fatalError("Could not parse as XML")
}

xml.openTag
xml.nestingTag!.openTag
xml.nestingTag!.data


//print(stlrParser.ast.swift(grammar: "XMLTest")!)

//tree.children[0].children[0]
