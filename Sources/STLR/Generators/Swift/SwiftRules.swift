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
import OysterKit

private func tabs(_ depth:Int)->String{
    return String(repeating: "\t", count: depth)
}

private extension String {
    mutating func add(depth: Int = 0, line:String){
        self = "\(self)\(tabs(depth))\(line)\n"
    }
    
    mutating func add(depth: Int = 0, comment:String){
        self = "\(self)\(tabs(depth))// \(comment)\n"
    }
    
    var swiftSafe : String {
        var result = self.replacingOccurrences(of: "\\", with: "\\\\")
        
        result = result.replacingOccurrences(of: "\"", with: "\\\"")
        
        return result
    }
    
    var trim : String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}

/**
 Captures the different platforms supported by Swift which will influence code generation
 */
public enum Platform{
    /// The Mac platform
    case macOS
    
    /// iOS
    case iOS
    
    /// Linux or other platforms
    case foundation
    
    fileprivate var colorType : String {
        switch self {
        case .macOS:
            return "NSColor"
        case .iOS:
            return "UIColor"
        case .foundation:
            return "(r:Float,g:Float,b:Float)"
            
        }
    }
    
    fileprivate var coreLibrary : String {
        switch self {
        case .macOS:
            return "Cocoa"
        case .iOS:
            return "UIKit"
        case .foundation:
            return "Foundation"
        }
    }
    
    /**
     Generates the appropriate Swift source for a color on this platform
     
     - Parameter: A tuple containing the RGB values for the color (each a float from 0-1)
     - Returns: A String containing the Swift source
    */
    func colorLiteral(rgb:(r:Float,g:Float,b:Float))->String{
        switch self {
        case .macOS,.iOS:
           return "#colorLiteral(red:\(rgb.r), green:\(rgb.g), blue:\(rgb.b), alpha: 1)"
        case .foundation:
            return "(r:\(rgb.r),g:\(rgb.g),b:\(rgb.b))"
        }
    }
}

fileprivate enum TransientToken : Int, Token, CustomStringConvertible {
    fileprivate var description: String{
        return "_transient"
    }
    
    case instance = 0
}
