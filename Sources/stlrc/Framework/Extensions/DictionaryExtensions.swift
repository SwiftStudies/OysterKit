//
//  DictionaryExtensions.swift
//  CommandKit
//
//  Created by Sean Alling on 11/8/17.
//

import Foundation


extension Array where Element == Command {
    
    /**
     */
    var numberOfTabs: Int {
        let keys = self.map({ $0.name })
        let largestKey = keys.reduce(into: "", { largest, newValue in
            largest = newValue.count > largest.count ? newValue : largest
        })
        let rawNumberOfTabs = largestKey.count / 4
        let modulo = 10 % rawNumberOfTabs
        return (modulo == 0) ? (rawNumberOfTabs + 1) : rawNumberOfTabs
    }
}

extension Array where Element == Option {
    
    /**
     */
    var numberOfTabs: Int {
        let keys = self.map({ $0.shortForm ?? $0.longForm })
        let largestKey = keys.reduce(into: "", { largest, newValue in
            largest = newValue.count > largest.count ? newValue : largest
        })
        let rawNumberOfTabs = largestKey.count < 4 ? 1 : largestKey.count / 4
        let modulo = 10 % rawNumberOfTabs
        return (modulo == 0) ? (rawNumberOfTabs + 1) : rawNumberOfTabs
    }
}
