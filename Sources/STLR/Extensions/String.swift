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

import OysterKit

public extension String {
    /**
     Creates a rule, producing the specified token, by compiling the string as STLR source
     
     - Parameter token: The token to produce
     - Returns: `nil` if compilation failed
    */
    @available(*,deprecated,message: "Use .dynamicRule(Behaviour.Kind) instead")
    public func  dynamicRule(token:TokenType)->Rule? {
        let grammarDef = "grammar Dynamic\n_ = \(self)"
        
        let compiler = STLRParser(source: grammarDef)
        
        let ast = compiler.ast
        
        guard ast.grammar.rules.count > 0 else {
            return nil
        }
        
        return ast.grammar.dynamicRules[0].parse(as:token)
    }
    
    /**
     Creates a rule of the specified kind (e.g. ```.structural(token)```)
     
     - Parameter kind: The kind of the rule
     - Returns: `nil` if compilation failed
     */
    public func dynamicRule(_ kind:Behaviour.Kind) throws ->Rule{
        let compiled = try STLR.build("grammar Dynamic\n_ = \(self)")

        
        
        guard let rule = compiled.grammar.dynamicRules.first else {
            throw TestError.interpretationError(message: "No rules created from \(self)", causes: [])
        }
        
        return rule.rule(with: Behaviour(kind, cardinality: rule.behaviour.cardinality, negated: rule.behaviour.negate, lookahead: rule.behaviour.lookahead), annotations: rule.annotations)
    }
}

