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
 A collection of standard system operations, including a generic ability to execute any command
 */
public enum System : Operation {
    /// Perform a shell command with the supplied arguments
    case shell(String, arguments:[String])
    
    /// Create a new directory
    case makeDirectory(name:String)

    /// Remove a directory and its contents
    case removeDirectory(name:String)

    /// Change the working directory in the operation context
    case changeDirectory(name:String)
    
    public func perform(in context: OperationContext) throws {
        let path = context.workingDirectory.path
        switch self {
        case .shell(let command, let arguments):
            let result = execute(command: command,in:path ,arguments: arguments)
            throw OperationError.information(message: result)
        case .makeDirectory(let name):
            do {
                try System.shell("mkdir",arguments: [name]).perform(in: context)
            } catch OperationError.information(let message) {
                if message.range(of: "File exists") != nil {
                    throw OperationError.error(message: "File already exists \(name)", exitCode: 255)
                }
            } catch {
                throw OperationError.error(message: "\(error)", exitCode: 255)
            }
        case .removeDirectory(let name):
            if name == "/" {
                throw OperationError.error(message: "Won't remove root directory", exitCode: Int(EXIT_FAILURE))
            }
            try System.shell("rm",arguments: ["-r","\(name)"]).perform(in: context)
        case .changeDirectory(let name):
            context.workingDirectory = context.workingDirectory.appendingPathComponent(name)
        }
    }
    
    /// Taken from [StackOverflow](https://stackoverflow.com/questions/26971240/how-do-i-run-an-terminal-command-in-a-swift-script-e-g-xcodebuild)
    private func execute(command: String, in path:String, arguments: [String]) -> String{
        var arguments = arguments
        arguments.insert(command, at: 0)
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.currentDirectoryPath = path
        task.arguments = arguments
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: String.Encoding.utf8)!
        if output.count > 0 {
            //remove newline character.
            let lastIndex = output.index(before: output.endIndex)
            return String(output[output.startIndex ..< lastIndex])
        }
        return output
    }

}

