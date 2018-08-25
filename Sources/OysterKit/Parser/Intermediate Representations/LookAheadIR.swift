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

private struct EmptyLexicalContext : LexicalContext {
    let source   : String
    let position : String.UnicodeScalarView.Index
    
    fileprivate var range: Range<String.UnicodeScalarView.Index>{
        return position..<position
    }
    
    fileprivate var matchedString: String{
        return ""
    }
}

/**
 A dummy `IntermediateRepresentation` used for lookahead evaluation instead of the standard IR so that the lookahead as no impact on the IR
 */
final class LookAheadIR : IntermediateRepresentation{
    func willEvaluate(token: Token, at position: String.UnicodeScalarView.Index) -> MatchResult? {
        return nil
    }
    
    func didEvaluate(token: Token, annotations: RuleAnnotations, matchResult: MatchResult) {
    }
    
    
    /// Does nothing
    /// Returns: `nil`
    final internal func willEvaluate(rule: Rule, at position: String.UnicodeScalarView.Index) -> MatchResult? {
        return nil
    }
    
    /// Does nothing
    final internal func didEvaluate(rule: Rule, matchResult: MatchResult) {
    }
    
    /// Does nothing
    final internal func willBuildFrom(source: String, with: Language) {
    }
    
    /// Does nothing
    final internal func didBuild() {
    }
    
    /// Does nothing
    func resetState() {
    }
}
