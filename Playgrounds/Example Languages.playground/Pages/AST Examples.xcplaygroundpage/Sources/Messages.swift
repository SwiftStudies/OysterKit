import Foundation

public struct Message : Decodable {
    public enum Priority : String, Decodable {
        case low = "Low", normal = "Normal", high = "High"
    }
    
    public let     subject : String
    public let     priority : Priority
    public let     body     : String
    
    /// Custom Decoding logic
    public init(from decoder: Decoder) throws{
        let root = try decoder.container(keyedBy: CodingKeys.self).nestedContainer(keyedBy: CodingKeys.self, forKey: .tag)
        
        let _  = root.contains(CodingKeys.attributes)
        
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
