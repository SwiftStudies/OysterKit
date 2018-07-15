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
    
    fileprivate struct Field {
        let name : String
        let type : String
        
        init(name:String, type:String) {
            self.name = name.fieldName
            self.type = type
        }
        
        var optional : Field {
            if type.hasSuffix("?") {
                return self
            }
            return Field(name: name, type: type+"?")
        }
        
        var array : Field {
            if type.hasPrefix("["){
                return self
            }
            return Field(name: name, type: "[\(type)]")
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
            "import Foundation",
            "",
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
        guard identifier.isStructural, let expression = identifier.grammarRule?.expression else {
            return
        }
        
        output.print(
            "/// \(identifier.name.typeName)",
            "struct \(identifier.name.typeName) : Decodable {").indent()
        for field in generate(expression: expression).consolidate() {
            output.print(
                "let \(field.name) : \(field.type)"
            )
        }
        output.outdent().print("}")
    }
    
    fileprivate static func generate(expression:STLRScope.Expression)->[Field]{
        switch expression {
        case .element(let element):
            if let field = generate(element: element){
                return [field]
            }
        case .choice(let elements):
            return elements.compactMap { (element) -> Field? in
                generate(element: element)?.optional
            }
        case .sequence(let elements):
            return elements.compactMap { (element) -> Field? in
                generate(element: element)
            }
        case .group:
            return []
        }
        
        return []
    }
    
    private static var structuralIdentifiers = [String:Bool]()
    
    fileprivate static func isStructural(identifier: STLRScope.Identifier)->Bool{
        if let existingAnswer = structuralIdentifiers[identifier.name] {
            return existingAnswer
        }
        
        guard let expression = identifier.grammarRule?.expression else {
            structuralIdentifiers[identifier.name] = false
            return false
        }
        
        if identifier.isDiscarded {
            structuralIdentifiers[identifier.name] = false
            return false
        }
        
        let fields = SwiftStructure.generate(expression: expression)
        if fields.count == 0 {
            structuralIdentifiers[identifier.name] = false
            return false
        }
        
        structuralIdentifiers[identifier.name] = true
        return true
    }
    
    private static func generate(element:STLRScope.Element)->Field?{
        guard element.isStructural else {
            return nil
        }
        
        let field : Field?
        
        switch element{
        case .terminal(_, _, _, let annotations):
            if let token = annotations.asRuleAnnotations[.token]?.description {
                field = Field(name: token, type: token.typeName)
            } else {
                field = nil
            }
        case .identifier(let identifier, _, _, let annotations):
            if identifier.isDiscarded {
                return nil
            }
            let token = annotations.asRuleAnnotations[.token]?.description ?? identifier.name
            if !identifier.isStructural {
                field = Field(name: token, type: "Swift.String")
            } else {
                field = Field(name: token, type: token.typeName)
            }
        case .group(let expression, let modifier, let lookahead, let annotations):
            if lookahead {
                return nil
            }
            if annotations.asRuleAnnotations[.void] == .set || annotations.asRuleAnnotations[.transient] == .set {
                return nil
            }
            if modifier == .transient || modifier == .void || modifier == .not{
                return nil
            }

            let fields = generate(expression: expression)
            
            return fields.first
        }
        
        if let field = field {
            switch element.modifier {
            case .one:
                return field
            case .zeroOrOne:
                return field.optional
            case .zeroOrMore, .oneOrMore:
                return field.array
            case .not:
                return nil
            case .void:
                return nil
            case .transient:
                return nil
            }
        }
        
        return nil
    }
}

private extension STLRScope.Element {
    var annotations : RuleAnnotations {
        switch self {
        case .terminal(_, _, _, let annotations):
            return annotations.asRuleAnnotations
        case .identifier(_, _, _, let annotations):
            return annotations.asRuleAnnotations
        case .group(_, _, _, let annotations):
            return annotations.asRuleAnnotations
        }
    }
    
    var modifier : STLRScope.Modifier {
        switch self {
        case .terminal(_, let quantifier, _, _):
            return quantifier
        case .identifier(_, let quantifier, _, _):
            return quantifier
        case .group(_, let quantifier, _, _):
            return quantifier
        }
    }
    
    var isStructural : Bool {
        if lookahead {
            return false
        }
        
        if annotations[RuleAnnotation.transient] == .set || annotations[RuleAnnotation.void] == .set {
            return false
        }
        
        switch self {
        case .terminal(_, _, _, _):
            return false
        case .identifier(_, _, _, let annotations):
            if annotations.asRuleAnnotations[RuleAnnotation.transient] == .set || annotations.asRuleAnnotations[RuleAnnotation.void] == .set {
                return false
            }
            return true
        case .group(_, _, _, let annotations):
            if annotations.asRuleAnnotations[RuleAnnotation.transient] == .set || annotations.asRuleAnnotations[RuleAnnotation.void] == .set {
                return false
            }
            return true
        }
    }
}

//private extension STLRScope.Expression {
//    var isStructural : Bool {
//        switch self {
//        case .element(let element):
//            return element.isStructural
//        case .sequence(let elements):
//            return elements.compactMap({$0.isStructural ? $0 : nil}).count > 0
//        case .choice(let elements):
//            return elements.compactMap({$0.isStructural ? $0 : nil}).count > 0
//        case .group:
//            return false
//        }
//    }
//}

private extension STLRScope.Identifier {
    var isDiscarded : Bool {
        let annotations = self.annotations.asRuleAnnotations
        if annotations[RuleAnnotation.void] == .set || annotations[RuleAnnotation.transient] == .set{
            return true
        }
        return false
    }
    var isStructural : Bool {
        return SwiftStructure.isStructural(identifier: self)
    }
}

private extension String {
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

fileprivate extension Array where Element == SwiftStructure.Field {
    fileprivate func consolidate()->[Element]{
        var existingFields = [String : String]()

        for field in self {
            if let existingType = existingFields[field.name] {
                if existingType == field.type {
                    existingFields[field.name] = "[\(existingType)]"
                } else if existingType.arrayElement(is: field.type){
                    //Do nothing, it will work fine
                } else {
                    fatalError("There are multiple fields with the same name (\(field.name)) but different types (\(field.type), and \(existingType). Cannot generate structure")
                }
            } else {
                existingFields[field.name] = field.type
            }
        }

        return existingFields.map({SwiftStructure.Field(name: $0, type: $1)})
    }
}
