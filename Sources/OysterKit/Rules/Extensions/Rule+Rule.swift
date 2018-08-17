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
 Lookahead operator for BehaviouralRules
 */
prefix  operator >>
prefix  operator !
prefix  operator -
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
