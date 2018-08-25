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

public protocol Terminal : Rule {
    /**
     Tests the the `Terminal` is available at the current scanner head position,
     throwing an `Error` if not
     
     - Parameter lexer: The lexer being used for scanning
     - Parameter token: The token produced if any. 
    */
    func test(lexer: LexicalAnalyzer, producing token:Token?) throws
    
    /// Provides a textual description of the match
    var matchDescription : String {get}
}

public extension Terminal {
    
    public func test(with lexer: LexicalAnalyzer, for ir: IntermediateRepresentation) throws {
        try test(lexer: lexer, producing: behaviour.token)
    }
    
    public var shortDescription: String {
        return behaviour.describe(match: matchDescription, requiresScanningPrefix: false)
    }
    
    
    public var behaviour: Behaviour {
        return Behaviour(.scanning, cardinality: .one, negated: false, lookahead: false)
    }
    
    public var annotations: RuleAnnotations {
        return [:]
    }
}
