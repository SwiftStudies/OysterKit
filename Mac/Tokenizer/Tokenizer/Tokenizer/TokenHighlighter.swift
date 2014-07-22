//
//  SyntaxHighlighter.swift
//  OysterKit Mac
//
//  Created by Nigel Hughes on 21/07/2014.
//  Copyright (c) 2014 RED When Excited Limited. All rights reserved.
//

import Cocoa
import OysterKit

let __TokenKey = "OKToken"

@objc
class TokenHighlighter : NSObject, NSTextStorageDelegate, NSLayoutManagerDelegate{
    var textDidChange:()->() = {() in
    }
    var highlightingDelay : NSTimeInterval = 0.5
    
    var textStorage:NSTextStorage!{
    willSet{
        if let reallyAvailable = textStorage? {
            textStorage.delegate = nil
        }
    }
    didSet{
        textStorage.delegate = self
    }
    }
    
    var tokenColorMap = [String:NSColor]()
    
    var tokenizer:Tokenizer = Tokenizer(){
    didSet{
        self.tokenize()        
    }
    }
    
    var backgroundQueue = NSOperationQueue()
    var tokenizationOperation = NSOperation()
    var editedRange:NSRange?
    
    func tokenize(string:String, usesRange:NSRange){
        
        var layoutManagers = self.textStorage.layoutManagers as [NSLayoutManager]
        
        let limit = countElements(self.textStorage.string as String)
        
        
        let tokens = tokenizer.tokenize(string)
        
        let applyColoring = NSBlockOperation(){
            var inRange:NSRange
            
            if usesRange.end > limit {
                inRange = NSMakeRange(usesRange.location, limit-usesRange.location)
            } else {
                inRange = usesRange
            }
            
            for layoutManager in layoutManagers {
                layoutManager.delegate = self
                layoutManager.removeTemporaryAttribute(__TokenKey, forCharacterRange: inRange)
            }
            
            
            for token in tokens {
                let tokenRange = NSMakeRange(inRange.location+token.originalStringIndex!, countElements(token.characters))
                
                if tokenRange.location + tokenRange.length < limit {
                    for layoutManager in layoutManagers {
                        layoutManager.addTemporaryAttribute(__TokenKey, value: token, forCharacterRange: tokenRange)
                    }
                }
            }
        }
        
        NSOperationQueue.mainQueue().addOperations([applyColoring], waitUntilFinished: false)
    }
    
    func tokenize(){
        tokenize(textStorage.string,usesRange: NSMakeRange(0, textStorage.length))
    }
    
    func prepareToHighlight(){
        textDidChange()
        
        let finalRange = editedRange ? editedRange! : self.textStorage.editedRange
        
        var actualRangeStart = finalRange.location
        var actualRangeEnd = finalRange.end
        var parseLocation = 0
        var foundStart = false
        
        for character in self.textStorage.string as String {
            if character == "\n" {
                if parseLocation < finalRange.location {
                    actualRangeStart = parseLocation
                } else if parseLocation > finalRange.end{
                    actualRangeEnd = parseLocation
                    break
                }
            }
            
            parseLocation++
        }
        
        let nsString : NSString = textStorage.string
        
        let adaptiveRange = NSMakeRange(actualRangeStart, actualRangeEnd-actualRangeStart)
        let adaptiveString = nsString.substringWithRange(adaptiveRange)
        
        let string = self.textStorage.string as String
        let tokenizeRange = NSMakeRange(0, countElements(string))
        
        
        tokenizationOperation = NSBlockOperation(){
            self.tokenize(adaptiveString, usesRange:adaptiveRange)
        }
        
        backgroundQueue.addOperation(tokenizationOperation)
    }
    
    func textStorageDidProcessEditing(notification: NSNotification!) {
        
//        editedRange = editedRange ? editedRange!.unionWith(textStorage.editedRange) : textStorage.editedRange
        
        if tokenizationOperation.executing {
            return
        }

        editedRange = textStorage.editedRange
        
        
        prepareToHighlight()
    }
    
    func layoutManager(layoutManager: NSLayoutManager!, shouldUseTemporaryAttributes attrs: [NSObject : AnyObject]!, forDrawingToScreen toScreen: Bool, atCharacterIndex charIndex: Int, effectiveRange effectiveCharRange: NSRangePointer) -> [NSObject : AnyObject]! {
        if !toScreen {
            return attrs
        }
        
        //This should never happen, but does!
        if !attrs {
            return attrs
        }
        
        let tokenValue:AnyObject? = attrs[__TokenKey]
        
        if let token:Token = attrs[__TokenKey] as? Token {
            if let color = tokenColorMap[token.name] {
                var returnAttributes : NSMutableDictionary = NSMutableDictionary(dictionary: attrs)
                
                returnAttributes[NSForegroundColorAttributeName] = color
                
                return returnAttributes
            }
        }
        
        return attrs
    }
}

extension NSRange{
    var end : Int {
        return length+location
    }
    
    func unionWith(range:NSRange)->NSRange{
        let newLocation = range.location < self.location ? range.location : self.location
        let newEnd = range.end > self.end ? range.end : self.end
        
        return NSMakeRange(newLocation, newEnd-newLocation)
    }
}