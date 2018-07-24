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
 `Behaviour` represents a complete description of the required behaviour of any given
  rule. This includes behaviours such as lookahead, negation, and cardinality. As well
  the scanning/parsing behaviour indicating whether or not the rule should create tokens
  (structural), is scanning (should be included in the match range, but creates no token) or
  skipping (must be matched, but is not included in the bounds of the match range).
 */
public struct Behaviour {
    /**
     Captures scanning/parsing behaviour indicating identifying if the rule should create tokens
     (structural), is scanning (should be included in the match range, but creates no token) or
     skipping (must be matched, but is not included in the bounds of the match range).
     */
    public enum Kind {
        /// Do not include any matches in the bounds of the match
        case    skipping
        /// Do not create structure but do include in the bounds of the match
        case    scanning
        /// Include in the bounds of the match and create a structural node in the AST
        case    structural(token:Token)
    }

    
    
    /// The rule should be matched, but if lookahead is true the scanner head position should be
    /// returned to its position at the start of evaluation
    public let lookahead : Bool
    
    /// The result of matching should be negated.
    public let negate : Bool
    
    /// The kind of rule, skipping, scanning, or structural (see above)
    public let kind : Kind
    
    /// The cardinatlity of the matches
    public let cardinality : Cardinality
    
    /// The token produced if structural or nil otherwise
    public var token : Token? {
        switch kind {
        case .structural(let token):
            return token
        default:
            return nil
        }
    }
    
    /**
     Constructs a new instance of the struct with the specified parameters. All except kind can be excluded resulting
     in requirements for a single match, un-negated without lookahead
 
     - Parameter kind: The of behaviour (skipping, scanning, or structural)
     - Parameter cardinality: How many matches are required. Defaults to 1, but can be specified as any closed range.
     - Parameter negated: Specifies if the result of the Matcher should be negated
     - Parameter lookahead: Specifies if the scanning head should be returned to the pre-matching position even if met.
    */
    public init(_ kind:Kind, cardinality: ClosedRange<Int> = 1...1, negated:Bool = false, lookahead:Bool = false){
        self.kind = kind
        self.cardinality = Cardinality(cardinality)
        self.negate = negated
        self.lookahead = lookahead
    }
    
    /**
     Constructs a new instance of the struct with the specified parameters. All except kind can be excluded resulting
     in requirements for a single match, un-negated without lookahead
     
     - Parameter kind: The of behaviour (skipping, scanning, or structural)
     - Parameter cardinality: The minimum number of matches required
     - Parameter negated: Specifies if the result of the Matcher should be negated
     - Parameter lookahead: Specifies if the scanning head should be returned to the pre-matching position even if met.
     */
    public init(_ kind:Kind, cardinality: PartialRangeFrom<Int>, negated:Bool = false, lookahead:Bool = false){
        self.kind = kind
        self.cardinality = Cardinality(cardinality)
        self.negate = negated
        self.lookahead = lookahead
    }
    
    /**
     Constructs a new instance of the struct with the specified parameters. All except kind can be excluded resulting
     in requirements for a single match, un-negated without lookahead
     
     - Parameter kind: The of behaviour (skipping, scanning, or structural)
     - Parameter cardinality: The cardinality of the matches
     - Parameter negated: Specifies if the result of the Matcher should be negated
     - Parameter lookahead: Specifies if the scanning head should be returned to the pre-matching position even if met.
     */
    public init(_ kind:Kind, cardinality: Cardinality, negated:Bool = false, lookahead:Bool = false){
        self.kind = kind
        self.cardinality = cardinality
        self.negate = negated
        self.lookahead = lookahead
    }
    
    /**
     Creates a new instance with the specified parameters changed. All have defaults and any that are excluded will maintain their current
     values.
     
     - Parameter kind: The of behaviour (skipping, scanning, or structural)
     - Parameter cardinality: How many matches are required.
     - Parameter negated: Specifies if the result of the Matcher should be negated
     - Parameter lookahead: Specifies if the scanning head should be returned to the pre-matching position even if met.
    */
    public func instanceWith(_ kind:Kind?=nil, cardinality: ClosedRange<Int>? = nil, negated:Bool? = nil, lookahead:Bool? = nil)->Behaviour{
        let newCardinality = cardinality == nil ? self.cardinality : Cardinality(cardinality!)
        return Behaviour(kind ?? self.kind, cardinality: newCardinality, negated: negated ?? self.negate, lookahead: lookahead ?? self.lookahead)
    }
    
    /**
     Creates a new instance with the specified parameters changed. All have defaults and any that are excluded will maintain their current
     values.
     
     - Parameter kind: The of behaviour (skipping, scanning, or structural)
     - Parameter cardinality: How many matches are required.
     - Parameter negated: Specifies if the result of the Matcher should be negated
     - Parameter lookahead: Specifies if the scanning head should be returned to the pre-matching position even if met.
     */
    public func instanceWith(_ kind:Kind?=nil, cardinality: PartialRangeFrom<Int>? = nil, negated:Bool? = nil, lookahead:Bool? = nil)->Behaviour{
        let newCardinality = cardinality == nil ? self.cardinality : Cardinality(cardinality!)
        return Behaviour(kind ?? self.kind, cardinality: newCardinality, negated: negated ?? self.negate, lookahead: lookahead ?? self.lookahead)
    }
}
