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

public extension Rule {
    /**
     Creates a new instance of the rule annotated with the specified annotations.
     If you supply annotations that impact scanning (token, void, transient), they
     will be filtered out, but applied to the resultant behaviour.
     
     - Parameter annotations: The desired annotations
     - Returns: A new instance of the rule with the specified annotations
     */
    public func annotatedWith(_ annotations:RuleAnnotations)->Rule{
        var resultantRule : Rule = self
        var filterOut = [RuleAnnotation]()
        
        for (annotation,value) in annotations {
            switch annotation {
            case .transient,.void:
                filterOut.append(annotation)
                switch value {
                case .bool(let value):
                    if !value {
                        continue
                    }
                    fallthrough
                case .set:
                    if case .void = annotation {
                        resultantRule = resultantRule.skip()
                    } else {
                        resultantRule = resultantRule.scan()
                    }
                default:
                    #warning("This should be a log entry")
                    print("Warning: \(annotation) supplied with \(value) when only supports .set")
                }
            case .token:
                filterOut.append(annotation)
                switch value {
                case .string(let stringValue):
                    resultantRule = resultantRule.parse(as: LabelledToken(withLabel: stringValue))
                default:
                    #warning("This should be a log entry")
                    print("Warning: \(annotation) supplied with \(value) when only supports .string")
                    resultantRule = resultantRule.parse(as: LabelledToken(withLabel: "\(value)"))
                }
            default: break
            }
        }
        
        return resultantRule.rule(with: nil, annotations: annotations.filter({!filterOut.contains($0.key)}))
    }
    
    /**
     Creates a new instance of the rule that requires matches of the specified
     cardinality
     
     - Parameter cardinality: The desired cardinalitiy
     - Returns: The new rule instance
     */
    public func require(_ cardinality:Cardinality)->Rule{
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
public prefix func >>(rule:Rule)->Rule{
    return rule.lookahead()
}

public extension Rule{
    /**
     Creates a new instance of the rule set to have lookahead behaviour
     
     // Creates a lookahead version of of the rule
     let lookahead = -CharacterSet.letters.lookahead()
     
     - Returns: A new version of the rule
     */
    public func lookahead()->Rule{
        return rule(with: Behaviour(.scanning, cardinality: behaviour.cardinality, negated: behaviour.negate, lookahead: true), annotations: annotations)
    }

    /**
     Creates a new instance of the rule which negates its match.
     Note that negate does not "toggle", that is !!rule != rule.
     
     // Creates a negated version of of the rule
     let notLetter = CharacterSet.letters.negate()
     
     - Returns: A new version of the rule
     */
    public func negate()->Rule{
        return rule(with: Behaviour(behaviour.kind, cardinality: behaviour.cardinality, negated: true, lookahead: behaviour.lookahead), annotations: annotations)
    }
    
    /**
     Creates a new instance of the rule which skips.
     
     // Creates a skipping version of of the rule
     let skipLetters = CharacterSet.letters.skip()
     
     - Returns: A new version of the rule
     */
    public func skip()->Rule{
        return rule(with: Behaviour(.skipping, cardinality: behaviour.cardinality, negated: behaviour.negate, lookahead: behaviour.lookahead), annotations: annotations)
    }
    
    /**
     Creates a new instance of the rule which scans.
     
     // Creates a scanning version of of the rule
     let scanLetters = CharacterSet.letters.scan()
     
     - Returns: A new version of the rule
     */
    public func scan()->Rule{
        return rule(with: Behaviour(.scanning, cardinality: behaviour.cardinality, negated: behaviour.negate, lookahead: behaviour.lookahead), annotations: annotations)
    }
    
    public func reference(_ kind:Behaviour.Kind, annotations: RuleAnnotations? = nil)->Rule{
        return ReferenceRule(Behaviour(kind, cardinality: .one, negated: false, lookahead: false), and: annotations ?? [:], for: self)
    }
}

/**
 Creates a new instance of the rule which negates its match.
 Note that negate does not "toggle", that is !!rule != rule
 
 // Creates a negated version of of the rule
 let notLetter = !CharacterSet.letters.skip()
 
 - Parameter rule:The rule to apply to
 - Returns: A new version of the rule
 */
public prefix func !(rule:Rule)->Rule{
    return rule.negate()
}

/**
 Creates a new instance of the rule which skips.
 
 // Creates a skipping version of of the rule
 let skippingRule = -scanningRule
 
 - Parameter rule:The rule to apply to
 - Returns: A new version of the rule
 */
public prefix func -(rule: Rule)->Rule{
    return rule.skip()
}

/**
 Creates a new instance of the rule which scans.
 
 // Creates a scanning version of of the rule
 let scanningRule = ~parsingRule
 
 - Parameter rule:The rule to apply to
 - Returns: A new version of the rule
 */
public prefix func ~(rule : Rule)->Rule{
    return rule.scan()
}

// Extends collections of terminals to support creation of Choice scanners
extension Array where Element == Rule {
    /**
     Creates a rule that is satisfied if one of the rules in the araray
     (which are evaluated in order) is matched
     */
    public var choice : Rule{
        return ChoiceRule(Behaviour(.scanning), and: [:], for: map({$0.rule(with: nil, annotations: nil)}))
    }
    
    /**
     Creates a rule that is satisified if all rules in the array are
     met, in order.
     */
    public var sequence : Rule{
        return SequenceRule(Behaviour(.scanning), and: [:], for: map({$0.rule(with: nil, annotations: nil)}))
    }
}

extension Rule{
    /**
     Creates a new instance of the rule with the specified behavioural attributes
     all other attributes maintained. If any of the supplied parameters are nil
     the current values will be used. All parameters default to nil.
     
     - Parameter kind: The kind of behaviour
     - Parameter negated: `true` if the results of `test()` should be negated
     - Parameter lookahead: Is lookahead behaviour required
     */
    internal func newBehaviour(_ kind:Behaviour.Kind?=nil, negated:Bool? = nil, lookahead:Bool? = nil)->Rule{
        return rule(with: Behaviour(kind ?? behaviour.kind, cardinality: behaviour.cardinality, negated: negated ?? behaviour.negate, lookahead: lookahead ?? behaviour.lookahead), annotations: annotations)
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
    internal func newBehaviour(_ kind:Behaviour.Kind?=nil, cardinality: ClosedRange<Int>, negated:Bool? = nil, lookahead:Bool? = nil)->Rule{
        return rule(with: behaviour.instanceWith(kind, cardinality: cardinality, negated: negated, lookahead: lookahead), annotations: annotations)
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
    internal func newBehaviour(_ kind:Behaviour.Kind?=nil, cardinality: PartialRangeFrom<Int>, negated:Bool? = nil, lookahead:Bool? = nil)->Rule{
        return rule(with: behaviour.instanceWith(kind, cardinality: cardinality, negated: negated, lookahead: lookahead), annotations: annotations)
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
    internal func newBehaviour(_ kind:Behaviour.Kind?=nil, cardinality: Cardinality, negated:Bool? = nil, lookahead:Bool? = nil)->Rule{
        
        return rule(with: Behaviour(kind ?? behaviour.kind, cardinality: cardinality, negated: negated ?? behaviour.negate, lookahead: lookahead ?? behaviour.lookahead), annotations: annotations)
    }
    
    /**
     Creates a new instance of the rule with the specified behaviour but
     all other attributes maintained.
     
     - Parameter behaviour: The new behaviour
     */
    #warning("Refactor to rule(with behaviour)")
    internal func instanceWith(with behaviour:Behaviour)->Rule{
        return rule(with: behaviour, annotations: nil)
    }
    
    /**
     Creates a new instance of the rule with the specified annotations but
     all other attributes maintained.
     
     - Parameter annotations: The new annotations
     */
    #warning("Get rid of this, it's the same as annotate with")
    internal func instanceWith(annotations:RuleAnnotations)->Rule{
        return annotatedWith(annotations)
    }
}
