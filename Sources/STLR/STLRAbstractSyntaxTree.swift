//    Copyright (c) 2016, RED When Excited
//    All rights reserved.
//
//    Redistribution and use in source and binary forms, with or without
//    modification, are permitted provided that the following conditions are met:
//
//    * Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
//    * Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
//    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
//    FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//    SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import Foundation
import OysterKit

/**
 This AST is automically constructed using a decoder.
 */
struct STLRAbstractSyntaxTree {
    struct Rule : Decodable {
        enum   AssignmentOperators : String, Decodable {
            case becomesEqualTo = "="
        }
        
        let identifier : String
        let assignmentOperators : AssignmentOperators
        let expression : Expression
        let annotations : [Annotation]?
    }
    
    struct Group : Decodable {
        let expression : Expression
    }
    
    struct Literal : Decodable {
        struct String : Decodable {
            let body : Swift.String
            enum CodingKeys : Swift.String, CodingKey { case body = "stringBody" }
        }
        let string : String?
        let number : Int?
        let boolean : Bool? //Doesn't seem to be able to cast boolean
    }
    
    struct Annotation : Decodable {
        let label : String
        let literal : Literal?
    }
    
    struct Element : Decodable {
        //These apply to all
        let negated  : Qualifier?
        let transient : Quantifier?
        let quantifier : Quantifier?
        let annotations : [Annotation]?
        let lookahead   : String?
        
        //Then there will be just one of these
        let group     : Group?
        let terminal  : Terminal?
        let identifier: String?
    }
    
    enum Qualifier : String, Decodable {
        case not = "!"
    }
    
    enum Quantifier : String, Decodable {
        case oneOrMore = "+", optional = "?", noneOrMore = "*", void = "-", transient = "~"
    }
    
    enum CharacterSetName : String, Decodable {
        case letters, uppercaseLetters, lowercaseLetters, alphaNumerics, decimalDigits, whitespacesAndNewlines, whitespaces, newlines, backslash
    }
    
    struct Terminal : Decodable {
        struct String : Decodable{
            let terminalBody : Swift.String
        }
        
        struct CharacterSet : Decodable {
            let characterSetName : CharacterSetName
        }
        
        let terminalString : String?
        let characterSet   : CharacterSet?
        let characterRange : [String]?
    }
    
    class Expression : Decodable {
        let sequence    : [Element]?
        let choice      : [Element]?
        let element     : Element?
    }
    
    let intermediateRepresentation : HomogenousTree
    let rules : [Rule]
    
    init(_ stlrSource : String) throws {
        intermediateRepresentation = try AbstractSyntaxTreeConstructor().build(stlrSource, using: STLR.generatedLanguage)
        
        rules = try ParsingDecoder().decode([Rule].self, using: intermediateRepresentation)
    }

}
