//    Copyright (c) 2014, RED When Excited
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
//
//    Createed with heavy reference to: https://github.com/apple/swift-corelibs-foundation/blob/master/Foundation/JSONEncoder.swift#L802
//

import Foundation

/**
 Makes it possible for any `Decodable` to be constructed using a source string and language. You can specify your own
 `AbstractSyntaxTreeConstructor` should you wish.
 */
public extension Decodable {
    /**
     Creates a new instance of the ``Decodeable`` using the supplied source and language.
     
     - Parameter source: The source to be parsed and then decoded
     - Parameter language: The language to parse the source with
     - Returns: A new instance of the Type
    */
    static func decode(_ source:String, using language:Language) throws ->Self{
        return try decode(source, with: HomogenousTree.self, using: language)
    }
    
    /**
     Creates a new instance of the ``Decodeable`` using the supplied source and language. You typically do not need to use this
     variant of the function and can use the simpler ``decode(_ source:String, using language:Language) throws ->Self`` which
     does not require the provision of your own ``DecodableAbstractSyntaxTree``
     
     - Parameter source: The source to be parsed and then decoded
     - Parameter astType: The intermediate ``DecodeableAbstractSyntaxTree``
     - Parameter language: The language to parse the source with
     - Returns: A new instance of the Type
     */
    static func decode<AST:DecodeableAbstractSyntaxTree>(_ source:String, with astType:AST.Type, using language:Language) throws ->Self{
        let ast = try AbstractSyntaxTreeConstructor().build(astType, from: source, using: language)
        
        return try ParsingDecoder().decode(Self.self, using: ast)
    }

}
