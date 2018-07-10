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

/**
 A pure Swift implementation of a `String` scanner, that can leverage some of the strengths of swift (over using `NSScanner`). In general consumers of
 OysterKit do not need to use this class directly as it is abstracted away by a concrete implementation of `Lexical Analyzer`.
 
 At this point (Swift 4.0) the Swift `String` subsystem is still enjoying a reasonable amount of churn so details of the implementation will change to
 fully leverage any improved performance affordances. However at this point the implementation is based around the `UnicodeScalarView` of a `String`
 as it enables direct cosumption of other useful classes such as `CharacterSet`.
 
 This may change in the future as Swift strings evolve.
 */
public class StringScanner : CustomStringConvertible{
    
    /// The string being scanned
    public  let string       : String
    
    /// The scalar view of the string
    private let scalars      : String.UnicodeScalarView
    
    /// The current scanning index in `scalars`
    public  var scanLocation : String.UnicodeScalarView.Index

    /// `true` if the scanner is at the end of the `String`
    public  var isAtEnd : Bool {
        return scanLocation == scalars.endIndex
    }
    
    /**
    Create a new instance of the class.
 
    - Parameter string: The `String` to be scanned
    */
    public init(_ string:String){
        self.string         = string
        scalars             = string.unicodeScalars
        self.scanLocation   = scalars.startIndex
    }
 
    /// The scalar currently being evaluated (at the "scan head")
    internal var current : UnicodeScalar {
        return string.unicodeScalars[scanLocation]
    }
    
    /// A useful description of the state of the scanner
    public var description: String{
        return "\(scalars.distance(from: scalars.startIndex, to: scanLocation))"
    }
    
    /**
     Moves the scan-head one position forward. It does not do any bounds checking
    */
    private func advanceLocation(){
        scanLocation = scalars.index(after: scanLocation)
    }
    
    /**
     Set the position of the scan-head explicitly
    */
    private func setLocation(scalarIndex:String.UnicodeScalarView.Index){
        scanLocation = scalarIndex
    }
    
    /**
     Advances the scan-head by one position. If it is at the end of the String it will not move (that is the scan-head will not advance past the last character in the `String`.
     
     - Returns: The `UnicodeScalar` currently at the new scan-head position, or nil if the end of the `String` has been reached.
    */
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
    
    /**
     Scans for the supplied regular expression. If the expression is matched the scanner location will be at the end of the match
 
     - Parameter regularExpression: The `NSRegularExpression` to be used
     - Returns: `true` if the regular expression was matched, `false` otherwise
    */
    public func scan(regularExpression regex:NSRegularExpression)->Bool{
        if let matchingResult = regex.firstMatch(in: string, options: NSRegularExpression.MatchingOptions.anchored, range: NSRange(scanLocation..., in: string)) {
            setLocation(scalarIndex: string.unicodeScalars.index(scanLocation, offsetBy: matchingResult.range.length))
            return true
        }
        return false
    }

    /**
     Scans all characters from the supplied set, continuing until the scanner hits a character not in the set.
     
     - Parameter charactersFrom: The `CharacterSet` to scan for
     - Returns: `true` if at least one is found, `false` otherwise
    */
    public func scan(charactersFrom set:CharacterSet)->Bool{
        return scan(charactersFrom: set, maximumLength: nil)
    }

    /**
     Scans a single character from the supplied set
     
     - Parameter charactersFrom: The `CharacterSet` to scan for
     - Returns: `true` if one is found, `false` otherwise
     */
    public func scan(characterFrom set:CharacterSet)->Bool{
        return scan(charactersFrom: set, maximumLength: 1)
    }
    
    /**
     Scans all characters from the supplied set, continuing until the scanner hits a character not in the set or the maximum length is reached.
     
     - Parameter charactersFrom: The `CharacterSet` to scan for
     - Parameter maximumLength: The maximum number of characters to scan for (scanning will successfully stop if the limit is reached). If `nil` then no
     limit is assumed
     - Returns: `true` if at least one is found, `false` otherwise
     */
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

    /**
     Advances the scan-head until a character from the supplied `CharacterSet` is found, or the end of the `String` is reached.
     
     - Parameter charactersFrom: The `CharacterSet` that should stop scanning
     - Returns: `true` if a character from the supplied set is found before the end of the string.
    */
    public func scanUpTo(characterFrom set:CharacterSet)->Bool{
        let startPosition = scanLocation
        
        while !isAtEnd && !set.contains(current){
            advanceLocation()
        }
        
        if isAtEnd || !set.contains(current){
            setLocation(scalarIndex: startPosition)
            return false
        }
        
        return true
    }
    
    /**
     Advances the scan-head until a character from the supplied `String` is found, or the end of the `String` is reached.
     
     - Parameter string: The `String` that should stop scanning
     - Returns: `true` if `string` is found before the end of the source.
     */
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
    
    /**
     Advances the scan-head to the end of the supplied string providing it matches.
     
     - Parameter string: The `String` that should be matched
     - Returns: `true` if `string` is sfound strating from the current scan-head position and before the end of the source.
     */
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
