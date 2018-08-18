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

/**
 Types that implement the `RuleProducer` protocol should provide convience functions for
 generating rules.
 */
public protocol RuleProducer {
    /**
     Creates a rule with the specified behaviour and annotations.
     
     - Parameter behaviour: The behaviour for the new instance, if nil the rule should
     use the default behaviour for the producer.
     - Parameter annotations: The annotations for the new rule, if nil the rule
     should use the default behaviour for the producer.
     - Returns: A new instance with the specified behaviour and annotations.
     */
    func rule(with behaviour:Behaviour?, annotations:RuleAnnotations?)->BehaviouralRule
    
    /// The default behaviour of the producer
    var defaultBehaviour : Behaviour { get }
    
    /// The default annotations of the producer
    var defaultAnnotations : RuleAnnotations { get } 
}

/**
 Operators for all rule producers
 */

/// Lookahead
prefix  operator >>

/// Negate
prefix  operator !

/// Skip
prefix  operator -

/// Scan
prefix  operator ~

public extension RuleProducer {
    /**
     Creates a new instance of the rule annotated with the specified annotations
     - Parameter annotations: The desired annotations
     - Returns: A new instance of the rule with the specified annotations
     */
    public func annotatedWith(_ annotations:RuleAnnotations)->BehaviouralRule{
        return rule(with: nil, annotations: annotations)
    }
    
    /**
     Creates a new instance of the rule that requires matches of the specified
     cardinality
     
     - Parameter cardinality: The desired cardinalitiy
     - Returns: The new rule instance
     */
    public func require(_ cardinality:Cardinality)->BehaviouralRule{
        return newBehaviour(cardinality: cardinality)
    }
}

/**
 Creates a new instance of the rule set to have lookahead behaviour
 
 // Creates a lookahead version of of the rule
 let lookahead = >>CharacterSet.letters.skip()
 
 - Parameter rule:The rule to apply to
 - Returns: A new version of the rule
 */
public prefix func >>(rule:RuleProducer)->BehaviouralRule{
    return rule.rule(with: Behaviour(.scanning, cardinality: rule.defaultBehaviour.cardinality, negated: rule.defaultBehaviour.negate, lookahead: true), annotations: rule.defaultAnnotations)
}

/**
 Creates a new instance of the rule which negates its match.
 Note that negate does not "toggle", that is !!rule != rule
 
 // Creates a negated version of of the rule
 let notLetter = !CharacterSet.letters.skip()
 
 - Parameter rule:The rule to apply to
 - Returns: A new version of the rule
 */
public prefix func !(rule:RuleProducer)->BehaviouralRule{
    return rule.rule(with: Behaviour(rule.defaultBehaviour.kind, cardinality: rule.defaultBehaviour.cardinality, negated: true, lookahead: rule.defaultBehaviour.lookahead), annotations: rule.defaultAnnotations)
}

/**
 Creates a new instance of the rule which skips.
 
 // Creates a skipping version of of the rule
 let skipLetters = -CharacterSet.letters.scan(.zeroOrMore)
 
 - Parameter rule:The rule to apply to
 - Returns: A new version of the rule
 */
public prefix func -(rule: RuleProducer)->BehaviouralRule{
    return rule.rule(with: Behaviour(.skipping, cardinality: rule.defaultBehaviour.cardinality, negated: rule.defaultBehaviour.negate, lookahead: rule.defaultBehaviour.lookahead), annotations: rule.defaultAnnotations)
}

/**
 Creates a new instance of the rule which scans.
 
 // Creates a scanning version of of the rule
 let scanLetters = -CharacterSet.letters.token(myToken, .zeroOrMore)
 
 - Parameter rule:The rule to apply to
 - Returns: A new version of the rule
 */
public prefix func ~(rule : RuleProducer)->BehaviouralRule{
    return rule.rule(with: Behaviour(.scanning, cardinality: rule.defaultBehaviour.cardinality, negated: rule.defaultBehaviour.negate, lookahead: rule.defaultBehaviour.lookahead), annotations: rule.defaultAnnotations)
}

// Extends collections of terminals to support creation of Choice scanners
extension Array where Element == RuleProducer {
    /**
     Creates a rule that is satisfied if one of the rules in the araray
     (which are evaluated in order) is matched
     */
    public var choice : BehaviouralRule{
        return ChoiceRule(Behaviour(.scanning), and: [:], for: map({$0.rule(with: nil, annotations: nil)}))
    }
    
    /**
     Creates a rule that is satisified if all rules in the array are
     met, in order.
     */
    public var sequence : BehaviouralRule{
        return SequenceRule(Behaviour(.scanning), and: [:], for: map({$0.rule(with: nil, annotations: nil)}))
    }
}

extension RuleProducer{
    /**
     Creates a new instance of the rule with the specified behavioural attributes
     all other attributes maintained. If any of the supplied parameters are nil
     the current values will be used. All parameters default to nil.
     
     - Parameter kind: The kind of behaviour
     - Parameter negated: `true` if the results of `test()` should be negated
     - Parameter lookahead: Is lookahead behaviour required
     */
    internal func newBehaviour(_ kind:Behaviour.Kind?=nil, negated:Bool? = nil, lookahead:Bool? = nil)->BehaviouralRule{
        return rule(with: Behaviour(kind ?? defaultBehaviour.kind, cardinality: defaultBehaviour.cardinality, negated: negated ?? defaultBehaviour.negate, lookahead: lookahead ?? defaultBehaviour.lookahead), annotations: defaultAnnotations)
    }
    
    /**
     Creates a new instance of the rule with the specified behavioural attributes
     all other attributes maintained. If any of the supplied parameters are nil
     the current values will be used. All parameters default to nil.
     
     - Parameter kind: The kind of behaviour
     - Parameter cardinality: A closed range specifying the range of matches required
     - Parameter negated: `true` if the results of `test()` should be negated
     - Parameter lookahead: Is lookahead behaviour required
     */
    internal func newBehaviour(_ kind:Behaviour.Kind?=nil, cardinality: ClosedRange<Int>, negated:Bool? = nil, lookahead:Bool? = nil)->BehaviouralRule{
        return rule(with: defaultBehaviour.instanceWith(kind, cardinality: cardinality, negated: negated, lookahead: lookahead), annotations: defaultAnnotations)
    }
    
    /**
     Creates a new instance of the rule with the specified behavioural attributes
     all other attributes maintained. If any of the supplied parameters are nil
     the current values will be used. All parameters default to nil.
     
     - Parameter kind: The kind of behaviour
     - Parameter cardinality: A partial range specifying the range of matches required with no maxium
     - Parameter negated: `true` if the results of `test()` should be negated
     - Parameter lookahead: Is lookahead behaviour required
     */
    internal func newBehaviour(_ kind:Behaviour.Kind?=nil, cardinality: PartialRangeFrom<Int>, negated:Bool? = nil, lookahead:Bool? = nil)->BehaviouralRule{
        return rule(with: defaultBehaviour.instanceWith(kind, cardinality: cardinality, negated: negated, lookahead: lookahead), annotations: defaultAnnotations)
    }
    
    /**
     Creates a new instance of the rule with the specified behavioural attributes
     all other attributes maintained. If any of the supplied parameters are nil
     the current values will be used. All parameters default to nil.
     
     - Parameter kind: The kind of behaviour
     - Parameter cardinality: A partial range specifying the range of matches required with no maxium
     - Parameter negated: `true` if the results of `test()` should be negated
     - Parameter lookahead: Is lookahead behaviour required
     */
    internal func newBehaviour(_ kind:Behaviour.Kind?=nil, cardinality: Cardinality, negated:Bool? = nil, lookahead:Bool? = nil)->BehaviouralRule{
        
        return rule(with: Behaviour(kind ?? defaultBehaviour.kind, cardinality: cardinality, negated: negated ?? defaultBehaviour.negate, lookahead: lookahead ?? defaultBehaviour.lookahead), annotations: defaultAnnotations)
    }
    
    /**
     Creates a new instance of the rule with the specified behaviour but
     all other attributes maintained.
     
     - Parameter behaviour: The new behaviour
     */
    internal func instanceWith(with behaviour:Behaviour)->BehaviouralRule{
        return rule(with: behaviour, annotations: nil)
    }
    
    /**
     Creates a new instance of the rule with the specified annotations but
     all other attributes maintained.
     
     - Parameter annotations: The new annotations
     */
    internal func instanceWith(annotations:RuleAnnotations)->BehaviouralRule{
        return rule(with: nil, annotations: annotations)
    }
}