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
 `Token`s are generated when rules are matched (usually, sometime a rule just advances the scan-head). Tokens with a `rawValue` of -1 are considered transient, meaning that they should not be included in any construction of an AST. However, they may provide context to the AST.
 */
public protocol Token {
    /// A rawValue that unless the token is transient should be unique
    var rawValue : Int { get }
}

/// Extensions to enable any Int to be used as a token. Note that **only positive integers should be used**
extension Int {
    /// A token from this integer value
    var token : Token {
        struct TransientToken : Token { let rawValue : Int }
        return TransientToken(rawValue: self)
    }
}

/**
 An extension to allow any `Int` to be used as a `Token`.
 */
extension Int : Token{
    /// Itself
    public var rawValue: Int{
        return self
    }
}

/**
 An extension to allow any `String` to be used as a `Token`.
 */
extension String : Token {
    /// Returns the `hash` of the `String`
    public var rawValue : Int {
        return self.hash
    }
}

/**
 Compares two tokens for equality
 */
public func ==(lhs:Token, rhs:Token)->Bool{
    return lhs.rawValue == rhs.rawValue
}


