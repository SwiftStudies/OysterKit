//
//  SyntaxHighlighter.swift
//  Tokenizer
//
//  Created by Nigel Hughes on 18/07/2014.
//  Copyright (c) 2014 Swift Studies. All rights reserved.
//

import OysterKit
import Foundation

@objc
class SyntaxHighlighter : NSObject, NSTextStorageDelegate{
    var defaultColor : NSColor {
        return NSColor(white: 0, alpha: 1)
    }
    var tokenizer = Tokenizer()
    var lastString = ""
    var tokenColorDictionary : [String:NSColor] = [String:NSColor](){
    didSet{
        applyTokenizer(force: true)
    }
    }
    var tokens = Array<AnyObject>()
    
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
    
    func applyTokenizer(force:Bool=false){
        if force {
            lastString = ""
        }
        if lastString != inputTextView.string {
            
            var appDelegate = NSApplication.sharedApplication().delegate as AppDelegate
            
            appDelegate.saveToDefaults()
            
            lastString = inputTextView.string
            var allTokens = Array<String>()
            
            let old = NSMakeRange(0, inputTextView.textStorage.length)
            inputTextView.textStorage.removeAttribute(NSForegroundColorAttributeName, range: old)
            
            tokenizer.tokenize(inputTextView.string){(token:Token)->Bool in
                allTokens.append(token.name)
                
                let tokenRange = NSMakeRange(token.originalStringIndex!, countElements(token.characters))
                
                if let mappedColor = self.tokenColorDictionary[token.name]? {
                    self.inputTextView.textStorage.addAttribute(NSForegroundColorAttributeName, value: mappedColor, range: tokenRange)
                }
                
                return true
            }
            
            self.tokens = allTokens
        }
    }
    
    func textStorageDidProcessEditing(aNotification: NSNotification!){
        applyTokenizer()
    }
}

