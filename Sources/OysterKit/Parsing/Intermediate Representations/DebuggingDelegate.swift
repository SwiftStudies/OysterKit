//    Copyright (c) 2014, RED When Excited
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
 This `IntermediateRepresentation` can be used when you are having trouble understanding why your grammar
 is not creating the structure you expect. It does not create any kind of representation of the parsed data,
 but solely reports the progress of the parser as it proceeds. An example usage would be:
 
        let debuggingIR = myParser.build(intermediateRepresentation: DebuggingDelegate(), using: Lexer(source: mySource))
 
 This can also be combined with a `ForkedIR` to both build your desired AST and debug at the same time.
 
 */
public class DebuggingDelegate : IntermediateRepresentation{
    private var depth = 0
    
    
    /// Create a new instance
    public required init() {
    }
    
    /**
     Prints a debugging message prefixed by a number of tabs
     
     - Parameter message: The message to display
     - Parameter indent: The number of tabs to prefix with
    */
    func debugMessage(message:String, indent:Int){
        let message = String(repeating: "\t", count: indent-1)+message
        print(message)
    }
    
    /**
     Ignores the parameters, and just resets the internal state
    */
    public func willBuildFrom(source: String, with: Language) {
        depth = 1
    }
    
    /// Does nothing
    public func didBuild() {
    }
    
    /**
     Prints a message telling you that evaluation is about to start for the rule and increases the depth of
     subsequent messages.
     
     - Parameter rule: The token for the supplied rule is included in the message
     - Parameter at: Is ignored
     - Returns: Always returns `nil`
    */
    public func willEvaluate(rule: Rule, at position: String.UnicodeScalarView.Index) -> MatchResult? {
        debugMessage(message: "ℹ️ \(rule.produces)", indent: depth)
        depth += 1
        return nil
    }
    
    /**
     Reports the success or otherwise of the rule evaluation, and reduces the depth of indent
     
     -Parameter rule: The token is included in the message
     -Parameter matchResult: The nature of the result is printed.
    */
    public func didEvaluate(rule: Rule, matchResult: MatchResult) {
        depth -= 1
        switch matchResult{
        case .success(_):
            debugMessage(message: "✅ \(rule.produces) matched", indent: depth)
        case .failure:
            debugMessage(message: "⁉️ \(rule.produces)", indent: depth)
        case .ignoreFailure:
            debugMessage(message: "⚠️ \(rule.produces), but failure is ignorable", indent: depth)
        case .consume:
            debugMessage(message: "✅ \(rule.produces) consumed", indent: depth)
        }
    }
    
    /// Does nothing
    public func resetState() {
        
    }
}
