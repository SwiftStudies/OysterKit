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
 An error type that captures not just a current error, but the hierarchy of
 errors that caused it.
 */
public protocol CausalErrorType : Error, CustomStringConvertible, CustomDebugStringConvertible{
    /// Any errors which can be rolled up into this error
    var causedBy : [Error]? {get}
    
    /// The range of the error in the source `String`
    var range    : ClosedRange<String.Index>? {get}
    
    /// The message associated with the error
    var message  : String {get}
    
    /// The error should stop subsequent processing
    var isFatal : Bool {get}
}

/**
 Adds some core standard functionality for automatically assembling error messages
 */
public extension CausalErrorType {
    /// A textural description of the error
    var description : String {
        return message
    }
    /// A more detailed description of the error including the hierarchy of errors that built to this error
    var debugDescription : String {
        func dumpCauses(_ indent:Int = 1, causes:[Error])->String{
            var result = ""
            for cause in causes {
                if let cause = cause as? CausalErrorType {
                    result += "\(String(repeating:"\t",count:indent))- \(cause.description)\n\(dumpCauses(indent+1,causes: cause.causedBy ?? []))"
                } else {
                    result += "\(String(repeating:"\t",count:indent))- \(cause.localizedDescription)\n"
                }
            }
            return result
        }
        if let causes = causedBy, !causes.isEmpty {
            return "\(message). Caused by:\n\(dumpCauses(causes: causes))"
        } else {
            return description
        }
    }
}

public extension CausalErrorType {
    /**
     Returns true if the supplied error includes the supplied description in its description
     
     - Parameter description: The text being searched for
     - Returns: True if it contains the message, false if not
     */
    public func hasCause(description:String)->Bool{
        if message.contains(description){
            return true
        }
        for cause in causedBy ?? [] {
            if let cause = cause as? CausalErrorType, cause.hasCause(description: description){
                return true
            } else if "\(cause)".contains(description){
                return true
            }
        }
        return false
    }
}

/**
 Utility functions
 */
public extension CausalErrorType {
    /**
     Provides a formatted version of the error message suitable for printing in a fixed width font, with a pointer highlighting the
     location of the error
     
     - Parameter in: The original source that was being parsed
     - Returns: A formatted `String` with a human readable and helpful message
     */
    func formattedErrorMessage(`in` input:String)->String{
        
        func occurencesOf(_ character: Character, `in` asString:String)->(count:Int,lastFound:String.Index) {
            var lastInstance = asString.startIndex
            var count = 0
            
            for (offset,element) in asString.enumerated() {
                if character == element {
                    count += 1
                    
                    lastInstance = asString.index(asString.startIndex, offsetBy: offset)
                }
            }
            
            return (count, lastInstance)
        }
        
        let errorIndex : String.Index
        
        if let range = range {
            if range.lowerBound >= input.endIndex {
                errorIndex = input.index(before: input.endIndex)
            } else {
                errorIndex = range.lowerBound
            }
        } else {
            errorIndex = input.startIndex
        }
        
        let occurences      = occurencesOf("\n", in: String(input[input.startIndex..<errorIndex]))
        
        let offsetInLine    = input.distance(from: occurences.lastFound, to: errorIndex)
        let inputAfterError = input[input.index(after:errorIndex)..<input.endIndex]
        let nextCharacter   = inputAfterError.index(of: "\n") ?? inputAfterError.endIndex
        let errorLine       = String(input[occurences.lastFound..<nextCharacter])
        let prefix          = "\(message) at line \(occurences.count), column \(offsetInLine): "
        
        let pointerLine     = String(repeating:" ", count: prefix.count+offsetInLine)+"^"
        
        return "\(prefix)\(errorLine)\n\(pointerLine)"
    }
}
