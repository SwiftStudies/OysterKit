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
 Match results are passed from `Rule`s to `IntermediateRepresentations` and provide all information required to create an AST or even begin
 interpretting the results of the match.
 */
public enum MatchResult : CustomStringConvertible{
    /// The match was successful
    case success(context:LexicalContext)
    /// The match was successful but no token should be issued
    case consume(context:LexicalContext)
    /// The match failed, but that failure is OK
    case ignoreFailure(atIndex:String.UnicodeScalarView.Index)
    /// The match failed
    case failure(atIndex:String.UnicodeScalarView.Index)
    
    /// A human readable description of the result
    public var description: String{
        switch self {
        case .success(let context):
            return "Success (\(String(context.source.unicodeScalars[context.range]).debugDescription.dropLast().dropFirst()))"
        case .consume(let context):
            return "Consumed (\(String(context.source.unicodeScalars[context.range])))"
        case .ignoreFailure:
            return "Ignore Failure"
        case .failure(let at):
            return "Failed at \(at.encodedOffset)"
        }
    }
    
    /// The substring of the source that the match was against
    public var range : String.UnicodeScalarView.Index {
        switch self {
        case .ignoreFailure(let index), .failure(let index):
            return index
        case .success(let context):
            return context.range.lowerBound
        case .consume(let context):
            return context.range.lowerBound
        }
    }
    
    
    /// The substring of the source that the match was against
    public var matchedString : String? {
        switch self {
        case .success(let context):
            return context.matchedString
        default:
            return nil
        }
    }
}
