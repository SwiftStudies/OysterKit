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
    
    private struct Field {
        let name : String
        let type : String
        
        var optional : Field {
            if type.hasSuffix("?") {
                return self
            }
            return Field(name: name, type: type+"?")
        }
    }
    
    /// Generates a Swift `struct` for the supplied scope that could be used by a `ParsingDecoder`
    ///
    ///  - Parameter scope: The scope to use to generate
    ///  - Returns: A single `TextFile` containing the Swift source
    public static func generate(for scope: STLRScope) throws -> [TextFile] {
        let output = TextFile("IR.swift")
        
        // Generate all of the structural elements required for rules
        output.print(
            "/// Intermediate Representation of the grammar",
            "struct IR {").indent()
        for rule in scope.rules {
            if let identifier = rule.identifier {
                generate(identifier: identifier, in: scope, to: output)
            }
        }
        
        // Generate the fields that make up the results of the parser
        for identifier in scope.rootRules.compactMap({$0.identifier}) {
            output.print(
                "/// Structure",
                "let \(identifier.name) : \(identifier.name.typeName)"
            )
        }
        
        output.outdent().print("}")
        
        return [output]
    }
    
    private static func generate(identifier:STLRScope.Identifier, in scope:STLRScope, to output:TextFile){
        guard let expression = identifier.grammarRule?.expression, !expression.scannable else {
            return
        }
        
        if expression.scannable{
            return
        }
        
        output.print(
            "/// \(identifier.name.typeName)",
            "struct \(identifier.name.typeName){").indent()
        for field in generate(expression: expression, in: scope) {
            output.print(
                "let \(field.name) : \(field.type)"
            )
        }
        output.outdent().print("}")
    }
    
    private static func generate(expression:STLRScope.Expression, in scope:STLRScope)->[Field]{
        switch expression {
        case .element(let element):
            if let field = generate(element: element, in: scope){
                return [field]
            }
        case .choice(let elements):
            return elements.compactMap { (element) -> Field? in
                generate(element: element, in: scope)?.optional
            }
        default:
            return []
        }
        
        return []
    }
    
    private static func generate(element:STLRScope.Element, in scope:STLRScope)->Field?{
        guard !element.lookahead else {
            return nil
        }
        
        switch element{
        case .terminal(_, let modifier, _, let annotations):
            if let token = annotations.asRuleAnnotations[.token]?.description {
                return Field(name: token, type: token.typeName)
            }
        case .identifier(let identifier, let modifier, let lookahead, let annotations):
            let token = annotations.asRuleAnnotations[.token]?.description ?? identifier.name
            if identifier.grammarRule?.expression?.scannable ?? true {
                return Field(name: token, type: "String")
            } else {
                return Field(name: token, type: token.typeName)
            }
        default:
            return nil
        }
        
        return nil
    }
}

private extension String {
    var typeName : String {
        return prefix(1).uppercased() + dropFirst()
    }
}
