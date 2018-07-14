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

public enum STLRCompilerError : Error {
    case unknownIdentifier(named:String)
    case identifierAlreadyDefined(named:String)
    case noTokenNameSpecified
}

/**
 Adds a new initializer to ``STLRScope`` taking in a STLR source file, building a ````STLRAbstractSyntaxTree```` and then using that
 to build the ````STLRScope````.
 */
extension STLRScope {
    //// Creates a new instance of ````STLRScope````
    convenience init(building source:String){
        self.init()
        
        do {
            let ast = try STLRAbstractSyntaxTree(source)
            
//            print(ast.intermediateRepresentation.description)
            
            for rule in ast.rules {
                try rule.compile(from: ast, into: self)
            }
        } catch {
            errors.append(error)
        }
    }
}

extension STLRScope {
    //// Gets the identifier with the specified name
    func get(identifier named:String)->STLRScope.Identifier? {
        if let existing = identifiers[named] {
            return existing
        }
        return nil
    }
    
    //// Returns an existing identifier, adding a reference to it, or creates a new one and adds it
    func register(identifier named:String)->STLRScope.Identifier {
        if let identifier = get(identifier: named) {
            ////TODO: It used to add references
            return identifier
        }

        let newIdentifier = Identifier(name: named, rawValue: identifiers.count+1)
        identifiers[named] = newIdentifier
        ////TODO: It used to add references

        return newIdentifier
    }
}

extension STLRAbstractSyntaxTree.Rule {
    func compile(from ast: STLRAbstractSyntaxTree, into scope:STLRScope) throws {
        if let identifier = scope.get(identifier: self.identifier), identifier.grammarRule != nil {
            throw STLRCompilerError.identifierAlreadyDefined(named: self.identifier)
        }

        let symbolTableEntry = scope.register(identifier: identifier)
        if let annotations = try annotations?.map({ return try $0.compile(from:ast, into: scope)}) {
            symbolTableEntry.annotations = annotations
        }
        
        if let void = void, void == .void {
            symbolTableEntry.annotations.append(STLRScope.ElementAnnotationInstance(STLRScope.ElementAnnotation.void, value: STLRScope.ElementAnnotationValue.set))
        }
        
        if let transient = transient, transient == .transient {
            symbolTableEntry.annotations.append(STLRScope.ElementAnnotationInstance(STLRScope.ElementAnnotation.transient, value: STLRScope.ElementAnnotationValue.set))
        }
        
        let grammarRule = STLRScope.GrammarRule(with: symbolTableEntry, try expression.compile(from:ast, into:scope), in: scope)

        // Update tables
        symbolTableEntry.grammarRule = grammarRule
        scope.rules.append(grammarRule)
    }
}

extension STLRAbstractSyntaxTree.Expression {
    func compile(from ast: STLRAbstractSyntaxTree, into scope:STLRScope) throws ->STLRScope.Expression {
        if let choice = choice {
            return try STLRScope.Expression.choice(choice.map(){
                return try $0.compile(from:ast,into: scope)
            })
        }
        
        if let sequence = sequence {
            return try STLRScope.Expression.sequence(sequence.map(){
                return try $0.compile(from:ast,into: scope)
            })
        }
        
        if let element = element {
            return try STLRScope.Expression.element(element.compile(from: ast, into: scope))
        }
        
        fatalError("Unknown child element has been added to Expression structure")
    }
}

extension STLRAbstractSyntaxTree.Terminal {
    func build()->STLRScope.Terminal {
        if let regex = regex {
            let regularExpression : NSRegularExpression
            do {
                regularExpression = try NSRegularExpression(pattern: "^\(regex)", options: [])
            } catch {
                fatalError("Could not compile pattern: \(regex), \(error)")
            }
            return STLRScope.Terminal(with: regularExpression)
        } else if let characterSet = STLRScope.TerminalCharacterSet(rawValue: characterSet?.characterSetName.rawValue ?? "$ERROR$") {
            return STLRScope.Terminal(with: characterSet)
        } else if let characterRange = characterRange {
            return STLRScope.Terminal(with: STLRScope.TerminalCharacterSet(from: characterRange[0].terminalBody, to: characterRange[1].terminalBody))
        } else if let terminalString = terminalString?.terminalBody {
            return STLRScope.Terminal.init(with: terminalString)
        } else if let otherCharacterSet = characterSet {
            switch otherCharacterSet.characterSetName {
            case .backslash:
                return STLRScope.Terminal.init(with: "\\\\")
            default:
                fatalError("Standard character set should have covered other cases")
            }
        }
        
        fatalError("Unimplemented Terminal type")
    }
}

extension STLRAbstractSyntaxTree.Element {
    
    //// Creates the raw element
    private func build(using element: STLRAbstractSyntaxTree.Element,from ast: STLRAbstractSyntaxTree, into scope:STLRScope, _ quantifier:STLRScope.Modifier, _ lookahead:Bool, _ annotations: STLRScope.ElementAnnotations) throws ->STLRScope.Element {
        if let terminal = element.terminal {
            return STLRScope.Element.terminal(terminal.build(), quantifier, lookahead, annotations)
        } else if let identifier = scope.get(identifier: element.identifier ?? "$ERROR$") {
            return STLRScope.Element.identifier(identifier, quantifier, lookahead, annotations)
        } else if let identifierName = element.identifier {
            return STLRScope.Element.identifier(scope.register(identifier: identifierName), quantifier, lookahead, annotations)
        } else if let expression = element.group?.expression {
            return STLRScope.Element.group(try expression.compile(from: ast, into: scope), quantifier, lookahead, annotations)
        } else {
            fatalError("Element should be a terminal, identifier, or group")
        }
    }

    func compile(from ast: STLRAbstractSyntaxTree, into scope:STLRScope) throws -> STLRScope.Element {
        let lookahead = self.lookahead != nil
        let transient = self.transient != nil
        
        var negated  = self.negated?.compile() ?? STLRScope.Modifier.one
        var quantifier  = self.quantifier?.compile() ?? STLRScope.Modifier.one
        var annotations = try self.annotations?.map({ return try $0.compile(from:ast, into: scope)}) ?? []

        //Look for void sugar'd annotation
        if void != nil {
            annotations.append(STLRScope.ElementAnnotationInstance(STLRScope.ElementAnnotation.void, value: STLRScope.ElementAnnotationValue.set))
        }

        //If there is no specific annotation and a transient mark (~) was given then create an annotation for it
        if transient && annotations[annotation: STLRScope.ElementAnnotation.transient] == nil{
            annotations.append(STLRScope.ElementAnnotationInstance(STLRScope.ElementAnnotation.transient, value: STLRScope.ElementAnnotationValue.set))
        }
        
        // Try to fold negation into the quantifier
        if quantifier == .one  {
            quantifier = negated
            negated = .one
        }
        
        var element : STLRScope.Element
        
        /// Do we have an inline specification of a token?
        if let inlineIdentifier = annotations[annotation: STLRScope.ElementAnnotation.token], case let STLRScope.ElementAnnotationValue.string(stringValue) = inlineIdentifier {
            var identifier : STLRScope.Identifier
            
            if let existingIdentifier = scope.identifiers[stringValue] {
                identifier = existingIdentifier
            } else {
                identifier = scope.register(identifier: stringValue)
                
                // This is a copy from rule and should be refactored into a common sub-method
                let rule : STLRScope.GrammarRule
                if identifier.grammarRule == nil {
                    rule = STLRScope.GrammarRule(with: identifier, nil, in: scope)
                    identifier.grammarRule = rule
                    rule.identifier = identifier
                    
                    //This may be a bug in rule definition too
                    scope.rules.append(rule)
                } else {
                    rule = identifier.grammarRule!
                }
                
                // If this is a reference to another identifier, this must be compiled next and it's expression used.
                if let referenceToIdentifier = self.identifier {
                    var subsummed = false
                    for surrogageRule in ast.rules {
                        // If the token is subsuming a top-level rule we can compile that rule and steal its expression
                        if surrogageRule.identifier == referenceToIdentifier {
                            rule.expression = try surrogageRule.expression.compile(from: ast, into: scope)
                            subsummed = true
                            break
                        }
                    }
                    if !subsummed {
                        rule.expression = STLRScope.Expression.element(try build(using: self, from: ast, into: scope, quantifier, lookahead, []))
                    }
                } else {
                    rule.expression = STLRScope.Expression.element(try build(using: self, from: ast, into: scope, quantifier, lookahead, []))
                }
                
                for annotation in annotations.remove(STLRScope.ElementAnnotation.token) {
                    if identifier.annotations[annotation: annotation.annotation] != nil {
                        scope.errors.append(LanguageError.warning(at: identifier.references[0], message: "\(identifier.name) has overlapping annotations"))
                    }
                    
                    identifier.annotations.append(annotation)
                }
            }
            
            //Finally create a new element as if they had always referenced the identifier here
            annotations = []
            
            return STLRScope.Element.identifier(identifier, .one, false, [])
        } else {
            //Wrap elements with negation AND another quantifier in a group
            if negated != .one && quantifier != .one {
                //Wrap in a lookahead group
                element = STLRScope.Element.group(
                    STLRScope.Expression.element(
                        try build(using: self, from: ast, into: scope, negated, false, [])
                ), quantifier, lookahead, annotations)
            } else {
                element = try build(using: self, from: ast, into: scope, quantifier, lookahead, annotations)
            }
        }
        
        //Wrap elements with lookahead AND a quantifier in a group
        if quantifier != .one && lookahead {
            //Change the lookahead setting on the element
            element.setLookahead(lookahead: false)
            
            //Wrap in a lookahead group
            element = STLRScope.Element.group(STLRScope.Expression.element(element), STLRScope.Modifier.one, true, annotations)
        }
        
        return element
    }
}

extension STLRAbstractSyntaxTree.Quantifier {
    func compile()->STLRScope.Modifier{
        switch self {
        case .noneOrMore:
            return STLRScope.Modifier.zeroOrMore
        case .optional:
            return STLRScope.Modifier.zeroOrOne
        case .oneOrMore:
            return STLRScope.Modifier.oneOrMore
        case .transient:
            return STLRScope.Modifier.transient
        case .void:
            return STLRScope.Modifier.void
        }
    }
}

extension STLRAbstractSyntaxTree.Qualifier{
    func compile()->STLRScope.Modifier{
        return STLRScope.Modifier.not
    }
}

extension STLRAbstractSyntaxTree.Annotation {
    func compile(from ast: STLRAbstractSyntaxTree, into scope:STLRScope) throws -> STLRScope.ElementAnnotationInstance {
        
        switch label {
        case "token":
            guard let tokenName = literal?.compile() else {
                throw STLRCompilerError.noTokenNameSpecified
            }
            
            
            return STLRScope.ElementAnnotationInstance(
                STLRScope.ElementAnnotation.token,
                value: tokenName)
        case "error":
            return STLRScope.ElementAnnotationInstance(
                STLRScope.ElementAnnotation.error,
                value: literal?.compile() ?? STLRScope.ElementAnnotationValue.string("Unspecified error"))
        case "void":
            return STLRScope.ElementAnnotationInstance(
                STLRScope.ElementAnnotation.void,
                value: STLRScope.ElementAnnotationValue.set)
        case "transient":
            return STLRScope.ElementAnnotationInstance(
                STLRScope.ElementAnnotation.transient,
                value: STLRScope.ElementAnnotationValue.set)
        case "pinned":
            return STLRScope.ElementAnnotationInstance(
                STLRScope.ElementAnnotation.pinned,
                value: STLRScope.ElementAnnotationValue.set)
        default:
            return STLRScope.ElementAnnotationInstance(
                STLRScope.ElementAnnotation.custom(label: label),
                value: literal?.compile() ?? STLRScope.ElementAnnotationValue.set)
        }
    }

}

extension STLRAbstractSyntaxTree.Literal {
    func compile()->STLRScope.ElementAnnotationValue{
        if let boolean = boolean {
            return STLRScope.ElementAnnotationValue.bool(boolean)
        }
        if let string = string {
            return STLRScope.ElementAnnotationValue.string(string.body)
        }
        if let number = number {
            return STLRScope.ElementAnnotationValue.int(number)
        }
        
        return STLRScope.ElementAnnotationValue.set
    }
}
