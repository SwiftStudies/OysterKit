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


public extension Array where Element == Error {
    /// Extracts any causal errors from the array and builds a range from them
    var range    : ClosedRange<String.Index>? {
        var lowerBound : String.Index?
        var upperBound : String.Index?
        
        for cause in compactMap({$0 as? CausalErrorType}){
            if let existingLower = lowerBound, let causeLower = cause.range?.lowerBound {
                lowerBound = Swift.min(existingLower, causeLower)
            } else {
                lowerBound = cause.range?.lowerBound
            }
            if let existingUpper = upperBound, let causeUpper = cause.range?.upperBound {
                upperBound = Swift.max(existingUpper, causeUpper)
            }
        }
        
        switch (lowerBound, upperBound) {
        case (let lower, nil) where lower != nil:
            return lower!...lower!
        case (nil, let upper) where upper != nil:
            return upper!...upper!
        case (let lower,let upper) where upper != nil && lower != nil:
            return lower!...upper!
        default:
            return nil
        }
    }
}
