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

/// Captures the output of a source generator
public class TextFile : Operation {
    /// Writes the file at the specified location
    public func perform(in context: OperationContext) throws {
        let writeTo = context.workingDirectory.appendingPathComponent(name)

        do {
            try content.write(to: writeTo, atomically: true, encoding: .utf8)
        } catch {
            throw OperationError.error(message: "Failed to write file \(writeTo) \(error.localizedDescription)")
        }
        context.report("Wrote \(writeTo.path)")
    }
    
    /// The desired name of the file, including an extension. Any path elements will be considered relative
    /// a location known by the consumer of the TextFile
    public var name : String
    
    public private(set) var content : String = ""
    
    private var tabDepth : Int = 0
    
    /**
     Creates a new instance
     
     - Parameter name: The name of the textfile
     */
    public init(_ name:String){
        self.name = name
    }
    
    /**
     Appends the supplied items to the text file at the current tab depth
     
     - Parameter terminator: An optional terminator to use. By default it is \n
     - Parameter separator: An optional separator to use between items/ Defaults to a newline
     - Parameter prefix: An optional prefex to add to each supplied item
     - Parameter items: One or more Strings to be appended to the file
     - Returns: Itself for chaining
     */
    @discardableResult
    public func print(terminator:String = "\n", separator:String = "\n", prefix : String = "", _ items:String...)->TextFile{
        var first = true
        for item in items {
            if !first {
                content += separator
            } else {
                first = false
            }
            
            content += "\(String(repeating: "    ", count: tabDepth))\(prefix)\(item)"
        }
        
        content += terminator
        
        return self
    }
    
    /// Indents subsequent output
    /// - Returns: Itself for chaining
    @discardableResult
    public func indent()->TextFile{
        tabDepth += 1
        return self
    }
    
    /// Outdents subsequent output
    /// - Returns: Itself for chaining
    @discardableResult
    public func outdent()->TextFile{
        tabDepth -= 1
        
        return self
    }
    
}
