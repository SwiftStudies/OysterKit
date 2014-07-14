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
    
    @IBOutlet var window: NSWindow
    @IBOutlet var tokenView: NSTokenField
    @IBOutlet var scrollView: NSScrollView
    @IBOutlet var tokenizerDefinitionScrollView: NSScrollView
    
    var textString:NSString?
    var lastDefinition:String = ""
    var lastInput = ""
    
    var tokenizer = Tokenizer()
    
    var inputTextView : NSTextView {
        get {
            return scrollView.contentView.documentView as NSTextView
        }
    }
    
    var tokenizerDefinitionTextView : NSTextView {
        return tokenizerDefinitionScrollView.contentView.documentView as NSTextView
    }
    
    
    var tokens = Array<AnyObject>()

    func prepareTextView(view:NSTextView){
        //For some reason IB settings are not making it through
        view.automaticQuoteSubstitutionEnabled = false
        view.automaticSpellingCorrectionEnabled = false
        view.automaticDashSubstitutionEnabled = false
        
        //Change the font, set myself as a delegate, and set a default string
        view.textStorage.font = NSFont(name: "Courier", size: 14.0)
        view.textStorage.delegate = self
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        prepareTextView(inputTextView)
        prepareTextView(tokenizerDefinitionTextView)
        
        tokenizerDefinitionTextView.string = "{\n\t\"O\".\"K\"->oysterKit\n}"
        inputTextView.string = "OK"
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
    
    func textStorageDidProcessEditing(aNotification: NSNotification!){
        
        if tokenizerDefinitionTextView.string != lastDefinition {
            lastDefinition = tokenizerDefinitionTextView.string
            lastInput=""
            let old = NSMakeRange(0, tokenizerDefinitionTextView.textStorage.length)
            tokenizerDefinitionTextView.textStorage.removeAttribute(NSForegroundColorAttributeName, range: old)
            
            tokenizerDefinitionTextView.textStorage.font = NSFont(name: "Courier", size: 14.0)
            
            //The definition is consumped twice. Once here to generate the tokens, 
            //and again when the tokenizer itself is compiled.
            if let newTokenizer:Tokenizer = OysterKit.parseTokenizer(lastDefinition) {
                tokenizer = newTokenizer
            }
            
            var okFileTokenizer = TokenizerFile()
            okFileTokenizer.tokenize(tokenizerDefinitionTextView.string){(token:Token)->Bool in
                let tokenRange = NSMakeRange(token.originalStringIndex!, countElements(token.characters))
                
                if let mappedColor = self.tokenColorMap[token.name]? {
                    self.tokenizerDefinitionTextView.textStorage.addAttribute(NSForegroundColorAttributeName, value: mappedColor, range: tokenRange)
                }
                
                return true
            }
            
        }
        
        if lastInput != inputTextView.string {
            lastInput = inputTextView.string
            var allTokens = Array<String>()
            
            tokenizer.tokenize(inputTextView.string){(token:Token)->Bool in
                allTokens.append(token.name)
                return true
            }
            
            self.tokens = allTokens
        }
    }

}

