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
 When a rule definition calls itself whilst evaluating itself (left hand recursion) you cannot create the rule directly as it will become caught in an infinite look (creating instances of itself, which create instances of itself etc until the stack is empty).  To avoid this a rule can use this wrapper to manage lazy initialization of itself. The recursive rule enables a reference to be added on the RHS, but the actual rule will not be initiialized until later, and this wrapper will then call that lazily initalized rule.
 */
public final class RecursiveRule : Rule, CustomStringConvertible{

    

    /// Creates a new instance of a rule. If you use this initializer then you should subsequently (when possible) set `surrogateRule`
    /// - Parameter token: The token the rule will create.
    public init(stubFor behaviour:Behaviour, with annotations:RuleAnnotations){
        _behaviour = behaviour
        _annotations = annotations
    }
    
    /// The surrogate matcher
    private var rule     : Rule?
    
    /// The surrogate annotations. When the surrogate is assigned its annotations will be replaced with these on the new instance
    private var _annotations : RuleAnnotations
    
    /// The surrogate token. This MUST use forced unwrapping as there must always be a token
    private var _behaviour    : Behaviour
    
    /// The rule, which can be assigned at any point before actual parsing, to be used. When a new value is assigned to the rule a
    /// new instance is created (calling ``instance(token, annotations)) with the token and annotations assigned at construction
    public var surrogateRule : Rule? {
        get{
            return rule
        }
        set {
            rule = newValue?.rule(with: _behaviour, annotations: annotations)
        }
    }
    
    public var description: String{
        if let rule = rule {
            return behaviour.describe(match: "🔃\(rule.shortDescription)", annotatedWith: rule.annotations)
        } else {
            return shortDescription
        }
    }
    
    /// An abreviated description of the rule
    public var shortDescription: String{
        return rule?.shortDescription ?? _behaviour.describe(match: "❌", annotatedWith: rule?.annotations ?? [:])
    }

    
    /// Delegated to the the surrogate rule
    public func test(with lexer: LexicalAnalyzer, for ir: IntermediateRepresentation) throws {
        guard let rule = rule else {
            throw ProcessingError.undefined(message: "Recursive rule for \(behaviour.kind) has no surrogate set", at: lexer.index, causes: [])
        }
        try rule.test(with: lexer, for: ir)
    }
    
    public func match(with lexer: LexicalAnalyzer, for ir: IntermediateRepresentation) throws {
        guard let rule = rule else {
            throw ProcessingError.undefined(message: "Recursive rule for \(behaviour.kind) has no surrogate set", at: lexer.index, causes: [])
        }
        try rule.test(with: lexer, for: ir)
    }
    
    /// Delegated to the the surrogate rule
    public var behaviour: Behaviour {
        get {
            return rule?.behaviour ?? _behaviour
        }
    }

    /// Delegated to the the surrogate rule
    public var annotations: RuleAnnotations{
        return rule?.annotations ?? _annotations
    }
    
    /// Creates a new instance of itself
    public func rule(with behaviour: Behaviour?, annotations: RuleAnnotations?) -> Rule {
        return RecursiveRuleInstance(original: self,behaviour: behaviour ?? self.behaviour, annotations: annotations ?? self.annotations)
    }
        
    
    
}
