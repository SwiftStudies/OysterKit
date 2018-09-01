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

import OysterKit

public protocol SymbolType {
    static func build(for identifier: String, from grammar: STLR.Grammar, in symbolTable: SymbolTable<Self>)->Self
    
    func resolve(from grammar:STLR.Grammar, in symbolTable: SymbolTable<Self>) throws
    func validate(from grammar:STLR.Grammar, in symbolTable: SymbolTable<Self>) throws

    var identifier   : String {get}
}

public class SymbolTable<Symbol:SymbolType> {

    public let ast : STLR.Grammar
    private var identifiers = [String : Symbol]()

    /**
     Creates a new symbol table for the specified grammar. The table will be empty, and the caller
     should subsequently call `build()`, `resolve()`, then `validate()` before the table can be used.
     **/
    public init(_ grammr:STLR.Grammar){
        ast = grammr
    }
    
    /**
     Builds the symbol table. Implementers of the `SymbolType` should not attempt to resolve
     recursion at this stage, but create a forward reference that can be turned into a final
     reference in the resolution phase.
     **/
    public func build() throws{
        for rule in ast.rules {
            if identifiers[rule.identifier] == nil {
                identifiers[rule.identifier] = Symbol.build(for: rule.identifier, from: ast, in: self)
            }
        }
    }

    /**
     Any evaluation of symbols (for example as a result of recursion) that were left as forward
     references should be resolved at this stage.
     **/
    public func resolve() throws{
        var errors = [Error]()
        for (_,symbol) in identifiers {
            do {
                try symbol.resolve(from: ast, in: self)
            } catch {
                errors.append(error)
            }
        }
        
        if !errors.isEmpty {
            throw TestError.interpretationError(message: "Failed to resolve symbol table", causes: errors)
        }
    }
    
    /**
     A final validation step to ensure there are no issues in the table.
     **/
    public func validate() throws {
        var errors = [Error]()
        for (_,symbol) in identifiers {
            do {
                try symbol.validate(from: ast, in: self)
            } catch {
                errors.append(error)
            }
        }
        
        if !errors.isEmpty {
            throw TestError.interpretationError(message: "Failed to validate symbol table", causes: errors)
        }
    }
    
    public func isLeftHandRecursive(_ identifier:String)->Bool{
        var closedList = [String]()
        return ast[identifier].expression.references(identifier, grammar: ast, closedList: &closedList)
    }
    
    subscript(hasRule identifier:String)->Bool{
        return identifiers[identifier] != nil
    }
    
    private func set(_ identifier:String, to symbol:Symbol){
        identifiers[identifier] = symbol
    }
    
    subscript(_ identifier:String)->Symbol{
        get {

            if let cached = identifiers[identifier] {
                return cached
            } else {
                let symbol = Symbol.build(for: identifier, from: ast, in: self)
                set(identifier, to: symbol)
                
                return symbol
            }
        }

    }
}
