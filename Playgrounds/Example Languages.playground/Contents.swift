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
<message subject='Hello, OysterKit!' priority="High">
    It's really <i>good</i> to meet you,
    <p />
    I hope you are settling in OK, let me know if you need anything.
    <p />
    Phatom Testers
</message>
"""

enum Tokens : Int {
    case value
}

let csvSource = "a,bb,ccc,dddd"

for streamedToken in TokenStream(csvSource, using: STLRParser(source:"value = !\",\"+ \",\"?").ast.runtimeLanguage!){
    print("Got \(streamedToken.token)='\(csvSource[streamedToken.range])'")
}

let tree = try? AbstractSyntaxTreeConstructor().build("<message>DataData</message>", using: xmlLanguage)

print(tree?.description ?? "Failed")



let parsedXML = try? ParsedXML.decode(xmlSource, using: xmlLanguage)

do {
    let message = try Message.decode(xmlSource, using: xmlLanguage)
} catch AbstractSyntaxTreeConstructor.ConstructionError.parsingFailed(let errors) {
    print("\(errors.count) errors constructing")
    errors.forEach({print($0.localizedDescription)})
} catch AbstractSyntaxTreeConstructor.ConstructionError.constructionFailed(let errors) {
    print("\(errors.count) errors parsing")
    errors.forEach({print($0.localizedDescription)})
} catch {
    print(error.localizedDescription)
}

"Hello"
