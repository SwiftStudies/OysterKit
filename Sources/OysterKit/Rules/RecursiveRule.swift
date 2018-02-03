//    Copyright (c) 2016, RED When Excited
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
public class RecursiveRule : Rule, CustomStringConvertible{
    
    /// Creates a new instance of a rule. If you use this initializer then you should subsequently (when possible) set `surrogateRule`
    public init(){
        _produces = transientTokenValue.token
    }
    
    /// Creates a new instance of a rule. If you use this initializer then you should subsequently (when possible) set `surrogateRule`
    /// - Parameter token: The token the rule will create.
    public init(stubFor token:Token){
        _produces = token
    }
    
    /// The surrogate matcher
    private var rule     : Rule?
    
    /// The surrogate token. This MUST use forced unwrapping as there must always be a token
    private var _produces    : Token
    
    /// Always appears to be `nil` when read, but when set applies the matcher methods etc from the supplied rule to this so that the `RecursiveRule` behaves
    /// exactly like the original rule.
    public var surrogateRule : Rule? {
        get{
            return rule
        }
        set {
            guard let  newRule = newValue else {
                return
            }
            rule = newRule
        }
    }
    
    public var description: String{
        // Can't actuall print rule because if there is a looping recursion it could go on forwever
        return "\(rule == nil ? "❌\(_produces)" : "🔃\(rule!.produces)")"
    }
    
    /// Delegated to the the surrogate rule
    public func match(with lexer: LexicalAnalyzer, for ir: IntermediateRepresentation) throws -> MatchResult {
        return try rule?.match(with: lexer, for: ir) ?? MatchResult.failure(atIndex: lexer.index)
    }
    
    /// Delegated to the the surrogate rule
    public var produces: Token {
        get {
            return rule?.produces ?? _produces
        }

    }
    
    /// Delegated to the the surrogate rule
    public var annotations: RuleAnnotations{
        get {
            if let rule = rule {
                return rule.annotations
            }
            return [ : ]
        }
        set{
            rule?.annotations = newValue
        }
    }
    
    
}
