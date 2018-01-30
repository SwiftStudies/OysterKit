//: Playground - noun: a place where people can play

import Foundation
import STLR
import OysterKit



guard let grammarSource = try? String(contentsOfFile: "/Volumes/Personal/SPM/XMLDecoder/XML.stlr") else {
    fatalError("Could not load grammar")
}

guard let xmlLanguage = STLRParser.init(source: grammarSource).ast.runtimeLanguage else {
    fatalError("Could not create language")
}

let xmlSource = """
<hello attribute='test'>
    <world attribute='test' another-attribute='test2'>
        Again
    </world>
</hello>
"""

let tree = HomogenousAbstractSyntaxTreeConstructor(with: xmlSource).parse(using: xmlLanguage)

print(tree?.description ?? "Failed")

class XTest : Decodable {
    let openTag : String
    let nestingTag : XTest?
    let data : String?
}

//guard let xml = try? XTest.parse(source: xmlSource, using: xmlLanguage) else {
//    fatalError("Could not parse as XML")
//}

//xml.openTag
//xml.nestingTag!.openTag
//xml.nestingTag!.data


//print(stlrParser.ast.swift(grammar: "XMLTest")!)

//tree.children[0].children[0]

