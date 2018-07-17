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





public typealias RuleTest = (LexicalAnalyzer, IntermediateRepresentation) throws -> Void

public final class BlockRule : ExtendedRule {
    public let annotations: RuleAnnotations
    public let behaviour: Behaviour
    public let matcher : RuleTest

    public init(with behaviour:Behaviour, and annotations:RuleAnnotations = [:], using matcher:@escaping RuleTest){
        self.behaviour = behaviour
        self.annotations = annotations
        self.matcher = matcher
        
        assert((structural && behaviour.lookahead) == false, "Lookahead rules cannot be structural as their match range will always be 0")
        assert((behaviour.negate && behaviour.cardinality.minimumMatches == 0) == false, "Cannot negate an optional (minimum cardinality is 0) rule (negating an ignorable failure makes no sense).")
    }
    
    public func instanceWith(behaviour: Behaviour? = nil, annotations: RuleAnnotations? = nil) -> BlockRule {
        let newBehaviour = behaviour ?? self.behaviour
        let newAnnotations = annotations ?? self.annotations
        
        return BlockRule(with: newBehaviour, and: newAnnotations, using: matcher)
    }
    
    public func test(with lexer: LexicalAnalyzer, for ir: IntermediateRepresentation) throws {
        try matcher(lexer,ir)
    }
}
