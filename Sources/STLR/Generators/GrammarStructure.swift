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

public class GrammarStructure {
    enum Cardinality {
        case optional, one, many(Bool)
        
        init(modifier:STLRScope.Modifier){
            switch modifier {
            case .one, .not:
                self = .one
            case .zeroOrOne:
                self = .optional
            case .zeroOrMore:
                self = .many(true)
            case .oneOrMore:
                self = .many(false)
            case .void:
                fatalError("Didn't expect to see this")
            case .transient:
                fatalError("Didn't expect to see this")
            }
        }
        
        var optional : Bool {
            switch self {
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
            case .optional, .one:
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
    
    enum Kind {
        case transient, void, pinned, structural, lookahead
        
        init(identifier:STLRScope.Identifier){
            let annotations = identifier.annotations.asRuleAnnotations
            
            if annotations.pinned {
                self = .pinned
            } else if annotations.void {
                self = .void
            } else if annotations.transient {
                self = .transient
            } else {
                self = .structural
            }
        }
        
        init(modifier:STLRScope.Modifier, lookahead:Bool, annotations:RuleAnnotations,defaultValue:Kind){
            if lookahead {
                self = .lookahead
            } else if annotations.void {
                self = .void
            } else if annotations[.token] != nil{
                self = .structural
            } else if annotations.transient {
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
    
    enum DataType {
        case unknown,string,enumeration,structure,`typealias`
    }
    
    class Node {
        let scope : STLRScope
        var name : String
        var kind : Kind
        var cardinality : Cardinality
        var children = [Node]()
        var type = DataType.unknown
        var partOfChoice = false
        
        var canBeEnum : Bool {
            return children.reduce(true, {$0 && $1.partOfChoice})
        }
        
        var dataType : String {
            var coreType = ""
            switch type {
            case .unknown:
                coreType = "TBD"
            case .string:
                coreType = scope.type(of: name)
            case .typealias:
                coreType = "typealias \(name.typeName) = [\(children[0].name.typeName)]\(cardinality.optional ? "?" : " ")"
            case .structure, .enumeration:
                coreType = name.prefix(1).uppercased() + name.dropFirst()
            }
            switch cardinality {
            case .optional:
                coreType += "?"
            case .one:
                break
            case .many(let optional):
                coreType = "[\(coreType)]\(optional ? "?" : "")"
            }
            return coreType
        }
        
        init(_ scope:STLRScope, name:String, cardinality:Cardinality, kind:Kind){
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
        
        func consolidateChildren(){
            children = children.consolidate()
            //No need to recurse, we are now just one layer deep
        }
    }
    
    


    
    let scope : STLRScope
    var structure : Node

    private func dump(in scope:STLRScope){
        let temp = TextFile("temp")
        swift(to: temp, scope: scope)
        print(temp.content)
    }
    
    init(for scope:STLRScope){
        self.scope = scope
        self.structure = Node(scope, name:"structure",cardinality:.one, kind: .structural)
        
        //Create all nodes for rules that appear
        for rule in scope.rules {
            structure.children.append(generate(rule: rule))
        }
        
        for child in structure.children {
            let identifier = scope.get(identifier: child.name)!
            child.children.append(contentsOf: generate(expression: identifier.grammarRule!.expression!))
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
        let rootRules = scope.rootRules.map({$0.identifier!.name})

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
            child.consolidateChildren()
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
    
    func generate(element:STLRScope.Element)->Node{
        switch element {
        case .terminal(let terminal, let modifier, let lookahead, let annotations):
            return Node(scope, name: terminal.description, cardinality: Cardinality(modifier: modifier), kind: Kind(modifier: modifier, lookahead: lookahead, annotations: annotations.asRuleAnnotations, defaultValue: .transient))
        case .identifier(let identifier, let modifier, let lookahead, let annotations):
            let evaluatedAnnotations = identifier.annotations.merge(with: annotations)
            let evaluatedName : String
            if let tokenAnnotation = annotations.asRuleAnnotations[.token] {
                if case let .string(tokenName) = tokenAnnotation{
                    evaluatedName = tokenName
                } else {
                    evaluatedName = identifier.name
                }
            } else {
                evaluatedName = identifier.name
            }
            //If this identifier has not quantity modifier we need to see if the expression has one and promote it up
            //otherwise it will be lost
            let modifier = modifier.isOne ? identifier.grammarRule?.expression?.promotableContentModifer?.promotableOptionality ?? .one : modifier
            return Node(scope, name: evaluatedName, cardinality: Cardinality(modifier: modifier), kind: Kind(modifier: modifier, lookahead: lookahead, annotations: evaluatedAnnotations.asRuleAnnotations, defaultValue: .structural))
        case .group(let expression, let modifier, let lookahead, let annotations):
            if let tokenAnnotation = annotations.asRuleAnnotations[.token] {
                if case let .string(tokenName) = tokenAnnotation{
                    return Node(scope, name: tokenName, cardinality: Cardinality(modifier: modifier), kind: Kind(modifier: modifier, lookahead: lookahead, annotations: annotations.asRuleAnnotations, defaultValue: .structural))
                }
            }
            let children = generate(expression: expression)
            let node = Node(scope, name: "$group$", cardinality: Cardinality(modifier: modifier), kind: Kind(modifier: modifier, lookahead: lookahead, annotations: annotations.asRuleAnnotations, defaultValue: .transient))
            switch children.count {
            case 0:
                return node
            case 1:
                node.name = children[0].name
                node.kind = children[0].kind
                node.children = children[0].children
                node.cardinality = node.cardinality.merge(with: children[0].cardinality)
                return node
            default:
                node.children.append(contentsOf: children)
                return node
            }
        }
    }
    
    func generate(expression:STLRScope.Expression)->[Node] {
        var nodes = [Node]()
        switch expression {
        case .element(let element):
            nodes.append(generate(element:element))
        case .sequence(let elements):
            for element in elements {
                nodes.append(generate(element:element))
            }
        case .choice(let elements):
            for element in elements {
                let node = generate(element: element)
                node.partOfChoice = true
                switch node.cardinality {
                case .one:
                    node.cardinality = .optional
                case .many(let optional):
                    if !optional {
                        node.cardinality = .many(true)
                    }
                case .optional:
                    node.cardinality = .optional
                }
                nodes.append(node)
            }
        case .group():
            fatalError("Really do these exist?")
        }
        
        return nodes.filter({$0.kind.mattersToStructure})
    }

    
    func generate(rule:STLRScope.GrammarRule)->Node {
        let name = rule.identifier!.name
        
        return Node(scope, name: name, cardinality: .one, kind: Kind(identifier: rule.identifier!))
    }
    
}

fileprivate extension Array where Element == GrammarStructure.Node {
    
    fileprivate subscript(_ name:String)->GrammarStructure.Node? {
        return self.filter({$0.name == name}).first
    }
    
    fileprivate func consolidate()->[Element]{
        var existingFields = [String : GrammarStructure.Node]()
        
        for child in self {
            if let existingType = existingFields[child.name]?.dataType {
                if existingType == child.dataType || child.dataType.arrayElement(is: existingType){
                    child.cardinality = .many(false)
                    existingFields[child.name] = child
                } else if existingType.arrayElement(is: child.dataType){
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

extension STLRScope.Modifier{
    var promotableOptionality : STLRScope.Modifier {
        switch self {
        case .zeroOrOne, .zeroOrMore:
            return .zeroOrOne
        default:
            return .one
        }
    }
}

extension STLRScope.Element {
    var promotableContentModifier : STLRScope.Modifier? {
        if self.lookahead {
            return nil
        }
        switch self {
        case .group(let expression, let modifier, _, _):
            if modifier == .one {
                return expression.promotableContentModifer
            }
            return modifier
        case .terminal(_, let modifier, _, _):
            return modifier
        case .identifier(let identifier, let modifier, _, _):
            if modifier == .one {
                return identifier.grammarRule?.expression?.promotableContentModifer
            }
            return modifier
        }
        
        return nil
    }
}

extension STLRScope.Expression {
    var promotableContentModifer : STLRScope.Modifier? {
        switch self {
        case .element(let element):
            return element.promotableContentModifier
        case .sequence(let elements):
            if elements.count == 1 {
                return elements[0].quantifier
            }
            return nil
        case .choice(let elements):
            if elements.isEmpty {
                return nil
            }
            let oneQuantifierType = elements[0].quantifier
            for element in elements.dropFirst() {
                if oneQuantifierType != element.quantifier {
                    return nil
                }
            }
            return oneQuantifierType
        case .group:
            return nil
        }
    }
}

extension STLRScope {
    func identifierIsLeftHandRecursive(_ name:String)->Bool{
        return get(identifier: name)?.grammarRule?.leftHandRecursive ?? false
    }
    func type(of name:String)->String{
        guard let type = get(identifier: name)?.annotations.asRuleAnnotations[.custom(label: "type")]?.description else {
            return "Swift.String"
        }
        
        return String(type.dropLast().dropFirst())
    }
}


