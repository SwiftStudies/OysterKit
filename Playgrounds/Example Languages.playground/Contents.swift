//: Playground - noun: a place where people can play

import Foundation
import STLR
import OysterKit

print("Hello")

guard let grammarSource = try? String(contentsOfFile: "/Volumes/Personal/SPM/XMLDecoder/XML.stlr") else {
    fatalError("Could not load grammar")
}

guard let xmlLanguage = STLRParser.init(source: grammarSource).ast.runtimeLanguage else {
    fatalError("Could not create language")
}

let xmlSource = """
<message subject='Hello, OysterKit!' priority="High">
    It's really <i>good</i> to meet you,
    <p />
    I hope you are settling in OK, let me know if you need anything.
    <p />
    Phatom Testers
</message>
"""

let tree = try? AbstractSyntaxTreeConstructor().build(xmlSource, using: xmlLanguage)

print(tree?.description ?? "Failed")

struct ParsedXML : Decodable {
    struct Tag : Decodable {
        struct Attribute : Decodable {
            let identifier : String
            let value : String?
        }
        struct Content : Decodable {
            let data : String?
            let tag  : Tag?
        }
        let identifier : String
        let attributes : [Attribute]
        let content    : [Content]
    }
    
    let tag : Tag
}

let parsedXML = try? ParsedXML.decode(source: xmlSource, using: xmlLanguage)
