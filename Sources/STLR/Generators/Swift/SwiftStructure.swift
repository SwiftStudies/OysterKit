//    Copyright (c) 2018, RED When Excited
//    All rights reserved.
//
//    Redistribution and use in source and binary forms, with or without
//    modification, are permitted provided that the following conditions are met:
//
//    * Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
//    * Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
//    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
//    FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//    SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import Foundation
import OysterKit

extension GrammarStructure {
    func swift(to output:TextFile, scope:STLRScope, accessLevel:String){
        for child in structure.children {
            child.swift(to: output, scope: scope, accessLevel: accessLevel)
        }
    }
}

extension _GrammarStructure {
    func swift(to output:TextFile, scope:_STLR, accessLevel:String){
        for child in structure.children {
            child.swift(to: output, scope: scope, accessLevel: accessLevel)
        }
    }
}

fileprivate extension CharacterSet {
    func contains(_ character:Character)->Bool{
        return contains(character.unicodeScalars.first!)
    }
}

fileprivate extension Character {
    var safeVariant : String {
        let map : [Character : String] = ["1":"One","2":"Two","3":"Three","4":"Four","5":"Five","6":"Six","7":"Seven","8":"Eight","9" : "Nine",
                                          "-":"Dash","!":"Ping","|":"Pipe","<":"LessThan",">":"GreaterThan","=":"Equals","@":"at","$":"Dollar",
                                          "#":"Hash","£":"Pound","%":"Percent","^":"Hat","&":"Ampersand","*":"Star",
                                          "(":"OpenRoundBrace",")":"CloseRoundBrace","+":"Plus","~":"Tilde","`":"OpenQuote",":":"Colon",";":"SemiColon",
                                          "\"":"DoubleQuote","'":"SingleQuote","\\":"BackSlash","/":"ForwardSlash","?":"QuestionMark",".":"Period",
                                          ",":"Comma","§":"Snake","±":"PlusOrMinus"," ":"Space","[":"OpenSquareBracket","]":"CloseSquareBracket",
                                          "{":"OpenCurlyBrace","}":"CloseCurlyBrace"
                                          ]
        let safeCharacterSet = CharacterSet.letters.union(CharacterSet.decimalDigits).union(CharacterSet(charactersIn: "_"))
        if safeCharacterSet.contains(self){
            return String(self)
        }
        
        if let mappedCharacter = map[self] {
            return mappedCharacter
        }
        
        return String(self.unicodeScalars.first!.value, radix:16).map({$0.safeVariant}).joined(separator: "")
    }
}

fileprivate extension StringProtocol {
    var caseName : String {
        var remaining = String(self)
        var caseName = ""
        
        let firstCharacter = remaining.removeFirst()
        if firstCharacter == "_" || CharacterSet.letters.contains(firstCharacter){
            caseName += String(firstCharacter)
        } else {
            caseName += firstCharacter.safeVariant.instanceName
        }
        
        while let nextCharacter = remaining.first {
            remaining = String(remaining.dropFirst())
            caseName += nextCharacter.safeVariant
        }
        
        return caseName
    }
}

fileprivate extension GrammarStructure.Node {
    func stringEnum(to output:TextFile, accessLevel:String){
        output.print("","// \(dataType(accessLevel))","\(accessLevel) enum \(dataType(accessLevel)) : Swift.String, Codable {").indent()
        let cases = children.map({
            let caseMatchedString = $0.name.hasPrefix("\"") ? String($0.name.dropFirst().dropLast()) : $0.name
            let caseMatchedName   = caseMatchedString.caseName.propertyName
            if caseMatchedString == caseMatchedName {
                return "\(caseMatchedName)"
            } else {
                return "\(caseMatchedName) = \"\(caseMatchedString)\""
            }
        }).joined(separator: ",")
        output.print("case \(cases)").outdent().print("}")
    }
    
    func swiftEnum(to output:TextFile, scope:STLRScope, accessLevel:String){
        let _ = ""
        if children.reduce(true, {$0 && $1.dataType(accessLevel) == "Swift.String?"}){
            stringEnum(to: output, accessLevel:accessLevel)
            return
        }
        
        output.print("","// \(dataType(accessLevel))","\(accessLevel) enum \(dataType(accessLevel)) : Codable {").indent()
        for child in children {
            output.print("case \(child.name.propertyName)(\(child.name.propertyName):\(child.dataType(accessLevel).dropLast()))")
        }

        output.print("")
        output.print("enum CodingKeys : Swift.String, CodingKey {").indent().print(
            "case \(children.map({$0.name.propertyName}).joined(separator: ","))"
        ).outdent().print(
            "}",
            ""
        )
        
        output.print("\(accessLevel) init(from decoder: Decoder) throws {").indent().print(
            "let container = try decoder.container(keyedBy: CodingKeys.self)",
            ""
        )
        
        children.map({
            let propertyName = $0.name.propertyName
            let dataType = $0.dataType(accessLevel).dropLast()
            return "if let \(propertyName) = try? container.decode(\(dataType).self, forKey: .\(propertyName)){\n\tself = .\(propertyName)(\(propertyName): \(propertyName))\n\treturn\n}"
        }).joined(separator: " else ").split(separator: "\n").forEach({output.print(String($0))})
        
        output.print(
            "throw DecodingError.valueNotFound(Expression.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: \"Tried to decode one of \(children.map({$0.dataType(accessLevel).dropLast()}).joined(separator: ",")) but found none of those types\"))"
        ).outdent().print("}")
        
        output.print("\(accessLevel) func encode(to encoder:Encoder) throws {").indent()
        output.print(
            "var container = encoder.container(keyedBy: CodingKeys.self)",
            "switch self {"
        )
        for child in children {
            output.print("case .\(child.name.propertyName)(let \(child.name.propertyName)):").indent()
            output.print("try container.encode(\(child.name.propertyName), forKey: .\(child.name.propertyName))").outdent()
        }
        output.print("}")
        output.outdent().print("}")

        output.outdent().print("}")
    }
    
    
    func swift(to output:TextFile, scope:STLRScope, accessLevel:String){
        if type != .unknown {
            if children.isEmpty{
                output.print("\(accessLevel) let \(name.propertyName): \(dataType(accessLevel))")
            } else {
                switch type {
                case .structure:
                    output.print(
                        "",
                        "/// \(dataType(accessLevel)) ",
                        "\(accessLevel) \(scope.identifierIsLeftHandRecursive(name) ? "class" : "struct") \(dataType(accessLevel)) : Codable {"
                    )
                case.enumeration:
                    swiftEnum(to: output, scope: scope, accessLevel: accessLevel)
                default:
                    output.print("",dataType(accessLevel))
                }
            }
        } else {
            output.print("\(name): \(dataType(accessLevel)) //\(kind)")
        }
        if type == .typealias ||  type == .enumeration {
            return
        }
        output.indent()
        for child in children {
            child.swift(to: output, scope: scope, accessLevel: accessLevel)
        }
        output.outdent()
        if type == .structure && !children.isEmpty {
            output.print("}")
        }
    }
}

fileprivate extension _GrammarStructure.Node {
    func stringEnum(to output:TextFile, accessLevel:String){
        output.print("","// \(dataType(accessLevel))","\(accessLevel) enum \(dataType(accessLevel)) : Swift.String, Codable {").indent()
        let cases = children.map({
            let caseMatchedString = $0.name.hasPrefix("\"") ? String($0.name.dropFirst().dropLast()) : $0.name
            let caseMatchedName   = caseMatchedString.caseName.propertyName
            if caseMatchedString == caseMatchedName {
                return "\(caseMatchedName)"
            } else {
                return "\(caseMatchedName) = \"\(caseMatchedString)\""
            }
        }).joined(separator: ",")
        output.print("case \(cases)").outdent().print("}")
    }
    
    func swiftEnum(to output:TextFile, scope:_STLR, accessLevel:String){
        let _ = ""
        if children.reduce(true, {$0 && $1.dataType(accessLevel) == "Swift.String?"}){
            stringEnum(to: output, accessLevel:accessLevel)
            return
        }
        
        output.print("","// \(dataType(accessLevel))","\(accessLevel) enum \(dataType(accessLevel)) : Codable {").indent()
        for child in children {
            output.print("case \(child.name.propertyName)(\(child.name.propertyName):\(child.dataType(accessLevel).dropLast()))")
        }
        
        output.print("")
        output.print("enum CodingKeys : Swift.String, CodingKey {").indent().print(
            "case \(children.map({$0.name.propertyName}).joined(separator: ","))"
            ).outdent().print(
                "}",
                ""
        )
        
        output.print("\(accessLevel) init(from decoder: Decoder) throws {").indent().print(
            "let container = try decoder.container(keyedBy: CodingKeys.self)",
            ""
        )
        
        children.map({
            let propertyName = $0.name.propertyName
            let dataType = $0.dataType(accessLevel).dropLast()
            return "if let \(propertyName) = try? container.decode(\(dataType).self, forKey: .\(propertyName)){\n\tself = .\(propertyName)(\(propertyName): \(propertyName))\n\treturn\n}"
        }).joined(separator: " else ").split(separator: "\n").forEach({output.print(String($0))})
        
        output.print(
            "throw DecodingError.valueNotFound(Expression.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: \"Tried to decode one of \(children.map({$0.dataType(accessLevel).dropLast()}).joined(separator: ",")) but found none of those types\"))"
            ).outdent().print("}")
        
        output.print("\(accessLevel) func encode(to encoder:Encoder) throws {").indent()
        output.print(
            "var container = encoder.container(keyedBy: CodingKeys.self)",
            "switch self {"
        )
        for child in children {
            output.print("case .\(child.name.propertyName)(let \(child.name.propertyName)):").indent()
            output.print("try container.encode(\(child.name.propertyName), forKey: .\(child.name.propertyName))").outdent()
        }
        output.print("}")
        output.outdent().print("}")
        
        output.outdent().print("}")
    }
    
    
    func swift(to output:TextFile, scope:_STLR, accessLevel:String){
        if type != .unknown {
            if children.isEmpty{
                output.print("\(accessLevel) let \(name.propertyName): \(dataType(accessLevel))")
            } else {
                switch type {
                case .structure:
                    output.print(
                        "",
                        "/// \(dataType(accessLevel)) ",
                        "\(accessLevel) \(scope.identifierIsLeftHandRecursive(name) ? "class" : "struct") \(dataType(accessLevel)) : Codable {"
                    )
                case.enumeration:
                    swiftEnum(to: output, scope: scope, accessLevel: accessLevel)
                default:
                    output.print("",dataType(accessLevel))
                }
            }
        } else {
            output.print("\(name): \(dataType(accessLevel)) //\(kind)")
        }
        if type == .typealias ||  type == .enumeration {
            return
        }
        output.indent()
        for child in children {
            child.swift(to: output, scope: scope, accessLevel: accessLevel)
        }
        output.outdent()
        if type == .structure && !children.isEmpty {
            output.print("}")
        }
    }
}


fileprivate extension String {
    var propertyName : String {
        let lowerCased : String
        /// If I'm all uppercased, just go all lowercased
        if self.uppercased() == self {
            lowerCased = self.lowercased()
        } else {
            lowerCased =  String(prefix(1).lowercased()+dropFirst())
        }
        
        
        let keywords = ["switch","extension","protocol","in","for","case","if","while","do","catch","func","enum","let","var","struct","class","enum","import","private","fileprivate","internal","public","final","open","typealias","typedef","true","false","return","self","else","default","init","operator","throws","catch"]
        
        if keywords.contains(lowerCased){
            return "`\(lowerCased)`"
        }
        return lowerCased
    }
}

/// Generates a Swift structure that you can use a ParsingDecoder with to rapidly build an AST or IR
public class SwiftStructure : Generator, _Generator {
    
    
    /// Generates a Swift `struct` for the supplied scope that could be used by a `ParsingDecoder`
    ///
    ///  - Parameter scope: The scope to use to generate
    ///  - Returns: A single `TextFile` containing the Swift source
    public static func generate(for scope: STLRScope, grammar name:String, accessLevel:String) throws -> [Operation] {
        let output = TextFile("\(name).swift")
        
        var tokens = scope.swift(grammar: "\(name)Rules")!
        tokens = String(tokens[tokens.range(of: "enum")!.lowerBound...])
        
        // Generate all of the structural elements required for rules
        output.print(
            "import Foundation",
            "import OysterKit",
            "",
            "/// Intermediate Representation of the grammar"
            )

        var lines = tokens.components(separatedBy: CharacterSet.newlines)
        let line = lines.removeFirst()
        
        output.print("fileprivate \(line)")
        for line in lines{
            output.print(line)
        }

        // Now the structure
        let structure = GrammarStructure(for: scope, accessLevel:accessLevel)
        output.print("public struct \(name) : Codable {").indent()
        
        structure.swift(to: output, scope: scope, accessLevel: "public")
        
        for rule in scope.rootRules {
            output.print("\(accessLevel) let \(rule.identifier!.name) : \(rule.identifier!.name.typeName)")
        }
        
        // Generate the code to build the source
        output.print(
            "/**",
            " Parses the supplied string using the generated grammar into a new instance of",
            " the generated data structure",
            "",
            " - Parameter source: The string to parse",
            " - Returns: A new instance of the data-structure",
            " */",
            "\(accessLevel) static func build(_ source : Swift.String) throws ->\(name){").indent().print(
                "let root = HomogenousTree(with: LabelledToken(withLabel: \"root\"), matching: source, children: [try AbstractSyntaxTreeConstructor().build(source, using: \(name)Rules.generatedLanguage)])",
                "// print(root.description)",
                "return try ParsingDecoder().decode(\(name).self, using: root)").outdent().print(
            "}",
            "",
            "\(accessLevel) static let generatedLanguage = \(name)Rules.generatedLanguage"
        )
        
        output.outdent().print("}")
        
        return [output]
    }
    
    /// Generates a Swift `struct` for the supplied scope that could be used by a `ParsingDecoder`
    ///
    ///  - Parameter scope: The scope to use to generate
    ///  - Returns: A single `TextFile` containing the Swift source
    public static func generate(for scope: _STLR, grammar name:String, accessLevel:String) throws -> [Operation] {
        let output = TextFile("\(name).swift")
        
        let tokenFile = TextFile("")
        scope.swift(in: tokenFile)
        var tokens = tokenFile.content
        tokens = String(tokens[tokens.range(of: "enum")!.lowerBound...])
        
        // Generate all of the structural elements required for rules
        output.print(
            "import Foundation",
            "import OysterKit",
            "",
            "/// Intermediate Representation of the grammar"
        )
        
        var lines = tokens.components(separatedBy: CharacterSet.newlines)
        let line = lines.removeFirst()
        
        output.print("fileprivate \(line)")
        for line in lines{
            output.print(line)
        }
        
        // Now the structure
        let structure = _GrammarStructure(for: scope, accessLevel:accessLevel)
        output.print("public struct \(name) : Codable {").indent()
        
        structure.swift(to: output, scope: scope, accessLevel: "public")
        
        for rule in scope.grammar.rules.filter({scope.grammar.isRoot(identifier: $0.identifier)}) {
            output.print("\(accessLevel) let \(rule.identifier) : \(rule.identifier.typeName)")
        }
        
        // Generate the code to build the source
        output.print(
            "/**",
            " Parses the supplied string using the generated grammar into a new instance of",
            " the generated data structure",
            "",
            " - Parameter source: The string to parse",
            " - Returns: A new instance of the data-structure",
            " */",
            "\(accessLevel) static func build(_ source : Swift.String) throws ->\(name){").indent().print(
                "let root = HomogenousTree(with: LabelledToken(withLabel: \"root\"), matching: source, children: [try AbstractSyntaxTreeConstructor().build(source, using: \(name)Rules.generatedLanguage)])",
                "// print(root.description)",
                "return try ParsingDecoder().decode(\(name).self, using: root)").outdent().print(
                    "}",
                    "",
                    "\(accessLevel) static let generatedLanguage = \(name)Rules.generatedLanguage"
        )
        
        output.outdent().print("}")
        
        return [output]
    }

}

internal extension String {
    var fieldName : String {
        let swiftKeywords = ["import"]
        
        if swiftKeywords.contains(self){
            return "`\(self)`"
        }
        return self
    }
    var typeName : String {
        return prefix(1).uppercased() + dropFirst()
    }

    var instanceName : String {
        return prefix(1).lowercased() + dropFirst()
    }

    
    func arrayElement(`is` type:String)->Bool{
        guard hasPrefix("[") else {
            return false
        }
        return self.dropFirst().dropLast() == type
    }
}



