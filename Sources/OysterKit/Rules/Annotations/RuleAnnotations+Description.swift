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

extension RuleAnnotation : Comparable {
    /// I decide what the order of things are. And this is what I have decided.
    private var sortValue : Int {
        switch self {
        case .token:
            return 2
        case .error:
            return 5
        case .void:
            return 0
        case .transient:
            return 1
        case .pinned:
            return 3
        case .type:
            return 4
        case .custom(_):
            return 10
        }
    }
    
    private var customLabelValue : String? {
        if case let RuleAnnotation.custom(label) = self {
            return label
        }
        return nil
    }
    
    /**
     Compares two rule annotations. Standard annotations go first then custom ones sorted
     by name.
     
     - Parameter lhs: Left hand side of the <
     - Parameter rhs: Right hand side of the <
     - Returns: `true` if lhs < rhs
     **/
    public static func < (lhs : RuleAnnotation, rhs:RuleAnnotation) -> Bool {
        if let lhs = lhs.customLabelValue, let rhs = rhs.customLabelValue {
            return lhs < rhs
        }
        
        return lhs.sortValue < rhs.sortValue
    }
}

extension Dictionary where Key == RuleAnnotation, Value == RuleAnnotationValue {
    
    public var stlrDescription: String{
        if isEmpty {
            return ""
        }
        return self.sorted(by: { (lhs, rhs) -> Bool in
            return lhs.key < rhs.key
        }).map({ (entry) -> String in
            var result = ""
            
            switch entry.key {
            case .token:
                result = "@token"
            case .error:
                result = "@error"
            case .void:
                result = "@void"
            case .transient:
                result = "@transient"
            case .pinned:
                result = "@pin"
            case .type:
                result = "@type"
            case .custom(let label):
                result = "@\(label)"
            }
            
            switch entry.value {
                
            case .string(let string):
                result += "(\"\(string)\")"
            case .bool(let bool):
                result += "(\(bool))"
            case .int(let int):
                result += "(\(int))"
            case .set:
                break
            }
            
            return result
        }).joined(separator: " ")
    }
    
    /// Generates a STLR like description of the annotations
    public var description : String {
        return stlrDescription
    }
}
