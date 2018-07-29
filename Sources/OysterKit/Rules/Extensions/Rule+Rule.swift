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
            negate      = (inner:false,                         outer:newValue)
            cardinality = (inner:.one,                          outer:rule.behaviour.cardinality)
            annotations = (inner: [:],                          outer:rule.annotations)
            kind        = (inner: .scanning,                    outer:rule.behaviour.kind)
            lookahead   = (inner: false,                        outer:rule.behaviour.lookahead)
        case .cardinality(let newValue):
            negate      = (inner:rule.behaviour.negate,         outer:false)
            cardinality = (inner:.one,                          outer:newValue)
            annotations = (inner: [:],                          outer:rule.annotations)
            kind        = (inner: .scanning,                    outer:rule.behaviour.kind)
            lookahead   = (inner: false,                        outer:rule.behaviour.lookahead)
        case .annotation(let newValue):
            negate      = (inner:rule.behaviour.negate,         outer:false)
            cardinality = (inner:rule.behaviour.cardinality,    outer:.one)
            annotations = (inner: rule.annotations,             outer:newValue)
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
prefix  operator >>
prefix  operator !
prefix  operator -
prefix  operator ~

public extension BehaviouralRule {
    /**
     Creates a new instance of the rule annotated with the specified annotations
     - Parameter annotations: The desired annotations
     - Returns: A new instance of the rule with the specified annotations
     */
    public func annotatedWith(_ annotations:RuleAnnotations)->BehaviouralRule{
        if behaviour.cardinality == .one {
            return instanceWith(annotations: annotations)
        }
        
        return Precidence.annotation(annotations).modify(self)
    }
    
    /**
     An instance of the rule with a cardinality of one
     */
    public var one : BehaviouralRule{
        return newBehaviour(cardinality: 1...1)
    }

    /**
     An instance of the rule with a cardinality of one or more
     */
    public var oneOrMore : BehaviouralRule{
        return newBehaviour(cardinality: 1...)
    }

    /**
     An instance of the rule with a cardinality of zero or more
     */
    public var zeroOrMore : BehaviouralRule{
        return newBehaviour(cardinality: 0...)
    }

    /**
     An instance of the rule with a cardinality of zero or one
     */
    public var optional : BehaviouralRule {
        return newBehaviour(cardinality: 0...1)
    }
}

/**
 Creates a new instance of the rule set to have lookahead behaviour
 
    // Creates a lookahead version of of the rule
    let lookahead = >>CharacterSet.letters.skip()
 
 - Parameter rule:The rule to apply to
 - Returns: A new version of the rule
 */
public prefix func >>(rule:BehaviouralRule)->BehaviouralRule{
    if rule.behaviour.cardinality == .one {
        return rule.newBehaviour(nil, negated: nil, lookahead: true)
    }

    return Precidence.lookahead(true).modify(rule)
}

/**
 Creates a new instance of the rule which negates its match.
 Note that negate does not "toggle", that is !!rule != rule
 
 // Creates a negated version of of the rule
 let notLetter = !CharacterSet.letters.skip()
 
 - Parameter rule:The rule to apply to
 - Returns: A new version of the rule
 */
public prefix func !(rule:BehaviouralRule)->BehaviouralRule{
    if rule.behaviour.cardinality == .one {
        return rule.newBehaviour(nil, negated: true, lookahead: nil)
    }
    
    return Precidence.negate(true).modify(rule)    
}

/**
 Creates a new instance of the rule which skips.
 
 // Creates a skipping version of of the rule
 let skipLetters = -CharacterSet.letters.scan(.zeroOrMore)
 
 - Parameter rule:The rule to apply to
 - Returns: A new version of the rule
 */
public prefix func -(rule : BehaviouralRule)->BehaviouralRule{
    if rule.behaviour.cardinality == .one {
        return rule.instanceWith(behaviour: Behaviour(.skipping, cardinality: rule.behaviour.cardinality, negated: rule.behaviour.negate, lookahead: rule.behaviour.lookahead), annotations: rule.annotations)
    }

    return Precidence.structure(.skipping).modify(rule)    
}

/**
 Creates a new instance of the rule which scans.
 
 // Creates a scanning version of of the rule
 let scanLetters = -CharacterSet.letters.token(myToken, .zeroOrMore)
 
 - Parameter rule:The rule to apply to
 - Returns: A new version of the rule
 */
public prefix func ~(rule : BehaviouralRule)->BehaviouralRule{
    if rule.behaviour.cardinality == .one {
        return rule.instanceWith(behaviour: Behaviour(.scanning, cardinality: rule.behaviour.cardinality, negated: rule.behaviour.negate, lookahead: rule.behaviour.lookahead), annotations: rule.annotations)
    }
    
    return Precidence.structure(.scanning).modify(rule)
}

public extension Token {
    /**
     Creates a rule which will generate this token if matched
     
     - Parameter rule:The rule which must be matched in order to generate the tokekn
     - Returns: An instance of the rule
     */
    func `if`(_ rule:BehaviouralRule)->BehaviouralRule{
        if rule.behaviour.cardinality == .one {
            return rule.instanceWith(behaviour: Behaviour(.structural(token: self), cardinality: rule.behaviour.cardinality, negated: rule.behaviour.negate, lookahead: rule.behaviour.lookahead), annotations: rule.annotations)
        }
        
        return Precidence.structure(.structural(token: self)).modify(rule)
    }
}

// Extends collections of terminals to support creation of Choice scanners
extension Array where Element == BehaviouralRule {
    /**
     Creates a rule that tests for the producer (with the specified cardinality)
     that will produce the defined token
     
     - Parameter token: The token to be produced
     - Parameter cardinality: The desired cardinality of the match
     - Returns: A rule
     */
    public func token(_ token: Token, from cardinality: Cardinality = .one) -> BehaviouralRule {
        return sequence.newBehaviour(.structural(token:token), cardinality: cardinality)
    }
    
    /**
     Creates a rule that tests for the producer (with the specified cardinality)
     that includes the range of the result in any matched string
     
     - Parameter cardinality: The desired cardinality of the match
     - Returns: A rule
     */
    public func scan(_ cardinality: Cardinality = .one) -> BehaviouralRule {
        return sequence.newBehaviour(.scanning, cardinality: cardinality)
    }
    
    /**
     Creates a rule that tests for the producer (with the specified cardinality)
     moving the scanner head forward but not including the range of the result
     in any match.
     
     - Parameter cardinality: The desired cardinality of the match
     - Returns: A rule
     */
    public func skip(_ cardinality: Cardinality = .one) -> BehaviouralRule {
        return sequence.newBehaviour(.skipping, cardinality: cardinality)
    }
    
    /**
     Creates a rule that is satisfied if one of the rules in the araray
     (which are evaluated in order) is matched
    */
    public var oneOf : BehaviouralRule{
        return ChoiceRule(Behaviour(.scanning), and: [:], for: self)
    }
    
    /**
     Creates a rule that is satisified if all rules in the array are
     met, in order. 
     */
    public var sequence : BehaviouralRule{
        return SequenceRule(Behaviour(.scanning), and: [:], for: self)
    }

}
