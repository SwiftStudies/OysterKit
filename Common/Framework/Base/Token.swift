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

class Token : Printable{
    let name:String
    var characters:String = ""
    
    init(name:String){
        self.name = name
    }

    init(name:String, withCharacters:String){
        self.name = name
        self.characters = withCharacters
    }
    
    var description : String {
        return "\(name) '\(characters)'"
    }
    
    class EndOfTransmissionToken : Token {
        init(){
            super.init(name: "End of Transmission",withCharacters: "")
        }
    }
    
    class ErrorToken: Token{
        let problem : String
        
        init(forString:String, problemDescription:String){
            problem = problemDescription
            super.init(name: "Error", withCharacters: forString)
        }
        
        init(forCharacter:UnicodeScalar,problemDescription:String){
            problem = problemDescription
            super.init(name: "Error", withCharacters: "\(forCharacter)")
        }
        
        override var description:String {
            return super.description+" - "+problem
        }
    }


}


