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

public extension _STLR.Grammar {
    public subscript(_ identifier:String)->_STLR.Rule{
        for rule in rules {
            if rule.identifier == identifier {
                return rule
            }
        }
        fatalError("Undefined identifier: \(identifier)")
    }
}

public extension _STLR.Expression {
    fileprivate var elements : [_STLR.Element] {
        switch self {
        case .sequence(let sequence):
            return sequence
        case .choice(let choice):
            return choice
        case .element(let element):
            return [element]
        }
    }
    
    public func references(_ identifier:String, grammar:_STLR.Grammar, closedList:[String])->Bool {
        for element in elements {
            if element.references(identifier, grammar: grammar, closedList: closedList){
                return true
            }
        }
        return false
    }
}

public extension _STLR.Element {
    func references(_ identifier:String, grammar:_STLR.Grammar, closedList:[String])->Bool {
        if let group = group {
            return group.expression.references(identifier, grammar: grammar, closedList: closedList)
        } else if let _ = terminal {
            return false
        } else if let referencedIdentifier = self.identifier{
            if referencedIdentifier == identifier {
                return true
            }
            if !closedList.contains(referencedIdentifier){
                return grammar[referencedIdentifier].expression.references(identifier, grammar:grammar, closedList: closedList)
            }
        }
        return false
    }
}
