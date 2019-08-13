//    Copyright (c) 2019, RED When Excited
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
//
//


import Foundation

@_functionBuilder public struct RuleBuilder {
    static public func buildBlock(_ rules:Rule...) -> [Rule] {
        return rules
    }    
}

/// Constructs a `SequenceRule` from an array of rules
///
/// - Parameter makeRules: The block that will generate a single rule which requires all of the rules returned to be supplied in sequence
public func sequence(@RuleBuilder makeRules:()->[Rule]) -> Rule {
    return SequenceRule(
        Behaviour(.scanning,
                  cardinality: .one,
                  negated: false,
                  lookahead: false),
        and: [:],
        for: makeRules()
    )
}

/// Constructs a `ChoiceRule` from an array of `Rule`s
///
/// - Parameter makeRules: The block that will generate an array of `Rule`s, any one of which can satisfy the generated `Rule` (evaluated in order)
public func oneOf(@RuleBuilder makeRules:()->[Rule]) -> Rule {
    return ChoiceRule(
        Behaviour(
            .scanning,
            cardinality: .one,
            negated: false,
            lookahead: false),
        and: [:],
        for: makeRules()
    )
}

/// Creates a grammar from an array of `Rule`s
/// - Parameter makeRules: The block that will generate the array of `Rule` and turn it into a grammar
public func grammar(@RuleBuilder makeRule:()->Rule) -> Grammar {
    return [makeRule()]
}
