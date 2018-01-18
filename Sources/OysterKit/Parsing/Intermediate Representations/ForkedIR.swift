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
 This `IntermediateRepresentation` essentially forks the function calls to its two subordinate `IntermediateRepresentations`. This allows you to combine
 multiple `IntermediateRepresentation`s for example your normal data-structure pairs with an instance of `DebuggingDelegate` for debugging purposes.
 */
public class ForwardingIR<BaseIR:IntermediateRepresentation> : IntermediateRepresentation {
    /// The primary, or first `IntermediateRepresentation`
    public var primary   : BaseIR
    
    /// The secondary `IntermediateRepresentation`.
    public var secondary : IntermediateRepresentation
    
    /// Calling the constructor with no parameters on this implementation will result in a fatal error as both must exist.
    public required init() {
        fatalError("Forwarding IR requires that a secondary IR is supplied pre-initialized and then used with build(intermediateRepresentation:lexer:)")
    }
    
    /**
    Creates a new instance with a new instance of the `BaseIR` using the required constructor for the specified and then consuming the supplied secondary `IntermediateRepresentaion`
     
     - Parameter secondary: An instance of the secondary `IntermediateRepresentation`
    */
    public init(secondary:IntermediateRepresentation){
        self.primary   = BaseIR()
        self.secondary = secondary
    }
    
    /**
     Creates a new instance with a new instance of the `BaseIR` consuming the supplied primary and secondary `IntermediateRepresentaion` instances
     
     - Parameter Primary: An instance of the primary `IntermediateRepresentation`
     - Parameter secondary: An instance of the secondary `IntermediateRepresentation`
     */
    public init(primary: BaseIR, secondary:IntermediateRepresentation){
        self.primary = primary
        self.secondary = secondary
    }
    
    /**
     Forwarded to both primary and secondary `Intermediate Representations`
    */
    public func willBuildFrom(source: String, with: Language) {
        primary.willBuildFrom(source: source, with: with)
        secondary.willBuildFrom(source: source, with: with)
    }
    
    /**
     Forwarded to both primary and secondary `Intermediate Representations`
     */
    public func resetState() {
        primary.resetState()
        secondary.resetState()
    }
    
    /**
     Forwarded to both primary and secondary `Intermediate Representations`
     */
    public func willEvaluate(rule: Rule, at position: String.UnicodeScalarView.Index) -> MatchResult? {
        let primaryHasCache = primary.willEvaluate(rule: rule, at: position)
        let _ = secondary.willEvaluate(rule: rule, at: position)
        
        if let primaryHasCache = primaryHasCache {
            secondary.didEvaluate(rule: rule, matchResult: primaryHasCache)
            
            return primaryHasCache
        }
        
        return nil
    }
    
    /**
     Forwarded to both primary and secondary `Intermediate Representations`
     */
    public func didEvaluate(rule: Rule, matchResult: MatchResult) {
        primary.didEvaluate(rule: rule, matchResult: matchResult)
        secondary.didEvaluate(rule: rule, matchResult: matchResult)
    }

    /**
     Forwarded to both primary and secondary `Intermediate Representations`
     */
    public func didBuild() {
        primary.didBuild()
        secondary.didBuild()
    }

}
