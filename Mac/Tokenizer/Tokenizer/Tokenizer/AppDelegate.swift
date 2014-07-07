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

    class var stateDefinitionColor:NSColor {
        return NSColor(calibratedRed: 0, green: 0.6, blue: 0, alpha: 1.0)
    }
    
    let tokenColorMap = [
        "not" : NSColor.redColor(),
        "quote" : NSColor.redColor(),
        "Char" : NSColor.redColor(),
        "single-quote" : NSColor.redColor(),
        "delimiter" : NSColor.redColor(),
        "token" : NSColor.purpleColor(),
        "variable" : NSColor.blueColor(),
        "start-branch" : AppDelegate.stateDefinitionColor,
        "start-repeat" : AppDelegate.stateDefinitionColor,
        "start-delimited" : AppDelegate.stateDefinitionColor,
        "end-branch" : AppDelegate.stateDefinitionColor,
        "end-repeat" : AppDelegate.stateDefinitionColor,
        "end-delimited" : AppDelegate.stateDefinitionColor,
    ]
    
    
    @IBOutlet var window: NSWindow
    @IBOutlet var tokenView: NSTokenField
    @IBOutlet var scrollView: NSScrollView
    
    var textString:NSString?
    
    var inputTextView : NSTextView {
        get {
            return scrollView.contentView.documentView as NSTextView
        }
    }
    
    
    var tokens = Array<AnyObject>()
    
    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        // Insert code here to initialize your application
        inputTextView.automaticQuoteSubstitutionEnabled = false
        inputTextView.automaticSpellingCorrectionEnabled = false
        inputTextView.automaticDashSubstitutionEnabled = false
        inputTextView.textStorage.font = NSFont(name: "Courier", size: 14.0)
        inputTextView.textStorage.delegate = self
        inputTextView.string = "{\n\t\"O\".\"K\"->oysterKit\n}"

    }
    

    func applicationWillTerminate(aNotification: NSNotification?) {
        // Insert code here to tear down your application
    }
    
    func textStorageWillProcessEditing(aNotification: NSNotification!){

    }

    func textStorageDidProcessEditing(aNotification: NSNotification!){
        let old = NSMakeRange(0, inputTextView.textStorage.length)
        inputTextView.textStorage.removeAttribute(NSForegroundColorAttributeName, range: old)
        
        inputTextView.textStorage.font = NSFont(name: "Courier", size: 14.0)
        
        
        var okFileTokenizer = TokenizerFile()
        var allTokens = Array<String>()
        okFileTokenizer.tokenize(inputTextView.string){(token:Token)->Bool in
            let tokenRange = NSMakeRange(token.originalStringIndex!, countElements(token.characters))
            allTokens.append(token.description)
            self.tokens = allTokens

            if let mappedColor = self.tokenColorMap[token.name]? {
                self.inputTextView.textStorage.addAttribute(NSForegroundColorAttributeName, value: mappedColor, range: tokenRange)
            }
            
            return true
        }
    }

}

