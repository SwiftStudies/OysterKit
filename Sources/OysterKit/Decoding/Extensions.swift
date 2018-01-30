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
     Creates a new instance of the Decoable using the supplied source and language.
     
     - Parameter source: The source to be parsed and then decoded
     - Parameter language: The language to parse the source with
     - Parameter using: The Abstract Syntax Tree Type to use, it must implemented both Parsable and DecodableNode
     - Returns: A new instance of the Type
    */
    static func parse<T>(source:String, using language:Language, and ast:T.Type) throws ->Self where T : Parsable, T:DecodeableNode{
        
        // TODO: Make it first create the IR using the supplied constructor. It should then check to make sure that the resultant AST is a decodable
        // node. This essentially allows alternative implementations to be provided for the intermediate form allowing rework of the AST before decoding
        let instance = try ParsingDecoder().decode(Self.self, from: source, with: language, ast: ast)

        return instance
    }
    
    /**
     Creates a new instance of the Decoable using the supplied source and language. A `HomogenousTree` will be used as the keyed data source for the decoder
     
     - Parameter source: The source to be parsed and then decoded
     - Parameter language: The language to parse the source with
     - Returns: A new instance of the Type
     */
    static func parse(source:String, using language:Language) throws ->Self{
        return try parse(source: source, using: language, and: HomogenousTree.self)
    }

}
