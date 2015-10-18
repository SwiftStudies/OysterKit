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

class AppDelegate: NSObject, NSApplicationDelegate, NSTextStorageDelegate {
    let keyTokenizerString = "tokString"
    let keyTokenizerText   = "tokText"
    let keyColors = "tokColors"
    let keyColor = "tokColor"
    
    var buildTokenizerTimer : NSTimer?
    
    @IBOutlet var window: NSWindow!
    @IBOutlet var tokenizerDefinitionScrollView: NSScrollView!
    @IBOutlet var testInputScroller : NSScrollView!
    @IBOutlet var highlighter: TokenHighlighter!
    @IBOutlet var okScriptHighlighter: TokenHighlighter!
    @IBOutlet var colorDictionaryController: NSDictionaryController!
    @IBOutlet var buildProgressIndicator: NSProgressIndicator!
    
    var textString:NSString?
    var lastDefinition:String = ""
    var lastInput = ""
    
    var testInputTextView : NSTextView {
        return testInputScroller.contentView.documentView as! NSTextView
    }
    
    var tokenizerDefinitionTextView : NSTextView {
        return tokenizerDefinitionScrollView.contentView.documentView as! NSTextView
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
        let defaults = NSUserDefaults.standardUserDefaults()

        defaults.setValue(tokenizerDefinitionTextView.string, forKey: keyTokenizerString)
        defaults.setValue(highlighter.textStorage.string, forKey: keyTokenizerText)

        var tokenColorDict = [String:NSData]()
        
        for (tokenName, color): (String, NSColor) in highlighter.tokenColorMap{
            tokenColorDict[tokenName] = NSArchiver.archivedDataWithRootObject(color)
        }
        
        defaults.setValue(tokenColorDict, forKey: keyColors)
    }
    
    func loadFromDefaults(){
        let defaults = NSUserDefaults.standardUserDefaults()
        
        tokenizerDefinitionTextView.string = defaults.stringForKey(keyTokenizerString)
        testInputTextView.string = defaults.stringForKey(keyTokenizerText)
        
        let dictionary = defaults.dictionaryForKey(keyColors) as! Dictionary<String, NSData>
        highlighter.tokenColorMap = [String:NSColor]()
        for (tokenName,tokenColorData) in dictionary {
            let tokenColor : NSColor = NSUnarchiver.unarchiveObjectWithData(tokenColorData) as! NSColor
            highlighter.tokenColorMap[tokenName] = tokenColor
        }
    }
    

    func prepareTextView(view:NSTextView){
        //For some reason IB settings are not making it through
        view.automaticQuoteSubstitutionEnabled = false
        view.automaticSpellingCorrectionEnabled = false
        view.automaticDashSubstitutionEnabled = false
        
        //Change the font, set myself as a delegate, and set a default string
        view.textStorage?.font = NSFont(name: "Courier", size: 14.0)
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        registerDefaults()

        colorDictionaryController.initialKey = "token"
        colorDictionaryController.initialValue = NSColor.grayColor()

        //Tie the highlighters to their text views
        highlighter.textStorage = testInputTextView.textStorage
        okScriptHighlighter.textStorage = tokenizerDefinitionTextView.textStorage
        
        okScriptHighlighter.textDidChange = {
            self.buildTokenizer()
        }
        
        loadFromDefaults()
        
        okScriptHighlighter.tokenColorMap = [
            "loop" : NSColor.purpleColor(),
            "not" : NSColor.purpleColor(),
            "quote" : NSColor.purpleColor(),
            "Char" : NSColor.stringColor(),
            "single-quote" :NSColor.stringColor(),
            "delimiter" : NSColor.stringColor(),
            "token" : NSColor.purpleColor(),
            "variable" : NSColor.variableColor(),
            "state-name" : NSColor.variableColor(),
            "start-branch" : NSColor.purpleColor(),
            "start-repeat" : NSColor.purpleColor(),
            "start-delimited" : NSColor.purpleColor(),
            "end-branch" :NSColor.purpleColor(),
            "end-repeat" : NSColor.purpleColor(),
            "end-delimited" : NSColor.purpleColor(),
            "tokenizer" : NSColor.purpleColor(),
            "exit-state" : NSColor.purpleColor()
        ]
        
        okScriptHighlighter.tokenizer = OKScriptTokenizer()

        prepareTextView(testInputTextView)
        prepareTextView(tokenizerDefinitionTextView)
        
    }
    
    func applicationWillTerminate(notification: NSNotification) {
        saveToDefaults()
    }
    
    
    func doBuild(){
        highlighter.backgroundQueue.addOperationWithBlock(){
            if let newTokenizer:Tokenizer = OKStandard.parseTokenizer(self.tokenizerDefinitionTextView.string!) {
                self.highlighter.tokenizer = newTokenizer
            }
        }
        
        buildProgressIndicator.stopAnimation(self)
    }
    
    func buildTokenizer(){
        if let timer = buildTokenizerTimer {
            timer.invalidate()
        }
        
        buildProgressIndicator.startAnimation(self)
        
        buildTokenizerTimer = NSTimer(timeInterval: 1.0, target: self, selector:Selector("doBuild"), userInfo: nil, repeats: false)
        NSRunLoop.mainRunLoop().addTimer(buildTokenizerTimer!, forMode: NSRunLoopCommonModes)
    }
}

extension NSColor{
    class func variableColor()->NSColor{
        return NSColor(calibratedRed: 0, green: 0.4, blue: 0.4, alpha: 1.0)
    }
    
    class func commentColor()->NSColor{
        return NSColor(calibratedRed: 0, green: 0.6, blue: 0, alpha: 1.0)
    }
    
    class func stringColor()->NSColor{
        return NSColor(calibratedRed: 0.5, green: 0.4, blue: 0.2, alpha: 1.0)
    }
}

