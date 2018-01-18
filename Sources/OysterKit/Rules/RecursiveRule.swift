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
public class RecursiveRule : Rule{
    
    /// The initializer block responsible for creating the rule
    private var initBlock : (()->Rule)?
    
    /// Creates a new instance of the rule. If you use this initializer then you should subsequently (when possible) set `surrogateRule`
    public init(){
        
    }
    
    /**
     Creates a new instance providing a closure which will create the actual rule when the rule is first used
     
     Parameters initializeWith: The closure to be used once it is safe to do so
    */
    public init(initializeWith lazyBlock:(()->Rule)?){
        self.initBlock = lazyBlock
    }
    
    /// The surrogate matcher
    private var _matcher     : ((_ lexer : LexicalAnalyzer, _ ir:IntermediateRepresentation) throws -> MatchResult)?
    
    /// The surrogate token. This MUST use forced unwrapping as there must always be a token
    private var _produces    : Token!
    
    /// The surrogate annotations
    private var _annotations : RuleAnnotations?
    
    /// Initiales the various delegated surrogate methods based on the lazily initialized rule
    private final func lazyInit(_ initBlock: ()->Rule){
        let rule = initBlock()
        _matcher     = rule.match
        _produces    = rule.produces
        self.initBlock = nil
    }
    
    /// Always appears to be `nil` when read, but when set applies the matcher methods etc from the supplied rule to this so that the `RecursiveRule` behaves
    /// exactly like the original rule.
    public var surrogateRule : Rule? {
        get{
            return nil
        }
        set {
            guard let  newRule = newValue else {
                return
            }
            initBlock = nil
            _matcher = newRule.match
            _produces = newRule.produces
        }
    }
    
    /// Delegated to the the surrogate rule
    public func match(with lexer: LexicalAnalyzer, for ir: IntermediateRepresentation) throws -> MatchResult {
        if let initBlock = initBlock {
            lazyInit(initBlock)
        }
        
        return try _matcher?(lexer, ir) ?? MatchResult.failure(atIndex: lexer.index)
    }
    
    /// Delegated to the the surrogate rule
    public var produces: Token {
        if let initBlock = initBlock {
            lazyInit(initBlock)
        }
        
        if _produces == nil {
            enum DummyToken : Int, Token { case value }
            print("Warning having to create a dummy token because the rule doesn't produce anything\n\t\(self)")
            return DummyToken.value
        }
        
        return _produces
    }
    
    /// Delegated to the the surrogate rule
    public var annotations: RuleAnnotations{
        get {
            return _annotations ?? [:]
        }
        set{
            _annotations = newValue
        }
    }
    
    
}
