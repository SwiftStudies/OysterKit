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
 A generic class for capturing cached types which have can have more than one position
 */
private final class Recollection<PositionType:Comparable, CachedType>{
    /// The actual cache of tuples of position and what was cached
    var events        = [(position:PositionType, cache:CachedType)]()
    
    /// The limited size of the cache (FIFO on overflow)
    let capacity    : Int
    
    /**
     Initialises the cache with an initial entry
     
     - Parameter position: The position of the initial cached entry
     - Parameter cache: The result to be cached
     - Parameter capacity: The size of the cache
    */
    init(position:PositionType, cache:CachedType, capacity:Int) {
        self.capacity = capacity
        events.reserveCapacity(capacity)
        events.append((position,cache))
    }
    
    /**
     Retreive or set the cached entry at the specified position
     
     - Parameter position: The position that a cached entry is desired for
     - Returns: The cached entry at that position or `nil` if there is no entry at that position
    */
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
}

/**
 A generic cache that can be used in your own `IntermediateRepresentation`
 */
public final class StateCache<PositionType:Comparable,KeyType:Hashable,CachedType> : CustomStringConvertible{
    /// The depth of the cache
    private let memorySize : Int
    
    /// The breadth of the cache (how many positions per entry)
    private let breadth    : Int

    /// The actual cache
    private var memory     = [KeyType : Recollection<PositionType,CachedType>]()
    
    /**
     Creates a new instance of the cache
     
     - Parameter memory: The requied memroy size
     - Parameter breadth: The required depth of the cache
    */
    public init(memorySize:Int, breadth:Int){
        self.memorySize = memorySize
        self.breadth    = breadth
    }

    /**
     Adds new entry to the cache. This may knock out something already in the cache.
     
     - Parameter at: The position for the cached entry
     - Parameter key:  The key for the entry
     - Parameter value: The value to be cached
    */
    public func remember(at position:PositionType, key:KeyType, value:CachedType){
        if let existingMemory = memory[key] {
            existingMemory[position] = value
        } else {
            memory[key] = Recollection(position: position, cache: value, capacity: 20)
        }
    }
    
    /**
     Retreives the cached entry with the specified key and position if any
     
     - Parameter at: The position
     - Parameter key: The desired key
     - Returns: The entry at that position with that key or `nil` if nothing is cached
    */
    public func recall(at position:PositionType, key:KeyType)->CachedType?{
        return memory[key]?[position]
    }
    
    /// A human readable description of the cache
    public var description: String{
        var result = "Cache \(memory.count) of \(memorySize):\n"
        
        for recollection in memory {
            result += "\t\(recollection)\n"
        }
        
        return result
    }
}





