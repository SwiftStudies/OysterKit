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

/// An extension to any `Node` to provide an implementation to satisfy `CustomStringConvertable`
public extension Node {
    /// A human readable description of the `Node`
    var description: String {
        return "\(token)"
    }
}

/// An extension to make it easy to operate on any collection of `Node`s
public extension Collection where Iterator.Element : Node {
    /**
     Returns the combined range of all `Node`s in the `Collection` essentially setting the `lowerBound` to the lowest of all range, and upperBound to the highest of all ranges.
    */
    var combinedRange : Range<String.UnicodeScalarView.Index> {
        let finalRange = reduce(first!.range, { (rangeSoFar, nextChild) -> Range<String.UnicodeScalarView.Index> in
            let lowerBound = rangeSoFar.lowerBound < nextChild.range.lowerBound ? rangeSoFar.lowerBound : nextChild.range.lowerBound
            let upperBound = rangeSoFar.upperBound > nextChild.range.upperBound ? rangeSoFar.upperBound : nextChild.range.upperBound
            
            return lowerBound..<upperBound
        })
        
        return finalRange
    }
    

}
