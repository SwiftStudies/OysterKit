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

struct RecursiveRuleInstance : Rule {
    let original : RecursiveRule
    let behaviour: Behaviour
    let annotations: RuleAnnotations
    
    init(_ original:RecursiveRule, behaviour:Behaviour, annotations:RuleAnnotations){
        self.original = original
        self.behaviour = Behaviour(.scanning)
        self.annotations = annotations
    }
    
    func test(with lexer: LexicalAnalyzer, for ir: IntermediateRepresentation) throws {
        try original.test(with: lexer, for: ir)
    }
    
    func match(with lexer: LexicalAnalyzer, for ir: IntermediateRepresentation) throws {
//        try original.surrogateRule?.test(with: lexer, for: ir)
        if let surrogateRule = original.surrogateRule {
            try evaluate(surrogateRule.test, using: lexer, and: ir)
        } else {
            throw ProcessingError.fatal(message: "\(original) has no surrogate rule set", causes: [])
        }
    }
    
    var description: String {
        return behaviour.describe(match: original.description, annotatedWith: original.surrogateRule?.annotations ?? [:])
    }
    
    var shortDescription: String {
        let indicator : String
        if let _ = original.surrogateRule {
            indicator = "🔃"
        } else {
            indicator = "❌"
        }
        if let token = behaviour.token {
            return behaviour.describe(match: "\(indicator)\(token)", requiresStructuralPrefix: false, annotatedWith: original.surrogateRule?.annotations ?? [:])
        }
        return behaviour.describe(match: "\(indicator)❌", requiresStructuralPrefix: false, annotatedWith: original.surrogateRule?.annotations ?? [:])
    }
    
    func rule(with behaviour: Behaviour?, annotations: RuleAnnotations?) -> Rule {
        return RecursiveRuleInstance(original, behaviour: behaviour ?? self.behaviour, annotations: annotations ?? self.annotations)
    }
}
