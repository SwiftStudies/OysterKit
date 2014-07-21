//
//  SyntaxHighlighter.swift
//  Tokenizer
//
//  Created by Nigel Hughes on 18/07/2014.
//  Copyright (c) 2014 Swift Studies. All rights reserved.
//

import OysterKit
import Cocoa

@objc
class SyntaxHighlighter : NSObject, NSTextStorageDelegate{
    var defaultColor : NSColor {
        return NSColor(white: 0, alpha: 1)
    }
    var tokenizer : Tokenizer = Tokenizer(){
    didSet{
        applyTokenizer(force: true)
    }
    }
    var lastString = ""
    var tokenColorDictionary : [String:NSColor] = [String:NSColor](){
    didSet{
        applyTokenizer(force: true)
    }
    }
    var tokens = Array<AnyObject>()
    var tokenizingOperation = NSOperation()
    
    @IBOutlet var inputScrollView: NSScrollView
    @IBOutlet var tokenView: NSTokenField
    
    //Works around a beta-bug
    var inputTextView : NSTextView {
    get {
        return inputScrollView.contentView.documentView as NSTextView
    }
    }
        
    func begin(){
        //For some reason IB settings are not making it through
        inputTextView.automaticQuoteSubstitutionEnabled = false
        inputTextView.automaticSpellingCorrectionEnabled = false
        inputTextView.automaticDashSubstitutionEnabled = false
        inputTextView.richText = false
        
        
        //Change the font, set myself as a delegate, and set a default string
        inputTextView.textStorage.font = NSFont(name: "Courier", size: 14.0)
        inputTextView.textStorage.delegate = self
        applyTokenizer()
    }
    
    func doColoringWithTokens(coloringTokens:[Token]){
        let old = NSMakeRange(0, inputTextView.textStorage.length)
        inputTextView.textStorage.removeAttribute(NSForegroundColorAttributeName, range: old)
        
        var allStringTokens = [String]()
        
        for token in coloringTokens {
            let tokenRange = NSMakeRange(token.originalStringIndex!, countElements(token.characters))
            
            if let mappedColor = self.tokenColorDictionary[token.name]? {
                self.inputTextView.textStorage.addAttribute(NSForegroundColorAttributeName, value: mappedColor, range: tokenRange)
            }
            
            allStringTokens.append(token.description)
        }
        
        self.tokens = allStringTokens
    }
    
    func makeTokensAndColor(){
        var appDelegate = NSApplication.sharedApplication().delegate as AppDelegate
        
        appDelegate.saveToDefaults()
        var allTokens = tokenizer.tokenize(inputTextView.string)
        
        let blockColoring = NSBlockOperation(){
            self.doColoringWithTokens(allTokens)
        }
        
        NSOperationQueue.mainQueue().addOperations([blockColoring], waitUntilFinished: true)
    }
    
    func applyTokenizer(force:Bool=false){
        if force {
            lastString = ""
        }
        if lastString != inputTextView.string {
            if tokenizingOperation.executing{
                //To do... we could just check again in the future to see if
                //the coloring has been updated..., if another thread got in in the gap
                // then the the text definition will have been updated
                return
            }
            lastString = inputTextView.string
            
            //Now we can creaqte the operation
            tokenizingOperation = NSBlockOperation(){
                self.makeTokensAndColor()
            }
            backgroundQueue.addOperation(tokenizingOperation)
        }
    }
    
    func textStorageDidProcessEditing(aNotification: NSNotification!){
        applyTokenizer()
    }
}

