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

/**
 Abstract Syntax Trees are responsible to for taking an IntermediateRepresentation and building a data structure suitable for semantic analysis
 */
public protocol AbstractSyntaxTree {
    /**
     Create a new instance of the object using the supplied node
     
     - Parameter node: The node to use to populate the fields of the type
     */
    init(with node:AbstractSyntaxTreeConstructor.IntermediateRepresentationNode, from source:String) throws
}

/**
 HomogenousTree is used as the default form of AbstractSyntaxTree. Each node in the tree captures its `TokenType`, the `String` it mtached, and any children.
 */
public struct HomogenousTree : AbstractSyntaxTree, CustomStringConvertible {
    /**
     Creates a new instance using the supplied intermediate representation and source
     
     - Parameters node: The `AbstractSyntaxTreeConstructor.IntermediateRepresentationNode` in the `IntermediateRepresentation` to create
     - Parameters source: The original `String` being parsed
     */
    public init(with node: AbstractSyntaxTreeConstructor.IntermediateRepresentationNode, from source:String) throws {
        token = node.token
        matchedString = String(source[node.range])
        children = try node.children.map({ try HomogenousTree(with:$0, from: source)})
        annotations = node.annotations
    }
    
    /**
     Creates a new instance of the node using the supplied parameters. You do not normally need to call this as nodes
     will be created by an `AbstractSyntaxTreeConstructor`. However if you wish to manually alter a generated tree
     creating nodes via this method may be appropriate.
 
     - Parameter token: The `TokenType` for the node
     - Parameter matchedString: The string that was matched
     - Parameter children: The child nodes
     - Parameter annotations: The annotations on the node
    */
    public init(with token:TokenType, matching:String, children:[HomogenousTree], annotations:[RuleAnnotation:RuleAnnotationValue] = [:]){
        self.token = token
        self.matchedString = matching
        self.children = children
        self.annotations = annotations
    }
    
    /// The captured `Token`
    public let     token         : TokenType
    
    /// The `String` that was matched to satisfy the rules for the `token`.
    public let     matchedString : String
    
    /// Any sub-nodes in the tree
    public let     children      : [HomogenousTree]
    
    /// Any associated annotations made on the node
    public      let annotations: [RuleAnnotation : RuleAnnotationValue]

    /// Access a child based on the name of the token of the child
    public subscript(_ tokenName:String)->HomogenousTree?{
        for child in children {
            if "\(child.token)" == tokenName {
                return child
            }
        }
        return nil
    }
    
    /// Access a child based on the index of the child
    public subscript(_ index:Int)->HomogenousTree{
        return children[index]
    }
    
    private func pretify(prefix:String = "")->String{
        let annotatedWith : String = annotations.reduce("", {(last,pair)->String in
            let label = "\(pair.key)"
            let value : String
            switch pair.value {
            case .set:
                value = ""
            case .string(let string):
                value = "(\"\(string)\")"
            default:
                value = "(\(pair.value))"
            }
            return last + "@\(label)\(value) "
        })
        return "\(prefix)\(annotatedWith)\(token) \(children.count > 0 ? "" : "- '\(matchedString.escaped)'")\(children.count > 0 ? children.reduce("\n", { (previous, current) -> String in return previous+current.pretify(prefix:prefix+"\t")}) : "\n")"
    }
    
    /// A well formatted description of this branch of the tree
    public var description: String{
        return pretify()
    }
}

extension String {
    var escaped : String  {
        return self.replacingOccurrences(of:"\n",with:"\\n").replacingOccurrences(of: "\t", with: "\\t")
    }
}
