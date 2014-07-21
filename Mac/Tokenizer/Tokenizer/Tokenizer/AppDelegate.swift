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

let backgroundQueue = NSOperationQueue()

class AppDelegate: NSObject, NSApplicationDelegate, NSTextStorageDelegate {
    let keyTokenizerString = "tokString"
    let keyTokenizerText   = "tokText"
    let keyColors = "tokColors"
    let keyColor = "tokColor"
    
    var parsingOperation = NSOperation()
    
    @IBOutlet var window: NSWindow
    @IBOutlet var tokenizerDefinitionScrollView: NSScrollView
    @IBOutlet var highlighter: Highlight
    @IBOutlet var testInputScroller : NSScrollView

    var textString:NSString?
    var lastDefinition:String = ""
    var lastInput = ""
    
    var testInputTextView : NSTextView {
        return testInputScroller.contentView.documentView as NSTextView
    }
    
    var tokenizerDefinitionTextView : NSTextView {
        return tokenizerDefinitionScrollView.contentView.documentView as NSTextView
    }
    
    func registerDefaults(){
        NSUserDefaults.standardUserDefaults().registerDefaults([
            keyTokenizerString : "begin{\n\t\"O\".\"K\"->oysterKit\n}",
            keyTokenizerText : "OK",
            keyColors : [
                "oysterKit" : NSArchiver.archivedDataWithRootObject(NSColor.purpleColor())
            ]
            ])
    }
    
    func saveToDefaults(){
        var defaults = NSUserDefaults.standardUserDefaults()

        defaults.setValue(tokenizerDefinitionTextView.string, forKey: keyTokenizerString)
        defaults.setValue(highlighter.textStorage.string, forKey: keyTokenizerText)

        var tokenColorDict = [String:NSData]()
        
        for (tokenName:String, color:NSColor) in highlighter.tokenColorMap{
            tokenColorDict[tokenName] = NSArchiver.archivedDataWithRootObject(color)
        }
        
        defaults.setValue(tokenColorDict, forKey: keyColors)
    }
    
    func loadFromDefaults(){
        var defaults = NSUserDefaults.standardUserDefaults()
        
        tokenizerDefinitionTextView.string = defaults.stringForKey(keyTokenizerString)
        testInputTextView.string = defaults.stringForKey(keyTokenizerText)
        
        var dictionary = defaults.dictionaryForKey(keyColors)
        highlighter.tokenColorMap = [String:NSColor]()
        for (tokenName,tokenColorData) in dictionary {
            var tokenColor : NSColor = NSUnarchiver.unarchiveObjectWithData(tokenColorData as NSData) as NSColor
            highlighter.tokenColorMap[tokenName as String] = tokenColor
        }
    }
    

    func prepareTextView(view:NSTextView){
        //For some reason IB settings are not making it through
        view.automaticQuoteSubstitutionEnabled = false
        view.automaticSpellingCorrectionEnabled = false
        view.automaticDashSubstitutionEnabled = false
        
        //Change the font, set myself as a delegate, and set a default string
        view.textStorage.font = NSFont(name: "Courier", size: 14.0)
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        highlighter.textStorage = testInputTextView.textStorage
        registerDefaults()
        prepareTextView(tokenizerDefinitionTextView)
        loadFromDefaults()
        tokenizerDefinitionTextView.textStorage.font = NSFont(name: "Courier", size: 14.0)
        textStorageDidProcessEditing(nil)
        prepareTextView(testInputTextView)
        
        tokenizerDefinitionTextView.textStorage.delegate = self
    }

    class var variableDefinitionColor:NSColor {
        return NSColor(calibratedRed: 0, green: 0.4, blue: 0.4, alpha: 1.0)
    }
    class var commentColor:NSColor {
        return NSColor(calibratedRed: 0, green: 0.6, blue: 0, alpha: 1.0)
    }
    class var stringColor:NSColor {
        return NSColor(calibratedRed: 0.5, green: 0.4, blue: 0.2, alpha: 1.0)
    }
    let tokenColorMap = [
        "loop" : NSColor.purpleColor(),
        "not" : NSColor.purpleColor(),
        "quote" : NSColor.purpleColor(),
        "Char" : AppDelegate.stringColor,
        "single-quote" : AppDelegate.stringColor,
        "delimiter" : AppDelegate.stringColor,
        "token" : NSColor.purpleColor(),
        "variable" : AppDelegate.variableDefinitionColor,
        "state-name" : AppDelegate.variableDefinitionColor,
        "start-branch" : NSColor.purpleColor(),
        "start-repeat" : NSColor.purpleColor(),
        "start-delimited" : NSColor.purpleColor(),
        "end-branch" :NSColor.purpleColor(),
        "end-repeat" : NSColor.purpleColor(),
        "end-delimited" : NSColor.purpleColor(),
        "tokenizer" : NSColor.purpleColor(),
        "exit-state" : NSColor.purpleColor()
    ]
    
    func applyColouringTokens(tokens:[Token]){
        let old = NSMakeRange(0, self.tokenizerDefinitionTextView.textStorage.length)
        self.tokenizerDefinitionTextView.textStorage.removeAttribute(NSForegroundColorAttributeName, range: old)
        self.tokenizerDefinitionTextView.textStorage.removeAttribute(NSFontAttributeName, range: old)
        self.tokenizerDefinitionTextView.textStorage.addAttribute(NSFontAttributeName, value: NSFont(name: "Courier", size: 14.0), range: old)
        
        for token in tokens {
            let tokenRange = NSMakeRange(token.originalStringIndex!, countElements(token.characters))
            
            if let mappedColor = self.tokenColorMap[token.name]? {
                if tokenRange.location+tokenRange.length < old.location+old.length {
                    self.tokenizerDefinitionTextView.textStorage.addAttribute(NSForegroundColorAttributeName, value: mappedColor, range: tokenRange)                    
                }
            }
        }
    }
    
    func buildTokenizer(usingString:String){
        saveToDefaults()

        if let newTokenizer:Tokenizer = OysterKit.parseTokenizer(self.lastDefinition) {
            self.highlighter.tokenizer = newTokenizer
        }
        
        var tokens = TokenizerFile().tokenize(self.lastDefinition)

        let colorText = NSBlockOperation(){
            self.applyColouringTokens(tokens)
        }

        //Todo
        //And we could check here to see if there are already new characters pending and NOT do this
        NSOperationQueue.mainQueue().addOperations([colorText], waitUntilFinished: true)
    }
    
    func textStorageDidProcessEditing(aNotification: NSNotification!){
        if tokenizerDefinitionTextView.string != lastDefinition {
            if parsingOperation.executing{
                //To do... we could just check again in the future to see if 
                //the coloring has been updated..., if another thread got in in the gap
                // then the the text definition will have been updated
                return
            }
            lastDefinition = tokenizerDefinitionTextView.string
            
            //Now we can creaqte the operation
            parsingOperation = NSBlockOperation(){
                self.buildTokenizer(self.lastDefinition)
            }
            backgroundQueue.addOperation(parsingOperation)
        }
    }

}

