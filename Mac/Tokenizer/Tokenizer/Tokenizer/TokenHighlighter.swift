/*
Copyright (c) 2014, RED When Excited
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import Cocoa
import OysterKit

let __TokenKey = "OKToken"

@objc
class TokenHighlighter : NSObject, NSTextStorageDelegate, NSLayoutManagerDelegate{
    var textDidChange:()->() = {() in
    }
    var highlightingDelay : NSTimeInterval = 0.5
    var highlightingTimer : NSTimer?
    
    var textStorage:NSTextStorage!{
    willSet{
        if let reallyAvailable = textStorage {
            if let oldValue = textStorage {
                oldValue.delegate = nil
            }
        }
    }
    didSet{
        textStorage.delegate = self
    }
    }
    
    var tokenColorMap = [String:NSColor]()
    
    var tokenizer:Tokenizer = Tokenizer(){
    didSet{
        editedRange = NSMakeRange(0,textStorage.string.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        scheduleHighlighting()
    }
    }
    
    var backgroundQueue = NSOperationQueue()
    var tokenizationOperation = NSOperation()
    var editedRange:NSRange?
    
    func tokenize(string:String, usesRange:NSRange){
        
        var layoutManagers = self.textStorage.layoutManagers as! [NSLayoutManager]
        
        let limit = count(self.textStorage.string as String)
        
        println("tokenizer is \(tokenizer)")
        
        let tokens = tokenizer.tokenize(string)
        
        let tokens2 = tokenizer.tokenize("OK is a test")
        
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
                let tokenRange = NSMakeRange(inRange.location+token.originalStringIndex!, count(token.characters))
                
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
        if tokenizationOperation.executing {
            scheduleHighlighting()
            return
        }
    
        highlightingTimer = nil
        
        textDidChange()
        
        let finalRange = (editedRange != nil) ? editedRange! : self.textStorage.editedRange
        editedRange = nil
        
        println("Using base range: \(finalRange)")
        
        
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
        
        
        println("Adaptive range: \(adaptiveRange)")
        
        
        let adaptiveString = nsString.substringWithRange(adaptiveRange)
        
        let string = self.textStorage.string as String
        let tokenizeRange = NSMakeRange(0, count(string))
        
        
        tokenizationOperation = NSBlockOperation(){
            self.tokenize(adaptiveString, usesRange:adaptiveRange)
        }
        
        backgroundQueue.addOperation(tokenizationOperation)
    }
    
    func scheduleHighlighting(){
        if let timer = highlightingTimer {
            timer.invalidate()
            highlightingTimer = nil
        }
        
        highlightingTimer = NSTimer(timeInterval: highlightingDelay, target: self, selector: Selector("prepareToHighlight"), userInfo: nil, repeats: false)
        NSRunLoop.mainRunLoop().addTimer(highlightingTimer!, forMode: NSRunLoopCommonModes)
    }
    
    func textStorageDidProcessEditing(notification: NSNotification) {
        editedRange = editedRange != nil ? editedRange!.unionWith(textStorage.editedRange) : textStorage.editedRange
        
        scheduleHighlighting()
    }
    
    func layoutManager(layoutManager: NSLayoutManager, shouldUseTemporaryAttributes attrs: [NSObject : AnyObject], forDrawingToScreen toScreen: Bool, atCharacterIndex charIndex: Int, effectiveRange effectiveCharRange: NSRangePointer) -> [NSObject : AnyObject]? {
        if !toScreen {
            return attrs
        }
        
        //This should never happen, but does!
        if attrs.count == 0 {
            return attrs
        }
        
        let tokenValue:AnyObject? = attrs[__TokenKey]
        
        if let token:Token = attrs[__TokenKey] as? Token {
            if let color = tokenColorMap[token.name] {
                var returnAttributes : NSMutableDictionary = NSMutableDictionary(dictionary: attrs)
                
                returnAttributes[NSForegroundColorAttributeName] = color
                
                return returnAttributes as [NSObject : AnyObject]
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