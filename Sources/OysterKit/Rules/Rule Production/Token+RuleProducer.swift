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

public extension Token {
    /**
     Creates an instance of the rule producer that will generate the token when satisfied
     
     - Parameter rule: The rule (or thing that can become a rule)
     - Returns: A rule
    */
    public func from(_ rule:RuleProducer)->BehaviouralRule{
        let intermediate = rule.rule(with: Behaviour(.structural(token: self), cardinality: rule.behaviour.cardinality, negated: rule.behaviour.negate, lookahead: rule.behaviour.lookahead), annotations: rule.annotations)
        
        if intermediate.behaviour.negate {
            print("Warning: Cannot create a token from a negated rule")
            return intermediate.scan()
        }
        
        return intermediate
    }
}

public extension RuleProducer {
    /**
     Changes the behaviour (or creates a rule with the behaviour) to create a token.
     
     - Parameter rule: The rule (or thing that can become a rule)
     - Returns: A rule
     */
    public func parse(as token:Token)->BehaviouralRule{
        return token.from(self)
    }
}
