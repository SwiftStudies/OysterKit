//
//  Scanner.swift
//  OysterKit
//
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

public class StringScanner : CustomStringConvertible{
    public  let string       : String
    private let scalars      : String.UnicodeScalarView
    public  var scanLocation : String.UnicodeScalarView.Index

    public  var isAtEnd : Bool {
        return scanLocation == scalars.endIndex
    }
    
    public init(_ string:String){
        self.string         = string
        scalars             = string.unicodeScalars
        self.scanLocation   = scalars.startIndex
    }
    
    internal var current : UnicodeScalar {
        return string.unicodeScalars[scanLocation]
    }
    
    public var description: String{
        return "\(scalars.distance(from: scalars.startIndex, to: scanLocation))"
    }
    
    private func advanceLocation(){
        scanLocation = scalars.index(after: scanLocation)
    }
    
    private func setLocation(scalarIndex:String.UnicodeScalarView.Index){
        scanLocation = scalarIndex
    }
    
    public func scanNext()->UnicodeScalar?{
        let startLocation = scanLocation
        
        guard !isAtEnd else {
            setLocation(scalarIndex: startLocation)
            return nil
        }
        
        let result = current
        advanceLocation()
        return result
    }

    ///: Scans all characters from the supplied set, continuing until the scanner hits a character not in the set. Returns true if at least one is found
    public func scan(charactersFrom set:CharacterSet)->Bool{
        return scan(charactersFrom: set, maximumLength: nil)
    }

    ///: Scan a single character from thet set, returning true if the character is found
    public func scan(characterFrom set:CharacterSet)->Bool{
        return scan(charactersFrom: set, maximumLength: 1)
    }
    
    
    private func scan(charactersFrom set:CharacterSet, maximumLength:Int?)->Bool {
        assert((maximumLength ?? 1) > 0, "If set maximumLength must be greater than 0")
        
        let startPosition = scanLocation
        
        var found = 0
        
        while !isAtEnd {
            if !set.contains(current){
                if found < 1 {
                    setLocation(scalarIndex: startPosition)
                    return false
                }
                return true
            }
            advanceLocation()
            found += 1
            if let maximumLength = maximumLength , found == maximumLength {
                return true
            }
        }
        
        if found > 0 {
            return true
        }
        
        setLocation(scalarIndex: startPosition)
        
        return false
    }

    ///: Scan a single character from thet set, returning true if the character is found
    public func scanUpTo(characterFrom set:CharacterSet)->Bool{
        let startPosition = scanLocation
        
        while !isAtEnd && !set.contains(current){
            advanceLocation()
        }
        
        if !set.contains(current){
            setLocation(scalarIndex: startPosition)
            return false
        }
        
        return true
    }
    
    public func scanUpTo(string:String)->Bool{
        let startingPosition = scanLocation
        
        while !isAtEnd {
            var foundSequence = true
            let sequencePosition = scanLocation
            
            for element in string.unicodeScalars {
                //We've hit the end of the collection without finding the sequence
                if isAtEnd {
                    setLocation(scalarIndex: startingPosition)
                    return false
                }
                //We have not found the sequence
                if element != scalars[scanLocation]{
                    foundSequence = false
                    break
                }
                
                advanceLocation()
            }
            
            if foundSequence{
                setLocation(scalarIndex: sequencePosition)
                return true
            }
            
            setLocation(scalarIndex: sequencePosition)
            advanceLocation()
        }
        
        //We got to the end without ever finding the sequence, so reset and return nil
        setLocation(scalarIndex: startingPosition)
        return false
    }
    
    public func scan(string:String)->Bool{
        let startingPosition = scanLocation
        
        for element in string.unicodeScalars{
            if isAtEnd || element != current{
                setLocation(scalarIndex: startingPosition)
                return false
            }
            
            advanceLocation()
        }
        
        return true
    }
}
