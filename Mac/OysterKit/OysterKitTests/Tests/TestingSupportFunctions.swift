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

import OysterKit
import XCTest

func token(name:String,chars:String?=nil)->Token{
    var actualChars:String
    
    if (chars != nil){
        actualChars = chars!
    } else {
        actualChars = name
    }
    
    return Token(name: name, withCharacters: actualChars)
}

func char(chars:String)->TokenizationState{
    return Characters(from:chars)
}

func printAsTest(tokenizer:Tokenizer, string:String, variableName:String){
    //tokenizer.tokenize("xyxz") == [token("xy"),token("xz")])
    
    print("\nXCTAssert(tokenizer.tokenize(\(variableName)) == [")
    tokenizer.tokenize(string){(token:Token)->Bool in
        print("token(\""+token.name+"\",chars:\""+token.characters+"\"), ")
        return true
    }
    print("])")
}

func dump(izer:Tokenizer,with:String){
    print("\nTokenizing "+with)
    izer.tokenize(with){(token:Token)->Bool in
        print("\t"+token.description)
        return true
    }
    print("\n")
}

extension XCTestCase {
    
    func readBundleFile(fileName:String, ext:String)->String?{
        let bundle = NSBundle(identifier:"com.rwe-uk.OysterKitTests")
        
        if let url = bundle?.URLForResource(fileName, withExtension: ext) {
            return try! String(contentsOfURL: url)
        } else {
           let allFiles =  bundle?.URLsForResourcesWithExtension(nil, subdirectory: nil)
            
            XCTAssert(false, "Could not find \(fileName).\(ext) in bundle, available files are \(allFiles)")
        }
        
        return nil
    }
    
    func assertTokenListsEqual(underTest:[Token],reference:[Token],comparePositions:Bool=false){

        let stopAt = underTest.count < reference.count ? underTest.count : reference.count
        
        XCTAssert(underTest.count == reference.count, "Tokens lists are not the same length: Test Result=\(underTest.count), Reference=\(reference.count)")
        
        if underTest != reference {
            for index in 0..<stopAt {
                let testToken = underTest[index]
                let refToken = reference[index]
                if testToken == refToken {
                    print("OK  : \(testToken)")
                } else {
                    print("FAIL: \(testToken) != \(refToken)")
                }
            }
        }
    }
    
}