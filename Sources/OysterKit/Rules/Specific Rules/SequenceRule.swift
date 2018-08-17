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

public final class SequenceRule : BehaviouralRule {
    public var behaviour: Behaviour
    public var annotations: RuleAnnotations
    public var sequence : [BehaviouralRule]
    
    public init(_ behaviour:Behaviour, and annotations:RuleAnnotations, for sequence:[BehaviouralRule]){
        self.behaviour = behaviour
        self.annotations = annotations
        self.sequence = sequence
    }
    
    public func test(with lexer: LexicalAnalyzer, for ir: IntermediateRepresentation) throws {
//        print("Evaluating: \(self)")
        for rule in sequence {
//            print("\tTrying \(rule)")
            _ = try rule.match(with: lexer, for: ir)
//            print("\tPassed")
        }
    }
    
    public func rule(with behaviour: Behaviour?, annotations: RuleAnnotations?) -> BehaviouralRule {
        return SequenceRule(behaviour ?? self.behaviour, and: annotations ?? self.annotations, for: sequence)
    }
    
    /// A textual description of the rule
    public var description: String {
        let    match = sequence.map({$0.description}).joined(separator: " ")
        let    annotates = "\(annotations.isEmpty ? "" : "\(annotations.description) ")"
        if sequence.count > 1 {
            return annotates + behaviour.describe(match:"(\(match))")
        } else {
            return annotates + behaviour.describe(match: match)
        }
    }
    
    /// An abreviated description of the rule
    public var shortDescription: String{
        if let produces = behaviour.token {
            return behaviour.describe(match: "\(produces)", requiresStructuralPrefix: false)
        }
        let match = sequence.map({$0.shortDescription}).joined(separator: " ")
        return sequence.count > 1 ? behaviour.describe(match: "(\(match))") : behaviour.describe(match: match)
    }
}
