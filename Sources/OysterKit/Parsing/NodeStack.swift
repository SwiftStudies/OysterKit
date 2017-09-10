//
//  NodeStack.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

extension Array where Element : Equatable{
    mutating func append(unique element:Element){
        for existingError in self{
            if existingError == element {
                return
            }
        }
        
        append(element)
    }
}



public final class NodeStackEntry<NodeType:Node> : CustomStringConvertible{
    public  var nodes    = [NodeType]()
    private var _errors   = [LanguageError]()
    
    public func addError(error:LanguageError){
        
        for existingError in _errors{
            if existingError.range == error.range && existingError.description == error.description {
                return
            }
        }
        
        _errors.append(error)
    }
    
    public func addErrors(_ errors:[LanguageError]){
        for error in errors{
            addError(error: error)
        }
    }
    
    public func flushErrors(){
        _errors.removeAll()
    }
    
    public var errors : [LanguageError]{
        return _errors
    }
    
    public func append(_ node: NodeType){
        nodes.append(node)
    }
    
    public func adopt(_ nodes: [NodeType]){
        self.nodes.append(contentsOf: nodes)
    }
    
    public var description: String{
        return "\(nodes.count) nodes, with \(_errors) errors"
    }
}

public final class NodeStack<NodeType:Node> : CustomStringConvertible{
    private var stack = [NodeStackEntry<NodeType>]()
    
    public init() {
        reset()
    }
    
    public func reset(){
        stack.removeAll()
        push()
    }
    
    public func push(){
        stack.append(NodeStackEntry())
    }
    
    public func pop()->NodeStackEntry<NodeType>{
        return stack.removeLast()
    }
    
    public var top : NodeStackEntry<NodeType>?{
        return stack.last
    }
    
    public var depth : Int {
        return stack.count
    }
    
    public var all : [NodeStackEntry<NodeType>] {
        return stack.reversed()
    }
    
    public var description: String{
        var result = "NodeStack: \n"
        
        for node in stack.reversed(){
            result += "\(node)\n"
        }
        
        return result
    }
}
