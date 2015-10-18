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

let __emancipateStates = true

public class Tokenizer : TokenizationState {
    var namedStates = [String:Named]()
    
    public override init(){
        super.init()
    }
    
    public init(states:[TokenizationState]){
        super.init()
        branches = states
    }
    
    public func tokenize(string: String, newToken: (Token)->Bool) {
        let emancipatedTokenization = TokenizeOperation(legacyTokenizer: self)
        
        emancipatedTokenization.tokenize(string, tokenReceiver: newToken)
    }
    
    public func tokenize(string:String) -> [Token]{
        var tokens = Array<Token>()
        
        tokenize(string, newToken: {(token:Token)->Bool in
            tokens.append(token)
            return true
        })

        return tokens
    }
    
    override public class func convertFromStringLiteral(value: String) -> Tokenizer {
        if let parsedTokenizer = OKStandard.parseTokenizer(value) {
            return parsedTokenizer
        }
        return Tokenizer()
    }
    
    override public class func convertFromExtendedGraphemeClusterLiteral(value: String) -> Tokenizer {
        return Tokenizer.convertFromStringLiteral(value)
    }
    
    override func serialize(indentation: String) -> String {
        var output = ""
        
        for (name,state) in namedStates {
            _ = state.serialize("")
            output+="\(name) = \(state.rootState.description)\n"
        }
        
        output+="begin\n"
        
        return output+"{\n"+serializeStateArray("\t", states: branches)+"}"
    }
    
}





