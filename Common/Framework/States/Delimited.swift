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


import Foundation

class Delimited : Branch{
    let openingDelimiter:String
    let closingDelimiter:String
    
    var consumedFirstDelimiter = false

    var generateTokenAndExit = false
    
    var delimetedStates:Array<TokenizationState>

    init(open:String,close:String,states:TokenizationState...){
        self.openingDelimiter = open
        self.closingDelimiter = close
        self.delimetedStates = states
        
        //Initialise super class
        super.init()
        self.delimetedStates.unshare()
        self.delimetedStates.append(self)
    }
    
    init(delimiter:String,states:TokenizationState...){
        self.openingDelimiter = delimiter
        self.closingDelimiter = delimiter
        self.delimetedStates = states
        
        //Initialise super class
        super.init()
        self.delimetedStates.unshare()
        self.delimetedStates.append(self)
    }
    
    override func couldEnterWithCharacter(character: UnicodeScalar, controller: TokenizationController) -> Bool {
        let delimiter = consumedFirstDelimiter ? closingDelimiter : openingDelimiter
        
        if delimiter == "\(character)" {
            return true
        } else {
            return false
        }
    }
    
    override func consume(character: UnicodeScalar, controller: TokenizationController) -> TokenizationStateChange {
        if generateTokenAndExit{
            generateTokenAndExit = false

            if let token = generateToken(controller) {
                controller.processToken(token)
            }
            
            if consumedFirstDelimiter{
                controller.pop()
            } else {
                controller.push(self.delimetedStates)
            }
            consumedFirstDelimiter = !consumedFirstDelimiter
            
            return TokenizationStateChange.Exit
        }
        
        generateTokenAndExit = true
        return TokenizationStateChange.None
    }
    
    override func description() -> String {
        return "Delimited \(openingDelimiter)-\(closingDelimiter) with states "
    }
}