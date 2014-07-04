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

class AppDelegate: NSObject, NSApplicationDelegate {

    
    @IBOutlet var window: NSWindow
    @IBOutlet var tokenView: NSTokenField
    @IBOutlet var scrollView: NSScrollView
    
    var textString:NSString?
    
    var inputTextView : OKTextView {
        get {
            return scrollView.contentView.documentView as OKTextView
        }
    }
    
    
    var tokens = Array<AnyObject>()
    
    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        // Insert code here to initialize your application
        inputTextView.okDelegate.tokenizer.branch(
            OysterKit.number,
            OysterKit.word,
            OysterKit.blanks,
            OysterKit.punctuation,
            OysterKit.eot
        )
        
    }
    

    func applicationWillTerminate(aNotification: NSNotification?) {
        // Insert code here to tear down your application
    }
}

//
// Working around compiler crash with NSTextViewDelegate
//
class TextViewDelegate: NSObject {
    var tokenizer = Tokenizer()
    
    var tokenizationString:String = ""
    
    
    func change(textView: NSTextView!){
        if textView.string != tokenizationString {
            tokenizationString = textView.string
            let tokens = tokenizer.tokenize(tokenizationString)
            
            var tokenStrings = Array<AnyObject>()
            for token in tokens {
                tokenStrings.append(token.name+":"+token.characters)
            }
            
            let appDel:AppDelegate = NSApplication.sharedApplication().delegate as AppDelegate
            appDel.tokens = tokenStrings
        }
    }
}

class OKTextView: NSTextView {
    let okDelegate = TextViewDelegate()
    
    override func didChangeText() {
        okDelegate.change(self)
    }
}

