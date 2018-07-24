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

/// A set of extensions to 'Rules' that allow you to easily modify the core behaviour of the rule (for example to add lookahead, make it void etc)
public extension Rule {
    
    /**
     Creates a new rule which is the same as this rule except that it consumes rather than generating tokens
     
     - Parameter annotations: Optional annotations on the generated rule
    */
    func consume(annotations:RuleAnnotations?=nil)->Rule{
        return ParserRule.consume(self, annotations)
    }
    
    /**
     Create a new rule wrapping the supplied rule which looks ahead rather than directly applying the rule

     - Parameter annotations: Optional annotations on the generated rule
     */
    func lookahead(annotations:RuleAnnotations?=nil)->Rule{
        return ParserRule.lookahead(self, annotations)
    }

    /**
     Creates a new rule making this rule optional
     
     - Parameter annotations: Optional annotations on the generated rule
     */
    func optional(annotations:RuleAnnotations?=nil)->Rule {
        return ParserRule.optional(produces: produces, self,annotations)
    }
    
    /**
     Creates a new rule making this rule logical inverse (that is, everything that didn't match it now does and vice versa)(
     
     - Parameter annotations: Optional annotations on the generated rule
     */
    func not(annotations:RuleAnnotations?=nil)->Rule {
        return ParserRule.not(produces: produces, self,annotations)
    }
    
    /**
     Creates a new rule making this rule logical inverse (that is, everything that didn't match it now does and vice versa) and changing the token that is produced by the rule
     
     - Parameter annotations: Optional annotations on the generated rule
     - Parameter token: The token the new rule should produce
     */
    func not(producing token:Token, annotations:RuleAnnotations?=nil)->Rule{
        return ParserRule.not(produces: token, self,annotations)
    }
    
    
    /**
     Creates a new rule wrapping this rule and requiring that it is repeated as specified
     
     - Parameter annotations: Optional annotations on the generated rule
     - Parameter min: The minimum number of matches of the matched rule to be satisfied
     - Parameter limit: The maxium number of matches before evaluation stops
     - Parameter producing: An alternative token to produce. If `nil` the wrapped rule's token will be used
     */
    func repeated(min:Int = 1, limit:Int? = nil, producing token:Token?  = nil, annotations:RuleAnnotations?=nil)->Rule{
        return ParserRule.repeated(produces: token ?? produces, self, min: min, limit: limit, annotations)
    }
    
    /**
     Creates a new rule wrapping this rule making it optional
     
     - Parameter annotations: Optional annotations on the generated rule
     - Parameter producing: An alternative token to produce. If `nil` the wrapped rule's token will be used
     */
    func optional(producing token:Token,annotations:RuleAnnotations?=nil)->Rule{
        return ParserRule.optional(produces: token, self,annotations)
    }
}

/// Convience functions for arrays for `Rule`s
public extension Collection where Self.Iterator.Element == Rule {
    
    /**
     Creates a new rule that requires that all rules in this array are found one after another.
     
     - Parameter token: The token that should be produced
     - Parameter annotations: Any annotations to the rule
    */
    func sequence(token:Token,annotations:RuleAnnotations?=nil)->Rule{
        return ParserRule.sequence(produces: token, [Rule](self), annotations)
    }
    
    /**
     Creates a new rule that requires one of all the rules in this array must be matched.
     
     - Parameter token: The token that should be produced
     - Parameter annotations: Any annotations to the rule
     */
    func oneOf(token:Token,annotations:RuleAnnotations?=nil)->Rule{
        return ParserRule.oneOf(produces: token, [Rule](self), annotations)
    }
    
}

