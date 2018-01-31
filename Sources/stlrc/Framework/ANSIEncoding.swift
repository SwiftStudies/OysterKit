//
//  ANSIEncoding.swift
//  CommandKit
//
//  Created by Sean Alling on 11/14/17.
//

import Foundation

/**
     An object that represents any ANSI coded stylistic text/strings
 */
public struct ANSIEncoding {
    /**
         A list of all ANSI codes for this encoding object
     */
    public var codes: [Int]
    
    /**
         Returns the ANSI codes of this object in string representation
     */
    public var encoding: String {
        let codeStrings = codes.map { String($0) }
        return ANSIEncoding.escape + codeStrings.joined(separator: ";") + "m"
    }
    
    /**
         ANSI codes that represent text stylization
     */
    public enum Style: Int {
        case none               = 0
        case bold               = 1
        case italic             = 3
        case underline          = 4
        case blink              = 5
        case inverse            = 7
        case concealed          = 8
        case strikethrough      = 9
        case boldOff            = 22
        case italicOff          = 23
        case underlineOff       = 24
        case inverseOff         = 27
        case strikethroughOff   = 29
    }
    
    /**
         ANSI codes that represent text colorization from the terminal
     */
    public enum ForegroundColor: Int {
        case black      = 30
        case red        = 31
        case green      = 32
        case yellow     = 33
        case blue       = 34
        case magenta    = 35
        case cyan       = 36
        case white      = 37
    }
    
    /**
         ANSI codes that represent colorization of the text's background from the terminal
     */
    public enum BackgroundColor: Int {
        case black      = 40
        case red        = 41
        case green      = 42
        case yellow     = 43
        case blue       = 44
        case magenta    = 45
        case cyan       = 46
        case white      = 47
    }
    
    /**
         The ANSI defined escape schema
     */
    public static var escape: String {
        return "\u{001B}["
    }
}

/**
     Internal String Encoding Algorithm
 */
extension String {
    
    fileprivate mutating func stripPrefixedCodes() -> [Int] {
        let workingString = self
        let mSplits = workingString.split(separator: "m").map({ String($0) })
        guard let formerCodeString = mSplits.first else { return [] }
        let formerCodes = formerCodeString.replacingOccurrences(of: ANSIEncoding.escape, with: "").split(separator: ";").flatMap({ Int($0) })
        
        // Strip String
        self = workingString.replacingOccurrences(of: formerCodeString + "m", with: "")
        
        // Return former codes
        return formerCodes
    }
    
    public func encode(with encoding: ANSIEncoding) -> String {
        var codes: [Int] = []
        var workingString = self
        
        if self.hasPrefix(ANSIEncoding.escape) {
            codes = workingString.stripPrefixedCodes()
        }
        
        var formatUpperBound = ANSIEncoding.init(codes: [ANSIEncoding.Style.none.rawValue]).encoding
        if workingString.hasSuffix(formatUpperBound) {
            formatUpperBound = ""
        }
        
        codes += encoding.codes
        codes = Array(Set(codes))
        
        let newANSI = ANSIEncoding(codes: codes)
        let newCodeString = newANSI.encoding
        return newCodeString + workingString + formatUpperBound
    }
}

/**
     User-facing text formatting
 */
extension String {
    
    /**
         Applies the style provided to this string object
     */
    public mutating func applyStyle(_ code: ANSIEncoding.Style) {
        let encoding = ANSIEncoding(codes: [code.rawValue])
        self = self.encode(with: encoding)
    }
    
    /**
         Applies the provided style(s) to this string object
     */
    public mutating func applyStyles(_ codes: ANSIEncoding.Style...) {
        let rawValues = codes.map({ $0.rawValue })
        let encoding = ANSIEncoding(codes: rawValues)
        self = self.encode(with: encoding)
    }
    
    /**
         Returns the string object with the provided style applied
     */
    public func style(_ code: ANSIEncoding.Style) -> String {
        let encoding = ANSIEncoding(codes: [code.rawValue])
        return self.encode(with: encoding)
    }
    
    /**
         Returns the string object with the provided style(s) applied
     */
    public func styles(_ codes: ANSIEncoding.Style...) -> String {
        let rawValues = codes.map({ $0.rawValue })
        let encoding = ANSIEncoding(codes: rawValues)
        return self.encode(with: encoding)
    }
    
    /**
         Applies the color provided to this string object
     */
    public mutating func applyColor(_ code: ANSIEncoding.ForegroundColor) {
        let encoding = ANSIEncoding(codes: [code.rawValue])
        self = self.encode(with: encoding)
    }
    
    /**
         Returns the string object with the provided color applied
     */
    public func color(_ code: ANSIEncoding.ForegroundColor) -> String {
        let encoding = ANSIEncoding(codes: [code.rawValue])
        return self.encode(with: encoding)
    }
    
    /**
         Applies the background color provided to this string object
     */
    public mutating func applyBackgroundColor(_ code: ANSIEncoding.BackgroundColor) {
        let encoding = ANSIEncoding(codes: [code.rawValue])
        self = self.encode(with: encoding)
    }
    
    /**
         Returns the string object with the provided background color applied
     */
    public func backgroundColor(_ code: ANSIEncoding.BackgroundColor) -> String {
        let encoding = ANSIEncoding(codes: [code.rawValue])
        return self.encode(with: encoding)
    }
}

