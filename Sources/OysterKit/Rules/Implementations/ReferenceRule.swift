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

public final class ReferenceRule : Rule {
    public var behaviour: Behaviour
    public var annotations: RuleAnnotations
    public var references : Rule
    
    public init(_ behaviour:Behaviour, and annotations:RuleAnnotations, for rule:Rule){
        self.annotations = annotations
        if let token = behaviour.token {
            self.references = rule.parse(as: token)
            self.behaviour = Behaviour(.scanning, cardinality: behaviour.cardinality, negated: behaviour.negate, lookahead: behaviour.lookahead)
        } else {
            self.references = rule
            self.behaviour = behaviour
        }
    }
    
    public func test(with lexer: LexicalAnalyzer, for ir: IntermediateRepresentation) throws {
        _ = try references.match(with: lexer, for: ir)
    }
    
    public func rule(with behaviour: Behaviour?, annotations: RuleAnnotations?) -> Rule {
        // Changes to scanning, skipping, structure should be applied differently
        if let behaviour = behaviour, behaviour.kind != self.behaviour.kind {
            // Apply the new kind to just the referenced rule, but leave this one's kind untouched
            let referenceRuleBehaviour = Behaviour(self.behaviour.kind, cardinality: behaviour.cardinality, negated: behaviour.negate, lookahead: behaviour.lookahead)
            let referencedRuleBehaviour = Behaviour(behaviour.kind, cardinality: references.behaviour.cardinality, negated: references.behaviour.negate, lookahead: references.behaviour.lookahead)

            return ReferenceRule(referenceRuleBehaviour, and: annotations ?? self.annotations, for: references.rule(with: referencedRuleBehaviour, annotations: nil))
        } else {
            return ReferenceRule(behaviour ?? self.behaviour, and: annotations ?? self.annotations, for: references)
        }
    }
    
    /// A textual description of the rule
    public var description: String {
        let    annotates = "\(annotations.isEmpty ? "" : "\(annotations.description) ")"
        return annotates + behaviour.describe(match:"(\(references.description))")
    }
    
    /// An abreviated description of the rule
    public var shortDescription: String{
        if let produces = behaviour.token {
            return behaviour.describe(match: "\(produces)", requiresStructuralPrefix: false)
        }
        if let referenceProduces = references.behaviour.token{
            return behaviour.describe(match: "\(referenceProduces)", requiresStructuralPrefix: false)
        }
        return behaviour.describe(match: "(\(references.shortDescription))")
    }
}
