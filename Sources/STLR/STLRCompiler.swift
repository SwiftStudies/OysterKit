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

public enum STLRCompilerError : Error {
    case identifierAlreadyDefined(named:String)
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
        if let _ = scope.get(identifier: self.identifier) {
            throw STLRCompilerError.identifierAlreadyDefined(named: self.identifier)
        }

        let symbolTableEntry = scope.register(identifier: identifier)
        if let annotations = try annotations?.map({ return try $0.compile(from:ast, into: scope)}) {
            symbolTableEntry.annotations = annotations
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

extension STLRAbstractSyntaxTree.Element {
    func compile(from ast: STLRAbstractSyntaxTree, into scope:STLRScope) throws -> STLRScope.Element {
        let annotations = try self.annotations?.map({ return try $0.compile(from:ast, into: scope)}) ?? []
        let lookahead = self.lookahead ?? "false" == "true"
        let transient = self.quantifier == .
        
        let transient   : Bool                  = children[STLR.transient]?.cast() ?? false
        
        
        let not : Modifier = not
        
        var negated     : Modifier            = children[STLR.negated]?.cast() ?? .one
        var quantifier  : Modifier            = children[STLR.quantifier]?.cast() ?? .one

        STLRScope.
        
        fatalError("Unimplemented element type")
    }
}

extension STLRAbstractSyntaxTree.Annotation {
    func compile(from ast: STLRAbstractSyntaxTree, into scope:STLRScope) throws -> STLRScope.ElementAnnotationInstance {
        
        switch label {
        case "token":
            return STLRScope.ElementAnnotationInstance(
                STLRScope.ElementAnnotation.token,
                value: literal.compile())
        case "error":
            return STLRScope.ElementAnnotationInstance(
                STLRScope.ElementAnnotation.error,
                value: literal.compile())
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
                value: literal.compile() )
        }
    }

}

extension STLRAbstractSyntaxTree.Literal {
    func compile()->STLRScope.ElementAnnotationValue{
        if let boolean = boolean {
            return STLRScope.ElementAnnotationValue.bool(boolean)
        }
        if let string = string {
            return STLRScope.ElementAnnotationValue.string(string)
        }
        if let number = number {
            return STLRScope.ElementAnnotationValue.int(number)
        }
        
        return STLRScope.ElementAnnotationValue.set
    }
}
