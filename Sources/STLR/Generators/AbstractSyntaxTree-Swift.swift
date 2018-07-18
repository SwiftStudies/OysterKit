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

/// Generates a Swift structure that you can use a ParsingDecoder with to rapidly build an AST or IR
public class SwiftStructure : Generator {
    
    
    /// Generates a Swift `struct` for the supplied scope that could be used by a `ParsingDecoder`
    ///
    ///  - Parameter scope: The scope to use to generate
    ///  - Returns: A single `TextFile` containing the Swift source
    public static func generate(for scope: STLRScope, grammar name:String) throws -> [TextFile] {
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
        let structure = StructureGenerator(for: scope)

        var lines = tokens.components(separatedBy: CharacterSet.newlines)
        let line = lines.removeFirst()
        
        output.print("fileprivate \(line)")
        for line in lines{
            output.print(line)
        }

        
        output.print("struct \(name) : Codable {").indent()
        
        
        structure.dump(to: output, scope: scope)
        
        for rule in scope.rootRules {
            output.print("let \(rule.identifier!.name) : \(rule.identifier!.name.typeName)")
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
            "static func build(_ source : Swift.String) throws ->\(name){").indent().print(
                "let root = HomogenousTree(with: LabelledToken(withLabel: \"root\"), matching: source, children: [try AbstractSyntaxTreeConstructor().build(source, using: \(name)Rules.generatedLanguage)])",
                "print(root.description)",
                "return try ParsingDecoder().decode(\(name).self, using: root)").outdent().print(
            "}"
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
    
    func arrayElement(`is` type:String)->Bool{
        guard hasPrefix("[") else {
            return false
        }
        return self.dropFirst().dropLast() == type
    }
}



