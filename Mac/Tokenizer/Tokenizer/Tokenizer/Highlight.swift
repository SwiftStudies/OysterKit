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
class Highlight : NSObject, NSTextStorageDelegate, NSLayoutManagerDelegate{
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
        NSOperationQueue.mainQueue().addOperationWithBlock(){
            self.tokenize()
        }
        
    }
    }
    
    var backgroundQueue = NSOperationQueue()
    var tokenizationOperation = NSOperation()
    
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
    
    func textStorageDidProcessEditing(notification: NSNotification!) {
        if tokenizationOperation.executing {
            return
        }

        var layoutManagers = self.textStorage.layoutManagers as [NSLayoutManager]
        
        let fullRange = NSMakeRange(0, self.textStorage.length)

        let editedRange = self.textStorage.editedRange
        var actualRangeStart = editedRange.location
        
        var foundBreak = false
        
        while actualRangeStart > 0 {
            var myRange = NSMakeRange(0,0)
            let tokenAtChar : AnyObject! = layoutManagers[0].temporaryAttribute(__TokenKey, atCharacterIndex: actualRangeStart, longestEffectiveRange: &myRange, inRange:fullRange)
            if tokenAtChar {
                actualRangeStart = myRange.location
                break
            } else {
                foundBreak = true
                actualRangeStart = myRange.location
            }
            actualRangeStart--
        }

        var actualRangeEnd = editedRange.location+editedRange.length
        foundBreak = false
        while actualRangeEnd < textStorage.length {
            var myRange = NSMakeRange(0,0)
            let tokenAtChar : AnyObject! = layoutManagers[0].temporaryAttribute(__TokenKey, atCharacterIndex: actualRangeEnd, effectiveRange: &myRange)

            if tokenAtChar {
                actualRangeEnd = myRange.location+myRange.length
                break
            } else {
                actualRangeEnd = myRange.location+myRange.length
            }
            
            
            actualRangeEnd++
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
}