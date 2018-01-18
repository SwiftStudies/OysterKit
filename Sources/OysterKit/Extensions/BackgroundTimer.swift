//    Copyright (c) 2014, RED When Excited
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

/// The queue to use for the timers
private let backgroundQueue = DispatchQueue(label: "OysterKitSerial", attributes: [DispatchQueue.Attributes.concurrent], target: nil)

/**
 Essentially a singleton you can never create an instance of because it has no cases. It provides a set of methods for scheduling blocks to run
 in the background.
 */
public enum BackgroundTimer {
    
    /// The queues that have been used
    private static var queues = [String : DispatchQueue]()
    
    
    /**
     Schedules a block to run on the stadard queue for OysterKit.
     
     -Parameter interval: The delay before executing
     -Parameter handler: The block to execute
     -Returns: The resultant `DispatchSourceTimer`
     -SeeAlso: `DispatchInterval.fromSeconds(seconds: Double)->DispatchTimeInterval` for an easy way to create the interval
    */
    public static func schedule(interval: DispatchTimeInterval,handler:@escaping () -> Void) -> DispatchSourceTimer {
        return schedule(queue: nil, interval: interval, handler: handler)
    }
    
    /**
     Schedules a block to run on the `name`d queue for OysterKit.
     
     -Parameter queue: The name of the queue to perform the task on. If it does not exist it will be created
     -Parameter interval: The delay before executing
     -Parameter handler: The block to execute
     -Returns: The resultant `DispatchSourceTimer`
     -SeeAlso: `DispatchInterval.fromSeconds(seconds: Double)->DispatchTimeInterval` for an easy way to create the interval
     */
    public static func schedule(queue name:String?, interval: DispatchTimeInterval,handler:@escaping () -> Void) -> DispatchSourceTimer {
    
        let queue : DispatchQueue
        if let name = name {
            if let existingQueue = queues[name]{
                queue = existingQueue
            } else {
                queue = DispatchQueue(label: name, attributes: [], target: nil)
                queues[name] = queue
            }
        } else {
            queue = backgroundQueue
        }
        
        let result = DispatchSource.makeTimerSource(queue: queue)
    
        result.setEventHandler(handler: handler)
        result.schedule(deadline: DispatchTime.now() + interval)
        result.resume()
        return result
    }
}

/// A utility method
public extension DispatchTimeInterval {
    /**
     Creates a `DispatchTimeInterval` using the number of seconds provided
     
     - Parameter seconds: The number of seconds (as a double)
     - Returns: The appropriate `DispathTimeInterval`
    */
    public static func fromSeconds(_ seconds: Double) -> DispatchTimeInterval {
        return .nanoseconds(Int(seconds * Double(NSEC_PER_SEC)))
    }
}

