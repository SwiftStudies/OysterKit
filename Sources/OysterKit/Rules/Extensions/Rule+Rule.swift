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

enum Precidence{
    case negate(Bool), cardinality(Cardinality), annotation(RuleAnnotations), structure(Behaviour.Kind), lookahead(Bool)
    
    func apply(to rule:BehaviouralRule)->(inner:(behaviour:Behaviour,annotations:RuleAnnotations),outer:(behaviour:Behaviour,annotations:RuleAnnotations)){
        let kind        : (inner:Behaviour.Kind, outer:Behaviour.Kind)
        let cardinality : (inner:Cardinality, outer:Cardinality)
        let negate      : (inner:Bool, outer:Bool)
        let lookahead   : (inner:Bool, outer:Bool)
        let annotations : (inner:RuleAnnotations, outer:RuleAnnotations)
        
        switch self {
        case .negate(let newValue):
            negate      = (inner:newValue,                      outer:false)
            cardinality = (inner:.one,                          outer:rule.behaviour.cardinality)
            annotations = (inner: [:],                          outer:rule.annotations)
            kind        = (inner: .scanning,                    outer:rule.behaviour.kind)
            lookahead   = (inner: false,                        outer:rule.behaviour.lookahead)
        case .cardinality(let newValue):
            negate      = (inner:rule.behaviour.negate,         outer:false)
            cardinality = (inner:newValue,                      outer:.one)
            annotations = (inner: [:],                          outer:rule.annotations)
            kind        = (inner: .scanning,                    outer:rule.behaviour.kind)
            lookahead   = (inner: false,                        outer:rule.behaviour.lookahead)
        case .annotation(let newValue):
            negate      = (inner:rule.behaviour.negate,         outer:false)
            cardinality = (inner:rule.behaviour.cardinality,    outer:.one)
            annotations = (inner: newValue,                     outer:rule.annotations)
            kind        = (inner: .scanning,                    outer:rule.behaviour.kind)
            lookahead   = (inner: false,                        outer:rule.behaviour.lookahead)
        case .structure(let newValue):
            negate      = (inner:rule.behaviour.negate,         outer:false)
            cardinality = (inner:rule.behaviour.cardinality,    outer:.one)
            annotations = (inner:rule.annotations,              outer: [:])
            kind        = (inner:rule.behaviour.kind,           outer:newValue)
            lookahead   = (inner: false,                        outer:rule.behaviour.lookahead)
        case .lookahead(let newValue):
            negate      = (inner:rule.behaviour.negate,         outer:false)
            cardinality = (inner:rule.behaviour.cardinality,    outer:.one)
            annotations = (inner:rule.annotations,              outer: [:])
            kind        = (inner:rule.behaviour.kind,           outer:.scanning)
            lookahead   = (inner:rule.behaviour.lookahead,      outer:newValue)
        }
        
        return (
            inner: (Behaviour(kind.inner, cardinality: cardinality.inner, negated: negate.inner, lookahead: lookahead.inner),annotations.inner),
            outer: (Behaviour(kind.outer, cardinality: cardinality.outer, negated: negate.outer, lookahead: lookahead.outer),annotations.outer)
        )
    }
    
    func modify(_ rule:BehaviouralRule)->BehaviouralRule{
        let precidence = apply(to: rule)
        
        let innerRule = rule.instanceWith(behaviour: precidence.inner.behaviour, annotations: precidence.inner.annotations)
        
        return ClosureRule(with: precidence.outer.behaviour, and: precidence.outer.annotations, using: { (lexer, ir) in
            try _ = innerRule.match(with: lexer, for: ir)
        })
    }
}

/**
 Lookahead operator for BehaviouralRules
 */
prefix operator >>
prefix operator !
prefix operator -

public extension BehaviouralRule {
    /**
     Creates a new instance of the rule annotated with the specified annotations
     - Parameter annotations: The desired annotations
     - Returns: A new instance of the rule with the specified annotations
     */
    public func annotatedWith(_ annotations:RuleAnnotations)->BehaviouralRule{
        return instanceWith(annotations: annotations)
    }
}

public prefix func >>(rule:BehaviouralRule)->BehaviouralRule{
    if rule.behaviour.cardinality == .one {
        return rule.newBehaviour(nil, negated: nil, lookahead: true)
    }

    return Precidence.lookahead(true).modify(rule)
}

public prefix func !(rule:BehaviouralRule)->BehaviouralRule{
    if rule.behaviour.cardinality == .one {
        return rule.newBehaviour(nil, negated: true, lookahead: nil)
    }
    
    return Precidence.negate(true).modify(rule)    
}

public prefix func -(rule : BehaviouralRule)->BehaviouralRule{
    if rule.behaviour.cardinality == .one {
        return rule.instanceWith(behaviour: Behaviour(.skipping, cardinality: rule.behaviour.cardinality, negated: rule.behaviour.negate, lookahead: rule.behaviour.lookahead), annotations: rule.annotations)
    }

    return Precidence.structure(.skipping).modify(rule)    
}
