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

/// Provides functions for optimizing the grammar as represented in the AST
public extension STLRIntermediateRepresentation{
    
    /// Optimizes the grammar using the optimizers registered by `register(optimizer:STLROptimizer)`
    public func optimize(){
        
        func rulesAreEqual(rule1:STLRIntermediateRepresentation.GrammarRule, rule2:STLRIntermediateRepresentation.GrammarRule)->Bool{
            guard let id1 = rule1.identifier?.name, let id2 = rule2.identifier?.name else {
                return true
            }
            return id1 == id2
        }
        
        let originalRootRules = rootRules
        
        for rule in rules{
            if let optimizedExpression = rule.expression?.optimize {
                rule.expression = nil
                rule.expression = optimizedExpression
            }
        }
        
        let newRootRules = rootRules
        
        let unusedRules = newRootRules.filter(){ (newRootRule) in
            !originalRootRules.contains(where: { (originalRootRule) in
                rulesAreEqual(rule1: newRootRule, rule2: originalRootRule)
            })
        }
        
        rules = rules.filter({ (rule) in
            !unusedRules.contains(){ (unused) in
                rulesAreEqual(rule1: unused, rule2: rule)
            }
        })
    }
    
}
