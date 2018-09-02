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

/// An extension to arrays of `Equatable` `Element`s that adds a set like append behaviour
extension Array where Element : Equatable{
    
    /**
     Adds an element to the `Array` if and only if the new `element` is not already in the array
     
     - Parameter unique: A candidate element to add to the array
    */
    mutating func append(unique element:Element){
        for existingError in self{
            if existingError == element {
                return
            }
        }
        
        append(element)
    }
}

/**
 `NodeStackEntry`'s are used to capture parsing context (for example child-nodes and errors) ASTs are constructed.
 */
public final class NodeStackEntry<NodeType:Node> : CustomStringConvertible{
    /// The child nodes of this node
    public  var nodes    = [NodeType]()
    
    /**
     Should be called when a child node is created
     
     - Parameter node: The new child node
    */
    public func append(_ node: NodeType){
        nodes.append(node)
    }
    
    /**
     Adds all of the supplied nodes as this nodes children
     
     - Parameter nodes: The new child nodes
     */
    public func adopt(_ nodes: [NodeType]){
        self.nodes.append(contentsOf: nodes)
    }
    
    /// A human readable description of the context
    public var description: String{
        return "\(nodes.count) nodes"
    }
}

/**
 A `NodeStack` can be used to manage AST construction state, as new rule evaluations begin new contexts can be pushed onto the node stack and then popped and discarded on failure, or popped and acted on for success.
 */
public final class NodeStack<NodeType:Node> : CustomStringConvertible{
    /// The stack itself
    private var stack = [NodeStackEntry<NodeType>]()
    
    /// Creates a new instance of the stack with an active context
    public init() {
        reset()
    }
    
    /// Removes all current stack entries and adds a new initial context
    public func reset(){
        stack.removeAll()
        push()
    }
    
    /// Adds a new context to the top of the stack
    public func push(){
        stack.append(NodeStackEntry())
    }
    
    /// Removes the stack entry from the top of the stack
    /// - Returns: The popped entry
    public func pop()->NodeStackEntry<NodeType>{
        return stack.removeLast()
    }
    
    /// The entry currently on the top of the stack, if any
    public var top : NodeStackEntry<NodeType>?{
        return stack.last
    }
    
    /// The depth of the stack
    public var depth : Int {
        return stack.count
    }
    
    /// An inverted (from deepest to shallowest) representation of the stack
    public var all : [NodeStackEntry<NodeType>] {
        return stack.reversed()
    }
    
    /// A human readable description of the stack
    public var description: String{
        var result = "NodeStack: \n"
        
        for node in stack.reversed(){
            result += "\(node)\n"
        }
        
        return result
    }
}
