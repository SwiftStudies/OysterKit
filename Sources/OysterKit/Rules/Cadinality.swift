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

/// Represents the cardinality of a rule. It can be specified as a closed range,
/// including those with no upper bound (`PartialRangeFrom`)
public struct Cardinality : Equatable {
    /// The minimum number of matches, must be >= 0
    public let minimumMatches : Int
    /// The maximum number of matches. If nil, any number can be matched
    public let maximumMatches : Int?
    
    /**
     Creates a new range from the supplied partial range meaning that the number
     of allowable matches is infinite
     
     - Parameter range: The partial closed range of allowed match counts
    */
    public init(_ range:PartialRangeFrom<Int>){
        minimumMatches = range.lowerBound
        maximumMatches = nil
        
        assert(minimumMatches >= 0,"It is not possible to match less than zero times")
    }
    
    /**
     Creates a new range from the supplied closed range meaning that the number
     of allowable matches is infinite
     
     - Parameter range: The closed range of allowed match counts
     */
    public init(_ range:ClosedRange<Int>){
        minimumMatches = range.lowerBound
        maximumMatches = range.upperBound

        assert(minimumMatches >= 0,"It is not possible to match less than zero times")
    }
    
    /// A pre-specified constant for one and exactly one matches
    public static let one = Cardinality(1...1)
    
    /// A pre-specified constant for optional matches (between 0 and 1 matches)
    public static let zeroOrOne = Cardinality(0...1)
    
    /// A pre-specified constant for optional but unbound matches (between 0 and infinity matches)
    public static let zeroOrMore = Cardinality(0...)
    
    /// A pre-specified constant for required but unbound matches (between 1 and infinity matches)
    public static let oneOrMore = Cardinality(1...)
    
    /// The equality function
    public static func ==(lhs:Cardinality, rhs:Cardinality)->Bool{
        if lhs.minimumMatches != rhs.minimumMatches {
            return false
        }
        
        switch (lhs.maximumMatches == nil,rhs.maximumMatches == nil){
        case (true,false),(false,true):
            return false
        default:
            return true
        }
    }
}
