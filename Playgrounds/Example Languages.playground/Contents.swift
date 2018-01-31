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

struct Message : Decodable {
    enum Priority : String, Decodable {
        case low = "Low", normal = "Normal", high = "High"
    }
    
    let     subject : String
    let     priority : Priority
    let     body     : String
    
    /// Custom Decoding logic
    public init(from decoder: Decoder) throws{
        let root = try decoder.container(keyedBy: CodingKeys.self).nestedContainer(keyedBy: CodingKeys.self, forKey: .tag)
        
        root.contains(CodingKeys.attributes)
        
        guard let rootTagIdentifier = try? root.decode(String.self, forKey: CodingKeys.identifier), rootTagIdentifier == "message" else {
            fatalError("XML root node should be message")
        }
        let attributes = try root.decode([ParsedXML.Tag.Attribute].self, forKey: .attributes)
        
        subject  = attributes.filter({$0.identifier == "subject"}).first?.value ?? "NO SUBJECT"
        priority = Priority(rawValue:attributes.filter({$0.identifier == "priority"}).first?.value ?? Priority.normal.rawValue) ?? .normal
        let content = try root.decode([ParsedXML.Tag.Content].self, forKey: .content)
        
        func dumpBody(result:String, content:ParsedXML.Tag.Content)->String {
            return result+(content.data ?? content.tag?.content.reduce("", dumpBody) ?? "EMPTY")
        }
        
        body = content.reduce("", dumpBody)
    }
    
    enum CodingKeys: String, CodingKey {
        case tag, identifier, attributes, content, data, value, attribute
    }
}

do {
    let message = try Message.decode(source: xmlSource, using: xmlLanguage)
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
