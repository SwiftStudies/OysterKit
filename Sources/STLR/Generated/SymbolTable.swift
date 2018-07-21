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

public protocol SymbolType {
    static func buildRule(for identifier: String, from grammar: _STLR.Grammar, in symbolTable: SymbolTable<Self>)->Self
}

public class SymbolTable<Symbol:SymbolType> {

    public let ast : _STLR.Grammar
    private var identifiers = [String : Symbol]()

    init(_ grammr:_STLR.Grammar){
        ast = grammr
    }
    
    public func isLeftHandRecursive(_ identifier:String)->Bool{
        return ast[identifier].expression.references(identifier, grammar: ast, closedList: [])
    }
    
    subscript(hasRule identifier:String)->Bool{
        return identifiers[identifier] != nil
    }
    
    subscript(_ identifier:String)->Symbol{
        get {
            if let cached = identifiers[identifier] {
                return cached
            }
            let symbol = Symbol.buildRule(for:identifier, from:ast, in: self)
            identifiers[identifier] = symbol
            return symbol
        }
        
        set{
            identifiers[identifier] = newValue
        }
    }
}
