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
 A rule that matches the specified Terminal
 */
public final class TerminalRule : Rule {
    /// The behaviour of the rule
    public var behaviour: Behaviour
    /// Annotations on the rule
    public var annotations: RuleAnnotations
    /// The acceptable matches that would satisfy this rule
    public var terminal : Terminal
    
    /**
     Creates a new instance of the rule with the specified parameteres.
     
     - Parameter behaviour: The `Behaviour` for the rule
     - Parameter annotations: The `RuleAnnotations` on the rule
     - Parameter terminal: The `Terminal` terminal
     */
    public init(_ behaviour:Behaviour, and annotations:RuleAnnotations, for terminal:Terminal){
        self.behaviour = behaviour
        self.annotations = annotations
        self.terminal = terminal
    }
    
    /**
     Tests the specified terminal exists at the scanner head
     
     - Parameter lexer: The `LexicalAnalyzer` managing the scan head
     - Parameter ir: The IR building the AST
     */
    public func test(with lexer: LexicalAnalyzer, for ir: IntermediateRepresentation) throws {
        try terminal.test(lexer: lexer, producing: behaviour.token)
    }
    
    /**
     Creates a new instance with the specified behaviour and annoations overriding the current instance's
     if specified
     
     - Parameter behaviour: If specified will replace this instance's behaviour in the new instance
     - Parameter annotations: If specified will replace this instance's annotations in the new instance
     */
    public func rule(with behaviour: Behaviour? = nil, annotations: RuleAnnotations? = nil) -> Rule {
        return TerminalRule(behaviour ?? self.behaviour, and: annotations ?? self.annotations, for: terminal)
    }
    
    /// A textual description of the rule
    public var description: String {
        
        return "\(annotations.isEmpty ? "" : "\(annotations.description) ")"+behaviour.describe(match:"\(terminal.matchDescription)", requiresScanningPrefix: false)
    }
    
    /// An abreviated description of the rule
    public var shortDescription: String{
        if let produces = behaviour.token {
            return behaviour.describe(match: "\(produces)", requiresScanningPrefix: false, requiresStructuralPrefix: false)
        }
        return behaviour.describe(match: "\(terminal.matchDescription)", requiresScanningPrefix: false, requiresStructuralPrefix: false)
    }
    
}
