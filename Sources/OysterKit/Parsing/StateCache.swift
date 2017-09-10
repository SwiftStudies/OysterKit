//
//  StateCache.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

private final class Recollection<PositionType:Comparable, CachedType>{
    var events        = [(position:PositionType, cache:CachedType)]()
    
    let capacity    : Int
    
    init(position:PositionType, cache:CachedType, capacity:Int) {
        self.capacity = capacity
        events.reserveCapacity(capacity)
        events.append((position,cache))
    }
    
    subscript(position:PositionType)->CachedType?{
        get {
            for event in events.reversed(){
                if event.position == position {
                    return event.cache
                }
            }
            return nil
        }
        
        set {
            guard let newEvent = newValue else {
                return
            }
            if events.capacity == events.count {
                events.removeFirst()
            }
            events.append((position, newEvent))
        }
    }
    
    func addEvent(at position:PositionType, event:CachedType){
        
    }
    
    
    
//    private var description: String{
//        var result = "\(position) with \(events.keys.count):\n"
//        
//        for (key,value) in events {
//            result += "\t\t\(key) = \(value)\n"
//        }
//        
//        return result
//    }
}

public final class StateCache<PositionType:Comparable,KeyType:Hashable,CachedType> : CustomStringConvertible{
    // For any given index maintain a dictionary of token raw values and if successful the final index, and if not nil
    private let memorySize : Int
    private let breadth    : Int

    private var memory     = [KeyType : Recollection<PositionType,CachedType>]()
    
    public init(memorySize:Int, breadth:Int){
        self.memorySize = memorySize
        self.breadth    = breadth
        
//        memory.reserveCapacity(memorySize)
    }
    
    public func remember(at position:PositionType, key:KeyType, value:CachedType){
        if let existingMemory = memory[key] {
            existingMemory[position] = value
        } else {
            memory[key] = Recollection(position: position, cache: value, capacity: 20)
        }
    }
    
    public func recall(at position:PositionType, key:KeyType)->CachedType?{
        return memory[key]?[position]
    }
    
    public var description: String{
        var result = "Cache \(memory.count) of \(memorySize):\n"
        
        for recollection in memory {
            result += "\t\(recollection)\n"
        }
        
        return result
    }
}





