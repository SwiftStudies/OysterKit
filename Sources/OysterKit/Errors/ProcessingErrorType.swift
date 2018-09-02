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

/// Represents the type of processing error.
public struct ProcessingErrorType : OptionSet {
    public let rawValue: Int
    
    /**
     Creates a new instance with the specified rawValue. Supported types are all captured with static constants and you should not need this
     
     - Parameter rawValue: The raw value
     **/
    public init(rawValue:Int){
        self.rawValue = rawValue
    }
    
    /**
     Creates a new instance classifying the supplied error
     
     - Parameter error: The error to classify
     **/
    public init(from error:Error){
        if let error = error as? ProcessingError {
            switch error {
            case .scannedMatchFailed:
                rawValue = ProcessingErrorType.scannedMatchFailed.rawValue
            case .internal(_):
                rawValue = ProcessingErrorType.internal.rawValue
            case .undefined(_,_,_):
                rawValue = ProcessingErrorType.undefined.rawValue
            case .scanning(_,_,_):
                rawValue = ProcessingErrorType.scanning.rawValue
            case .parsing(_,_,_):
                rawValue = ProcessingErrorType.parsing.rawValue
            case .interpretation(_,_):
                rawValue = ProcessingErrorType.interpretation.rawValue
            case .fatal(_,_):
                rawValue = ProcessingErrorType.fatal.rawValue
            }
        } else {
            rawValue = ProcessingErrorType.foreign.rawValue
        }
    }
    
    /// A non OysterKit error
    public static let foreign           = ProcessingErrorType(rawValue:1 << 0)
    
    /// An internal `ProcessingError`
    public static let `internal`        = ProcessingErrorType(rawValue:1 << 1)
    
    /// An undefined `ProcessingError`
    public static let undefined         = ProcessingErrorType(rawValue:1 << 2)
    
    /// A scanning `ProcessingError`
    public static let scanning          = ProcessingErrorType(rawValue:1 << 3)
    
    /// A parsing `ProcessingError`
    public static let parsing           = ProcessingErrorType(rawValue:1 << 4)
    
    /// An interpretation `ProcessingError`
    public static let interpretation    = ProcessingErrorType(rawValue:1 << 5)
    
    /// A fatal `ProcessingError`
    public static let fatal             = ProcessingErrorType(rawValue:1 << 6)
    
    /// A low level scanner (not scanning) error
    public static let scannedMatchFailed = ProcessingErrorType(rawValue: 1 << 7)
}
