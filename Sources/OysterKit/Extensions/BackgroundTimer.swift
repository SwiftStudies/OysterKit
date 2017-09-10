//
//  BackgroundTimer.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

private let backgroundQueue = DispatchQueue(label: "OysterKitSerial", attributes: [DispatchQueue.Attributes.concurrent], target: nil)

public enum BackgroundTimer {
    private static var queues = [String : DispatchQueue]()
    
    public static func schedule(interval: DispatchTimeInterval,handler:@escaping () -> Void) -> DispatchSourceTimer {
        return schedule(queue: nil, interval: interval, handler: handler)
    }
    
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

public extension DispatchTimeInterval {
    public static func fromSeconds(_ seconds: Double) -> DispatchTimeInterval {
        return .nanoseconds(Int(seconds * Double(NSEC_PER_SEC)))
    }
}

