//    Copyright (c) 2016, RED When Excited
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

public typealias Scope = STLR

public class GrammarStructure {
    /// The cardinality of the node, with fundamentally four values
    /// optional (0 or 1), one, or many (optional or not)
    public enum Cardinality {
        case none,optional, one, many(Bool)
        
        init(element:STLR.Element, referencing rule:Scope.Rule?){
            let notStructural = element.token == nil && ((element.isVoid || element.isTransient) || (rule?.isVoid ?? false || rule?.isTransient ?? false))
            
            if notStructural || element.isLookahead{
                self = .none
            } else if element.isNegated || element.cardinality == .one{
                self = .one
            } else if element.cardinality == .optionally {
                self = .optional
            } else if element.cardinality == .noneOrMore {
                self = .many(true)
            } else {
                self = .many(false)
            }
        }
        
        var optional : Bool {
            switch self {
            case .none:
                return true // I mean... it might not be there :-/
            case .optional:
                return true
            case .one:
                return false
            case .many(let optional):
                return optional
            }
        }
        
        var many : Bool {
            switch self {
            case .optional, .one, .none:
                return false
            case .many(_):
                return true
            }
        }
        
        init(optional:Bool, many:Bool){
            if many {
                self = .many(optional)
            } else if optional{
                self = .optional
            } else {
                self = .one
            }
        }
        
        func merge(with incoming:Cardinality)->Cardinality{
            return Cardinality(optional: optional || incoming.optional, many: many || incoming.many)
        }
        
    }
    
    /// The nature of the node.
    public enum Kind {
        case transient, void, pinned, structural, lookahead
        
        init(rule:STLR.Rule){

            if rule.annotations?[.pinned] != nil {
                self = .pinned
            } else if rule.isVoid {
                self = .void
            } else if rule.isTransient {
                self = .transient
            } else {
                self = .structural
            }
        }
        
        init(element:STLR.Element, referencing rule:Scope.Rule?, defaultValue:Kind){
            if element.isLookahead {
                self = .lookahead
            } else if element.isVoid {
                self = .void
            } else if case Behaviour.Kind.structural = element.kind { //Should this be token???
                if rule?.isVoid ?? false {
                    self = .void
                } else if rule?.isTransient ?? false{
                    self = .transient
                } else {
                    self = .structural
                }
            } else if element.isTransient {
                self = .transient
            } else {
                self = defaultValue
            }
        }
        
        var childrenMatter : Bool {
            switch self {
            case .transient, .void, .lookahead:
                return false
            default:
                return true
            }
        }
        
        var mattersToStructure : Bool {
            switch self {
            case .void, .lookahead:
                return false
            default:
                return true
            }
        }
    }
    
    /// The determined data type
    public enum DataType {
        case unknown,string,enumeration,structure,`typealias`
    }
    
    /**
     `Node` represents an element of the data structure and is the core of the
     AST derived.
     */
    public class Node {
        let scope : Scope
        /// The name of the element
        public var name : String
        
        /// The kind of the element
        public var kind : Kind
        
        /// The cardinality of the element
        public var cardinality : Cardinality
        
        /// Any child elements
        public var children = [Node]()
        
        /// The type of the element.
        public var type = DataType.unknown
        
        var partOfChoice = false
        
        var canBeEnum : Bool {
            return children.reduce(true, {$0 && $1.partOfChoice})
        }
        
        func dataType(_ accessLevel:String)->String {
            var coreType = ""
            switch type {
            case .unknown:
                coreType = "TBD"
            case .string:
                coreType = scope.type(of: name)
            case .typealias:
                coreType = "\(accessLevel) typealias \(name.typeName) = [\(children[0].name.typeName)]\(cardinality.optional ? "?" : " ")"
            case .structure, .enumeration:
                coreType = name.prefix(1).uppercased() + name.dropFirst()
            }
            switch cardinality {
            case .optional, .none:
                coreType += "?"
            case .one:
                break
            case .many(let optional):
                coreType = "[\(coreType)]\(optional ? "?" : "")"
            }
            return coreType
        }
        
        init(_ scope:Scope, name:String, cardinality:Cardinality, kind:Kind){
            self.scope = scope
            self.name = name
            self.cardinality = cardinality
            self.kind = kind
        }
        
        
        
        func promoteStructure(){
            var oneOrMoreStructural = false
            for child in children {
                child.promoteStructure()
                switch child.kind {
                case .structural, .pinned:
                    oneOrMoreStructural = true
                default:
                    break
                }
            }
            if oneOrMoreStructural {
                kind = .structural
            }
        }
        
        func cullStructurallyIrrelevantChildren(){
            for child in children {
                child.cullStructurallyIrrelevantChildren()
            }
            if children.count == 1 && !children[0].kind.childrenMatter{
                children = []
            }
        }
        
        func cullTransientChildren(){
            let _ = "hello"
            // Identify string based enums
            //  - Must have children
            //  - The must all be from a choice
            //  - The must all be transient, have no children of their own, and their name must start with a " (they are a terminal)
            if !children.isEmpty && canBeEnum  && children.reduce(true, {$0 && ($1.kind == .transient && $1.children.isEmpty && $1.name.hasPrefix("\""))}){
                for child in children {
                    child.kind = .structural
                    child.type = .string
                }
                type = .enumeration
                return
            }
            
            children = children.filter({(child) in
                child.cullTransientChildren()
                return child.kind != .transient && child.kind != .void
            })
        }
        
        func hoistGroupChildren(){
            var newChildren = [Node]()
            children = children.filter({(child) in
                child.hoistGroupChildren()
                if child.name == "$group$" {
                    
                    for grandChild in child.children {
                        grandChild.cardinality = child.cardinality.merge(with: grandChild.cardinality)
                    }
                    newChildren.append(contentsOf: child.children)
                    return false
                }
                return true
            })
            
            children.append(contentsOf: newChildren)
        }
        
        func hoistStructuralChildrenOfTransients(base:[Node]){
            var toAdd = [Node]()
            for child in children {
                if child.kind == .transient, let hoisting = base[child.name]{
                    if hoisting.kind == .structural {
                        toAdd.append(contentsOf: hoisting.children)
                    }
                }
            }
            
            children.append(contentsOf: toAdd)
        }
        
        func identifyTypes(baseTypes:[String]){
            if children.isEmpty {
                if baseTypes.contains(name){
                    type = .structure
                } else {
                    type = .string
                }
            }
            for child in children {
                child.identifyTypes(baseTypes: baseTypes)
            }
        }
        
        func consolidateChildren(accessLevel:String){
            children = children.consolidate(accessLevel:accessLevel)
            //No need to recurse, we are now just one layer deep
        }
    }
    
    
    
    
    
    let scope : Scope
    
    /// The generated data structure
    public var structure : Node
    
    private func dump(in scope:Scope){
        let temp = TextFile("temp")
        swift(to: temp, scope: scope, accessLevel: "public")
        print(temp.content)
    }
    
    /**
     Parses the AST and infers the fundamental data structure from it. This
     can subsequently be extended to generate the parsed input data structure
     in any language.
     
     - Parameter scope: The AST being assesed
     - Parameter accessLevel: The desired access level which should be specified
     in the target language
     */
    public init(for scope:Scope, accessLevel:String){
        self.scope = scope
        self.structure = Node(scope, name:"structure",cardinality:.one, kind: .structural)
        
        //Create all nodes for rules that appear
        for rule in scope.grammar.allRules {
            structure.children.append(generate(rule: rule))
        }
        
        //We also need to get all the inline defined rules
        
        for child in structure.children {
            let rule = scope.grammar[child.name]
            child.children.append(contentsOf: generate(expression: rule.expression))
            child.promoteStructure()
            child.cullStructurallyIrrelevantChildren()
            child.hoistGroupChildren()
            child.hoistStructuralChildrenOfTransients(base: structure.children)
        }
        
        structure.children = structure.children.filter({$0.kind != .transient && $0.kind != .void})
        
        structure.cullTransientChildren()
        
        // Now remove anything that is at the root level but has no children, they will be just strings
        structure.children = structure.children.filter({(rootNode) in
            return !rootNode.children.isEmpty
        })
        
        // Now remove anything from the top level that isn't referenced
        // and isn't a root rule
        var removeNames = [String]()
        
        let grammar = scope.grammar
        
        let rootRules = grammar.rules.filter({grammar.isRoot(identifier: $0.identifier)}).map({$0.identifier})
        
        for child in structure.children where !rootRules.contains(child.name){
            var referenced = false
            for otherChild in structure.children where otherChild.name != child.name{
                if otherChild.children[child.name] != nil {
                    referenced = true
                    break
                }
            }
            if !referenced {
                removeNames.append(child.name)
            }
        }
        
        structure.children = structure.children.filter({!removeNames.contains($0.name)})
        
        //Identify the children of all second level entries
        structure.identifyTypes(baseTypes: structure.children.map({return $0.name}))
        
        //Consolidate children and identify the type of all top level entries
        //Skipping anything that is already an enumeration
        for child in structure.children where child.type != .enumeration{
            child.consolidateChildren(accessLevel: accessLevel)
            if child.children.count == 1 && child.children[0].cardinality.many {
                child.type = .typealias
            } else {
                if child.canBeEnum {
                    child.type = .enumeration
                } else {
                    child.type = .structure
                }
            }
        }
        
    }
    
    func generate(element:STLR.Element)->[Node]{
        if let group = element.group {
            if case let Behaviour.Kind.structural(tokenName) = element.kind {
                let rule = scope.grammar["\(tokenName)"]
                let node = Node(scope, name: "\(tokenName)", cardinality: Cardinality(element: element, referencing: rule), kind: Kind(element: element, referencing: rule, defaultValue: .structural))
//                node.children = generate(expression: group.expression)
                
                return [node]
            }

            let children = generate(expression: group.expression)
            let node = Node(scope, name: "$group$", cardinality: Cardinality(element: element, referencing: nil), kind: Kind(element: element, referencing: nil, defaultValue: .transient))
            switch children.count {
            case 0:
                return [node]
            case 1:
                node.name = children[0].name
                node.kind = children[0].kind
                node.children = children[0].children
                node.cardinality = node.cardinality.merge(with: children[0].cardinality)
                return [node]
            default:
                node.children.append(contentsOf: children)
                return [node]
            }
        } else if let identifier = element.identifier {
            let evaluatedName : String
            /// We are only interested in the rule IF it is not inlined
            let rule = scope.grammar.rules.filter({$0.identifier == identifier}).first
            
            if case let Behaviour.Kind.structural(token) = element.kind {
                evaluatedName = "\(token)"
            } else {
                evaluatedName = identifier
            }
            
            //If this identifier has not quantity modifier we need to see if the expression has one and promote it up
            //otherwise it will be lost
            //I'm not doing any of the above below (commented out) because I don't think it's necessary with the generated
            //AST where ambiguity is removed
//            let modifier = modifier.isOne ? identifier.grammarRule?.expression?.promotableContentModifer?.promotableOptionality ?? .one : modifier
//            let evaluatedAnnotations = identifier.annotations.merge(with: annotations)
            let nodes =  [Node(scope, name: evaluatedName, cardinality: Cardinality(element: element, referencing: rule), kind: Kind(element: element, referencing: rule, defaultValue: .structural))]

            return nodes
        } else if let terminal = element.terminal {
//            /// The optimizer may have optimized a choice of single character terminals into
//            /// a character set initialized by the combination of that string. We will need
//            /// to break that appart
//            if case let _STLR.Terminal.characterSet(characterSet) = terminal {
//                if case let .customString(characters) = characterSetTerminal {
//                    var choices = [Node]()
//                    for character in characters {
//                        let choice = Node(scope, name: "\"\(character)\"", cardinality: .optional, kind: .transient)
//                        choice.partOfChoice = true
//                        choices.append(choice)
//                    }
//                    return choices
//                }
//            }
           
            if case let Behaviour.Kind.structural(token) = element.kind {
                let rule = scope.grammar["\(token)"]

                return [
                    Node(scope, name: "\(token)", cardinality: Cardinality(element: element,referencing: nil), kind: Kind(element: element,referencing: nil, defaultValue: .transient))
                ]
            } else {
                return [
                    Node(scope, name: terminal.description, cardinality: Cardinality(element: element,referencing: nil), kind: Kind(element: element,referencing: nil, defaultValue: .transient))
                ]
            }
            
        }
        
        fatalError("Element is not of any known types")
    }
    
    func generate(expression:STLR.Expression)->[Node] {
        var nodes = [Node]()
        switch expression {
        case .element(let element):
            generate(element: element).forEach({nodes.append($0)})
        case .sequence(let elements):
            for element in elements {
                generate(element: element).forEach({nodes.append($0)})
            }
        case .choice(let elements):
            for element in elements {
                let elementNodes = generate(element: element)
                if let node = elementNodes.first, elementNodes.count == 1 {
                    node.partOfChoice = true
                    switch node.cardinality {
                    case .one, .none:
                        node.cardinality = .optional
                    case .many(let optional):
                        if !optional {
                            node.cardinality = .many(true)
                        }
                    case .optional:
                        node.cardinality = .optional
                    }
                    nodes.append(node)
                } else {
                    elementNodes.forEach({nodes.append($0)})
                }
            }
        }
        
        return nodes.filter({$0.kind.mattersToStructure})
    }
    
    
    func generate(rule:Scope.Rule)->Node {
        return Node(scope, name: rule.identifier, cardinality: .one, kind: Kind(rule: rule))
    }

    
}

fileprivate extension Array where Element == GrammarStructure.Node {
    
    fileprivate subscript(_ name:String)->GrammarStructure.Node? {
        return self.filter({$0.name == name}).first
    }
    
    fileprivate func consolidate(accessLevel:String)->[Element]{
        var existingFields = [String : GrammarStructure.Node]()
        
        for child in self {
            if let existingType = existingFields[child.name]?.dataType(accessLevel) {
                if existingType == child.dataType(accessLevel) || child.dataType(accessLevel).arrayElement(is: existingType){
                    child.cardinality = .many(false)
                    existingFields[child.name] = child
                } else if existingType.arrayElement(is: child.dataType(accessLevel)){
                    //Do nothing, it will work fine
                } else {
                    fatalError("There are multiple fields with the same name (\(child.name)) but different types:\n\t\(child.dataType)\n\t\(existingType)\nCannot generate structure")
                }
            } else {
                existingFields[child.name] = child
            }
        }
        
        return existingFields.map({return $1})
    }
}

extension STLR {
    func identifierIsLeftHandRecursive(_ name:Swift.String)->Bool{
        return grammar.isLeftHandRecursive(identifier: name)
    }
    func type(of name:Swift.String)->Swift.String{
        if !grammar.defined(identifier: name){
            return "Swift.String"
        }
        let rule : STLR.Rule = grammar[name]
        
        guard let type = rule.declaredType else {
            return "Swift.String"
        }
        
        return Swift.String(type.dropLast().dropFirst())
    }
}
