//
//  SyntaxHighlighter.swift
//  OysterKit Mac
//
//  Created by Nigel Hughes on 21/07/2014.
//  Copyright (c) 2014 RED When Excited Limited. All rights reserved.
//

import Cocoa

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
    var tokenizer:Tokenizer = Tokenizer()
    
    var backgroundQueue = NSOperationQueue()
    var tokenizationOperation = NSOperation()
    
    func tokenize(string:String, inRange:NSRange){
        
        var layoutManagers = self.textStorage.layoutManagers as [NSLayoutManager]
        
        for layoutManager in layoutManagers {
            layoutManager.delegate = self
            layoutManager.removeTemporaryAttribute(__TokenKey, forCharacterRange: inRange)
        }
        
        tokenizer.tokenize(string){(token:Token)->Bool in
            let tokenRange = NSMakeRange(token.originalStringIndex!, countElements(token.characters))
            
            for layoutManager in layoutManagers {
                layoutManager.addTemporaryAttribute(__TokenKey, value: token, forCharacterRange: tokenRange)
            }
            
            return true
        }
    }
    
    func textStorageDidProcessEditing(notification: NSNotification!) {
        if tokenizationOperation.executing {
            return
        }

        let editedRange = self.textStorage.editedRange
        
        let string = self.textStorage.string
        let tokenizeRange = NSMakeRange(0, string.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        
        let blockOp = NSBlockOperation(){
            self.tokenize(string, inRange: tokenizeRange)
        }
        
        backgroundQueue.addOperation(blockOp)
    }
    
    func layoutManager(layoutManager: NSLayoutManager!, shouldUseTemporaryAttributes attrs: [NSObject : AnyObject]!, forDrawingToScreen toScreen: Bool, atCharacterIndex charIndex: Int, effectiveRange effectiveCharRange: NSRangePointer) -> [NSObject : AnyObject]! {
        if !toScreen {
            return attrs
        }
        
        if let token:Token = attrs[__TokenKey] as? Token {
            if let color = tokenColorMap[token.name] {
                var returnAttributes : NSDictionary = NSDictionary(dictionary: attrs)
                
                returnAttributes.setValue(color, forKey: NSForegroundColorAttributeName)
                
                return returnAttributes
            }
        }
        
        return attrs
    }
}