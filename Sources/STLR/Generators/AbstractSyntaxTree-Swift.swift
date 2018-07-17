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
        
        var tokens = scope.swift(grammar: "IRTokens")!
        tokens = String(tokens[tokens.range(of: "enum")!.lowerBound...])
        
        // Generate all of the structural elements required for rules
        output.print(
            "import Foundation",
            "import OysterKit",
            "",
            tokens,
            "",
            "/// Intermediate Representation of the grammar",
            "struct IR : Decodable {"
            ).indent()
        for rule in scope.rules {
            if let identifier = rule.identifier {
                generate(identifier: identifier, in: scope, to: output)
            }
        }
        

        
        // Generate the fields that make up the results of the parser
        output.print("")
        for identifier in scope.rootRules.compactMap({$0.identifier}) {
            output.print(
                "/// Root structure",
                "let \(identifier.name) : \(identifier.name.typeName)"
            )
        }
        output.print("")
        
        // Generate the code to build the source
        output.print(
            "/**",
            " Parses the supplied string using the generated grammar into a new instance of",
            " the generated data structure",
            "",
            " - Parameter source: The string to parse",
            " - Returns: A new instance of the data-structure",
            " */",
            "static func build(_ source : Swift.String) throws ->IR  {").indent().print(
                "let root = HomogenousTree(with: LabelledToken(withLabel: \"root\"), matching: source, children: [try AbstractSyntaxTreeConstructor().build(source, using: IRTokens.generatedLanguage)])",
                "print(root.description)",
                "return try ParsingDecoder().decode(IR.self, using: root)").outdent().print(
            "}"
        )
        
        output.outdent().print("}")
        
        return [output]
    }
    
    private static func generate(identifier:STLRScope.Identifier, in scope:STLRScope, to output:TextFile){
        guard identifier.isStructural, let expression = identifier.grammarRule?.expression else {
            return
        }

        output.print(
            "/// \(identifier.name.typeName)"
        )

        if let aliasedType = identifier.typeAlias {
            output.print("typealias \(identifier.name.typeName) = \(aliasedType)")
        } else {
            let typeType = identifier.grammarRule?.leftHandRecursive ?? false ? "class" : "struct"
            
            output.print(
                "\(typeType) \(identifier.name.typeName) : Decodable {").indent()
            for field in generate(expression: expression).consolidate() {
                output.print(
                    "let \(field.name) : \(field.type)"
                )
            }
            output.outdent().print("}")
        }
        
    }
    
    fileprivate static func generate(expression:STLRScope.Expression)->[Field]{
        switch expression {
        case .element(let element):
            if let fields = generate(element: element){
                return fields
            }
        case .choice(let elements):
            var fields = [Field]()
            for element in elements {
                fields.append(contentsOf: generate(element: element) ?? [])
            }
            return fields.optional
        case .sequence(let elements):
            var fields = [Field]()
            for element in elements {
                fields.append(contentsOf: generate(element: element) ?? [])
            }
            return fields
        case .group:
            return []
        }
        
        return []
    }
    
    private static var structuralIdentifiers = [String:Bool]()
    private static var identiferStack = [String]()
    
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
        
        if identiferStack.contains(identifier.name){
            return true
        }
        
        identiferStack.append(identifier.name)
        let fields = SwiftStructure.generate(expression: expression)
        identiferStack.removeLast()
        if fields.count == 0 {
            structuralIdentifiers[identifier.name] = false
            return false
        }
        
        structuralIdentifiers[identifier.name] = true
        return true
    }
    
    private static func generate(element:STLRScope.Element)->[Field]?{
        guard element.isStructural else {
            return nil
        }
        
        let fields : [Field]?
        
        switch element{
        case .terminal(_, _, _, let annotations):
            if let token = annotations.asRuleAnnotations[.token]?.description {
                fields = [Field(name: token, type: token.typeName)]
            } else {
                fields = nil
            }
        case .identifier(let identifier, _, _, let annotations):
            if identifier.isDiscarded {
                return nil
            }
            let token = annotations.asRuleAnnotations[.token]?.description ?? identifier.name
            if !identifier.isStructural {
                fields = [Field(name: token, type: "Swift.String")]
            } else {
                fields = [Field(name: token, type: token.typeName)]
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

            fields = generate(expression: expression)
        }
        
        if let fields = fields {
            switch element.modifier {
            case .one:
                return fields
            case .zeroOrOne:
                return fields.map({$0.optional})
            case .zeroOrMore, .oneOrMore:
                return fields.map({$0.array})
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

fileprivate extension STLRScope.Identifier {
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
    
    var typeAlias : String? {
        return grammarRule?.expression?.typeAlias
    }
}

fileprivate extension STLRScope.Expression {
    var typeAlias : String? {
        switch self {
        case .element(let element):
            switch element {
            case .group(let expression, let modifier, let lookahead, let annotations):
                if lookahead {
                    return nil
                }
                if annotations.asRuleAnnotations[.void] == .set || annotations.asRuleAnnotations[.transient] == .set {
                    return nil
                }
                
                guard let typeAlias = expression.typeAlias else {
                    return nil
                }
                
                switch modifier {
                case .one:
                    return typeAlias
                case .zeroOrOne:
                    return typeAlias.hasSuffix("?") ? typeAlias :  typeAlias+"?"
                case .zeroOrMore:
                    return "[\(typeAlias)]?"
                case .oneOrMore:
                    return "[\(typeAlias)]"
                default:
                    return nil
                }
            case .identifier(let identifier, let modifier, let lookahead, let annotations):
                if lookahead {
                    return nil
                }
                if annotations.asRuleAnnotations[.void] == .set || annotations.asRuleAnnotations[.transient] == .set {
                    return nil
                }
                switch modifier {
                case .one:
                    return identifier.name.typeName
                case .zeroOrOne:
                    return identifier.name.typeName+"?"
                case .zeroOrMore:
                    return "[\(identifier.name.typeName)]?"
                case .oneOrMore:
                    return "[\(identifier.name.typeName)]"
                default:
                    return nil
                }
            default:
                return nil
            }
        case .sequence(_):
            return nil
        case .choice(_):
            return nil
        case .group:
            return nil
        }        
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
                if existingType == field.type || field.type.arrayElement(is: existingType){
                    existingFields[field.name] = "[\(existingType)]"
                } else if existingType.arrayElement(is: field.type){
                    //Do nothing, it will work fine
                } else {
                    fatalError("There are multiple fields with the same name (\(field.name)) but different types:\n\t\(field.type)\n\t\(existingType)\nCannot generate structure")
                }
            } else {
                existingFields[field.name] = field.type
            }
        }

        return existingFields.map({SwiftStructure.Field(name: $0, type: $1)})
    }
    
    var optional : [Element] {
        return map({$0.optional})
    }
}
