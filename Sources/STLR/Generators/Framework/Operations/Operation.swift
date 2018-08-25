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
 Errors that can be thrown by any operation
 */
public enum OperationError : Error {
    /// Basic failure with a specific message to the user
    case error(message:String)
}

/**
 Operations are returned by a generator, and can be integrated into a build process
 */
public protocol Operation {
    func perform(in context:OperationContext) throws
}

/// The context operations work in
public class OperationContext {
    /// The working directory, can be changed and all subsequent operations will be affected
    public var workingDirectory : URL
    
    /// Environment variables
    public var environment : [String : String]
    
    private let reporter : (String)->Void
    
    /// Creates a new instance with the specified working directory.
    ///
    /// - Parameter workingDirectory: The working directory operations should use
    public init(with workingDirectory:URL, reportingTo reporter:@escaping (String)->Void){
        self.workingDirectory = workingDirectory
        self.environment = [String:String]()
        self.reporter = reporter
    }
    
    /**
     Reports a message via the supplied reporting block. Note that only
     non-critical errors should be reported
     
     - Parameter message: The message to report
    */
    public func report(_ message:String){
        reporter(message)
    }
}

/// Makes arrays of operations operations themselves
extension Array : Operation where Element == Operation {
    
    /// Performs all operations in the array. If any operation throws a terminating or unknown (not an `OperationError`) error
    /// then execution will terminate. Otherwise the messages will be collated. 
    public func perform(in context: OperationContext) throws {
        for operation in self {
            try operation.perform(in: context)
        }
    }
}
