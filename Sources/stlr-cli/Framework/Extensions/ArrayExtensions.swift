//
//  ArrayExtensions.swift
//  CommandKit
//
//  Created by Sean Alling on 11/8/17.
//

import Foundation

extension Array {
    func adding(_ newElement:Element)->Array{
        var newArray = self
        newArray.append(newElement)
        return newArray
    }
}

public extension Array where Element == Option {
    public subscript(optionNamed name:String)->Option?{
        for option in self {
            if option.longForm == name {
                return option
            }
        }
        return nil
    }
}


extension Array where Element == Argument {
    
    /**
         Determines if the correct `tool` argument is present
     
     - Preconditions:
         (a) must be in index = 0
         (b) must be the same name as the one specified in `Tool.name`
     */
    var isToolArgumentPresent: Bool {
        guard let safeArgument = self.first else { return false }
        return (safeArgument.type == .tool) ? true : false
    }
    
    /**
         Determines if a `command` argumewnt is present and in the proper location
     
     - Preconditions:
         (a) must be in index = 1
     */
    var isCommandArgumentPresent: Bool {
        guard self.count >= 2 else { return false }
        return (self[1].type == .command) ? true : false
    }
    
    /**
         Determines if an `option` is present and in the proper location
     
     - Preconditions:
         (a) must have a `command` at index = 1, AND
         (b) must be in index = 2
     */
    var isOptionArgumentPresent: Bool {
        guard let optionIndex = self.index(where: { $0.type == .option }) else { return false }
        guard optionIndex != self.startIndex else { return false }
        let beforeIndex = self.index(optionIndex, offsetBy: -1)
        guard self[beforeIndex].type == .command || self[beforeIndex].type == .tool else { return false }
        return true
    }
    
    /**
         Determines if `parameters` are present and in the proper location
     
     - Preconditions:
         (a) must be in index >= 2
     */
    var isParameterArgumentPresent: Bool {
        let firstIndex = self.index(where: { $0.type == .parameter })
        guard let safeFirstIndex = firstIndex else { return false }
        return Int(safeFirstIndex) >= 2 ? true : false
    }
    
    /**
         Returns the subset of arguments for a particular type
     */
    func subset(for type: Argument.ParsedType) -> [Argument] {
        return self.filter({ $0.type == type })
    }
    
    /**
         Provides the range at which the parameter arguments are found
     */
    var parameterRange: CountableClosedRange<Int>? {
        let subStartIndex = self.index(where: { $0.type == .parameter })
        guard let safeSubStartIndex = subStartIndex else { return nil }
        
        let subTestArray = self.suffix(from: Int(safeSubStartIndex))
        let testedSubArray = subTestArray.map({ $0.type == .parameter })
        
        if let endSubBound = testedSubArray.index(where: { $0 == false }) {
            var endBound = endSubBound + Int(safeSubStartIndex) - 1
            if endBound > self.endIndex { endBound = self.endIndex }
            return Int(safeSubStartIndex)...endBound
        }
        else {
            let endBound = subTestArray.count + Int(safeSubStartIndex) - 1
            return Int(safeSubStartIndex)...endBound
        }
    }
}
