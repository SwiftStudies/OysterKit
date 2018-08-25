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
 A `ChoiceRule` will match if one of the child rules is matched. It can be thought of as a logical OR.
 */
public final class ChoiceRule : Rule {
    /// The behaviour of the rule
    public var behaviour: Behaviour
    /// Annotations on the rule
    public var annotations: RuleAnnotations
    /// The acceptable matches that would satisfy this rule
    public var choices : [Rule]
    
    /**
     Creates a new instance of the rule with the specified parameteres.
     
     - Parameter behaviour: The `Behaviour` for the rule
     - Parameter annotations: The `RuleAnnotations` on the rule
     - Parameter choices: The child rules, any one of which can satisfy this rule
     */
    public init(_ behaviour:Behaviour, and annotations:RuleAnnotations, for choices:[Rule]){
        self.behaviour = behaviour
        self.annotations = annotations
        self.choices = choices
    }
    
    /**
     The test will be satisfied if any one of the `choices` are satisfied. The child rules are evaluated
     in order.
     
     - Parameter lexer: The `LexicalAnalyzer` managing the scan head
     - Parameter ir: The IR building the AST
     */
    public func test(with lexer: LexicalAnalyzer, for ir: IntermediateRepresentation) throws {
        var errors = [Error]()
        for rule in choices {
            do {
                let _ = try rule.match(with: lexer, for: ir)
                return
            } catch {
                errors.append(error)
            }
        }
        throw TestError(with: behaviour, and: annotations, whenUsing: lexer, causes: errors)
    }
    
    /**
     Creates a new instance with the specified behaviour and annoations overriding the current instance's
     if specified
     
     - Parameter behaviour: If specified will replace this instance's behaviour in the new instance
     - Parameter annotations: If specified will replace this instance's annotations in the new instance
    */
    public func rule(with behaviour: Behaviour?, annotations: RuleAnnotations?) -> Rule {
        return ChoiceRule(behaviour ?? self.behaviour, and: annotations ?? self.annotations, for: choices)
    }
    
    /// A textual description of the rule
    public var description: String {
        return "\(annotations.isEmpty ? "" : "\(annotations.description) ")"+behaviour.describe(match:"(\(choices.map({$0.description}).joined(separator: " | ")))")
    }
    
    /// An abreviated description of the rule
    public var shortDescription: String{
        if let produces = behaviour.token {
            return behaviour.describe(match: "\(produces)", requiresStructuralPrefix: false)
        }
        let match = choices.map({$0.shortDescription}).joined(separator: "|")
        return behaviour.describe(match: "(\(match))")
    }

}
