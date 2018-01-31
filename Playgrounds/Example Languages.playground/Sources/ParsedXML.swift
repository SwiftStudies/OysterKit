import Foundation

public struct ParsedXML : Decodable {
    public struct Tag : Decodable {
        public struct Attribute : Decodable {
            let identifier : String
            let value : String?
        }
        public struct Content : Decodable {
            let data : String?
            let tag  : Tag?
        }
        public let identifier : String
        public let attributes : [Attribute]
        public let content    : [Content]
    }
    
    public let tag : Tag
}
