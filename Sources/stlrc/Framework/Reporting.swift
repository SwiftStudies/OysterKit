//
//  Reporting.swift
//  stlrc
//
//  Created on 17/06/2018.
//

import Foundation

fileprivate extension Character {
    var isNewline : Bool {
        return CharacterSet.newlines.contains(unicodeScalars.first!)
    }
}

struct TextFileReference {
    let line      : Int
    let character : Int
    let prefix      : String
    let body        : String
    let suffix      : String
    
    init(of range:Range<String.Index>, in string:String){
        let prefix : String
        
        if range.lowerBound < string.endIndex {
            prefix = String(string[string.startIndex...range.lowerBound])
        } else {
            prefix = String(string[string.startIndex..<range.lowerBound])
        }
        self.line = prefix.filter({CharacterSet.newlines.contains($0.unicodeScalars.first!)}).count + 1
        
        var marker    = range.lowerBound < string.endIndex ? range.lowerBound : string.index(before: range.lowerBound)
        
        while marker != string.startIndex && !string[marker].isNewline{
            marker = string.index(before: marker)
        }
        self.character = string.distance(from: marker, to: range.lowerBound)+1
        
        var endMarker    = range.upperBound
        while endMarker != string.endIndex && !string[endMarker].isNewline{
            endMarker = string.index(after: endMarker)
        }
        
        self.prefix  = String(string[marker..<range.lowerBound]).trimmingCharacters(in: CharacterSet.newlines)
        self.body = String(string[range.lowerBound..<range.upperBound])
        self.suffix    = String(string[range.upperBound..<endMarker]).trimmingCharacters(in: CharacterSet.newlines)
        
    }
    
    func report(_ message:String, file:String? = nil)->String{
        return "[\(file == nil ? "" : "\(file!) ")\(line):\(character)] \(message):\n\t\(prefix)\(body.style(.inverse))\(suffix)"
    }
    
}
