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
    case warning(message:String), information(message:String), error(message:String,exitCode:Int), multiple(errors:[OperationError])
    
    /// Does this error mean that the entire process should be stopped?
    public var terminate : Bool {
        switch self {
        case .multiple(let errors):
            return errors.reduce(false, {$0 || $1.terminate})
        case .warning,.information:
            return false
        case .error:
            return true
        }
    }
    
    /// A message that can be displayed to a user
    public var message : String {
        switch self {
        case .multiple(let errors):
            return errors.reduce("", { return $0.count == 0 ? $1.message : "\($0)\n\($1.message)"})
        case .error(let message,_):
            return "Error: \(message)"
        case .information(let message):
            return "\(message)"
        case .warning(let message):
            return "Warning: \(message)"
        }
    }
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
    
    /// Creates a new instance with the specified working directory.
    ///
    /// - Parameter workingDirectory: The working directory operations should use
    public init(with workingDirectory:URL){
        self.workingDirectory = workingDirectory
    }
}
