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

public class SYExpressionParser : StackParser{
    var rpnParser = RPNParser()
    
    func processOperator(operatorToken:OperatorToken)->Bool{
        
        while topToken() is OperatorToken{
            let topOp = topToken() as! OperatorToken
            if operatorToken.presidence() <= topOp.presidence(){
                rpnParser.parse(popToken()!)
            } else {
                break
            }
        }
        
        pushToken(operatorToken)
        
        return true
    }
    
    func processCloseBracket()->Bool{
        var topTokenName = topToken()?.name
        while topTokenName != nil && topTokenName != "bracket-open" {
            rpnParser.parse(popToken()!)
            topTokenName = topToken()?.name
        }
        
        if topTokenName == nil {
            print("Missing open bracket")
            return true
        }
        
        return true
    }
    
    override public func parse(token: Token) -> Bool {
        switch token.name{
        case "operator":
            return processOperator(token as! OperatorToken)
        case "integer","float":
            rpnParser.parse(token)
            return true
        case "bracket-open":
            pushToken(token)
            return true
        case "bracket-close":
            return processCloseBracket()
        case "end":
            while (topToken() != nil){
                rpnParser.parse(popToken()!)
            }
            return true
        default:
            return true
        }
    }
    
    func execute(){
        rpnParser.execute()
    }
    
    override public func parseString(string: String, withTokenizer: Tokenizer) {
        rpnParser = RPNParser()
        super.parseString(string, withTokenizer: withTokenizer)
    }
}
