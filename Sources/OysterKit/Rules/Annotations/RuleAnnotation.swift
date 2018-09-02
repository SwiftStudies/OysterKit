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
 An annotation that can be associated with any rule influencing how matches are interpretted and providing additional data about the token. The following annotations represent "reserved words", but otherwise you can define any annotations you want.
 
 - `.token` Override the token to be created when the rule is matched (ignoring the `Rule`'s `produces` property
 - '.error` A specific error message to generate if the `Rule` is not satisfied
 - '.void' The match should be completely ignored. This is not a failure but rather a consumption
 - '.transient' The match should be made and a `Node` could be created but this token is not significant for the AST
 - '.pinned' The token should be created with no value even if the `Rule` is not matched in an ignorable failure
 
 
 */
public enum RuleAnnotation : Hashable, CustomStringConvertible{
    /// Token to be created when the rule is matched
    case token
    /// An error to be generated when the rule is not matched
    case error
    /// Matches will be completely discarded (no node, no adoption of children by parent)
    case void
    
    ///Token will not be preserved in the AST but it's children should be adopted by the parent node
    case transient
    
    ///Nodes will be created for failed optional matches
    case pinned
    
    ///The type of the token, used to inform code generation
    case type
    
    ///A custom developer defined annotation that your own AST will interpret
    case custom(label:String)
    
    ///The searchable hash value of the annotation
    public var hashValue: Int{
        switch self {
        case .token, .error, .void, .transient, .type:
            return "\(self)".hash
        case .pinned:
            return "pin".hash
        case .custom(let label):
            return label.hash
        }
    }
    
    /**
     Compares two annotations for equality (not values, but keys)
     
     - Parameter lhs: The first annotation
     - Parameter rhs: The second annotation
     - Returns: `true` if the annotations are the same, `false` otherwise.
     */
    public static func ==(lhs:RuleAnnotation, rhs:RuleAnnotation)->Bool{
        return lhs.hashValue == rhs.hashValue
    }
    
    /// A human readable description of the annotation
    public var description: String{
        switch self {
        case .type:
            return "type"
        case .pinned:
            return "pin"
        case .token:
            return "token"
        case .error:
            return "error"
        case .void:
            return "void"
        case .transient:
            return "transient"
        case .custom(let label):
            return label
        }
    }
}


