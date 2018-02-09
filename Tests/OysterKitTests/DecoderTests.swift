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

import XCTest
import OysterKit

fileprivate struct OneOfEverything : Decodable, Equatable{
    static func ==(lhs: OneOfEverything, rhs: OneOfEverything) -> Bool {
        if lhs.boolean != rhs.boolean {return false}
        if lhs.integer != rhs.integer {return false}
        if lhs.byte != rhs.byte {return false}
        if lhs.word != rhs.word {return false}
        if lhs.longWord != rhs.longWord {return false}
        if lhs.longLongWord != rhs.longLongWord {return false}
        if lhs.unsignedInteger != rhs.unsignedInteger {return false}
        if lhs.unsignedByte != rhs.unsignedByte {return false}
        if lhs.unsignedWord != rhs.unsignedWord {return false}
        if lhs.unsignedLongWord != rhs.unsignedLongWord {return false}
        if lhs.unsignedLongLongWord != rhs.unsignedLongLongWord {return false}
        if lhs.float != rhs.float {return false}
        if lhs.double != rhs.double {return false}
        if lhs.string != rhs.string {return false}
        if lhs.possiblyNil != rhs.possiblyNil {return false}

        return true
    }
    
    let boolean                 : Bool
    let integer                 : Int
    let byte                    : Int8
    let word                    : Int16
    let longWord                : Int32
    let longLongWord            : Int64
    let unsignedInteger         : UInt
    let unsignedByte            : UInt8
    let unsignedWord            : UInt16
    let unsignedLongWord        : UInt32
    let unsignedLongLongWord    : UInt64
    let float                   : Float
    let double                  : Double
    let string                  : String
    let possiblyNil             : String?
}

class DecoderTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testTypeArray<T : Decodable>(testData : String, typeRule:Rule) throws ->T{
        let grammar : [Rule] = [
            ParserRule.sequence(produces: OneOfEverythingGrammar.oneOfEverything, [
                ParserRule.repeated(produces: OneOfEverythingGrammar._transient, typeRule, min: 1, limit: nil, [:])
                ], [:])
            
        ]
        
        return try T.decode(testData, using: grammar.language)

    }
    
    func testBoolArray(){
        do{
            let result : [Bool] = try testTypeArray(
                testData: "true false true",
                typeRule: OneOfEverythingGrammar.boolean._rule())
            XCTAssertEqual(result, [true, false, true])
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testStringArray(){
        do{
            let result : [String] = try testTypeArray(
                testData: "true false true",
                typeRule: OneOfEverythingGrammar.boolean._rule())
            XCTAssertEqual(result, ["true", "false", "true"])
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testIntArray(){
        do{
            let result : [Int] = try testTypeArray(
                testData: "1 0 1",
                typeRule: OneOfEverythingGrammar.integer._rule())
            XCTAssertEqual(result, [1, 0, 1])
        } catch {
            XCTFail("\(error)")
        }
        do{
            let result : [UInt] = try testTypeArray(
                testData: "1 0 1",
                typeRule: OneOfEverythingGrammar.integer._rule())
            XCTAssertEqual(result, [1, 0, 1])
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testWordArray(){
        do{
            let result : [Int16] = try testTypeArray(
                testData: "1 0 1",
                typeRule: OneOfEverythingGrammar.integer._rule())
            XCTAssertEqual(result, [1, 0, 1])
        } catch {
            XCTFail("\(error)")
        }
        do{
            let result : [UInt16] = try testTypeArray(
                testData: "1 0 1",
                typeRule: OneOfEverythingGrammar.integer._rule())
            XCTAssertEqual(result, [1, 0, 1])
        } catch {
            XCTFail("\(error)")
        }
    }

    func testLongWordArray(){
        do{
            let result : [Int32] = try testTypeArray(
                testData: "1 0 1",
                typeRule: OneOfEverythingGrammar.integer._rule())
            XCTAssertEqual(result, [1, 0, 1])
        } catch {
            XCTFail("\(error)")
        }
        do{
            let result : [UInt32] = try testTypeArray(
                testData: "1 0 1",
                typeRule: OneOfEverythingGrammar.integer._rule())
            XCTAssertEqual(result, [1, 0, 1])
        } catch {
            XCTFail("\(error)")
        }
    }

    func testLongLongWordArray(){
        do{
            let result : [Int64] = try testTypeArray(
                testData: "1 0 1",
                typeRule: OneOfEverythingGrammar.integer._rule())
            XCTAssertEqual(result, [1, 0, 1])
        } catch {
            XCTFail("\(error)")
        }
        do{
            let result : [UInt64] = try testTypeArray(
                testData: "1 0 1",
                typeRule: OneOfEverythingGrammar.integer._rule())
            XCTAssertEqual(result, [1, 0, 1])
        } catch {
            XCTFail("\(error)")
        }
    }

    func testOneOfEverything() {
        let oneOfEverythingReference = OneOfEverything(boolean: true, integer: 1, byte: 2, word: 3, longWord: 4, longLongWord: 5, unsignedInteger: 6, unsignedByte: 7, unsignedWord: 8, unsignedLongWord: 9, unsignedLongLongWord: 10, float: 11.0, double: 12.0, string: "string", possiblyNil: nil)
        let oneOfEverythingExample = """
        true 1 2 3 4 5 6 7 8 9 10 11.0 12.0 string
        """

        do {
            var decoded = try OneOfEverything.decode(oneOfEverythingExample, using: OneOfEverythingGrammar.generatedLanguage)
            XCTAssertEqual(decoded, oneOfEverythingReference)
            
            decoded = try OneOfEverything.decode(oneOfEverythingExample, with: HomogenousTree.self, using: OneOfEverythingGrammar.generatedLanguage)
            XCTAssertEqual(decoded, oneOfEverythingReference)
            
            decoded = try ParsingDecoder().decode(OneOfEverything.self, from: oneOfEverythingExample, using: OneOfEverythingGrammar.generatedLanguage)
            XCTAssertEqual(decoded, oneOfEverythingReference)

            decoded = try ParsingDecoder().decode(OneOfEverything.self, using: AbstractSyntaxTreeConstructor().build(oneOfEverythingExample, using: OneOfEverythingGrammar.generatedLanguage))
            XCTAssertEqual(decoded, oneOfEverythingReference)

            
        } catch {
            XCTFail("\(error)")
        }
        
    }
    
    func testOneOfEverythingCached() {
        let oneOfEverythingReference = OneOfEverything(boolean: true, integer: 1, byte: 2, word: 3, longWord: 4, longLongWord: 5, unsignedInteger: 6, unsignedByte: 7, unsignedWord: 8, unsignedLongWord: 9, unsignedLongLongWord: 10, float: 11.0, double: 12.0, string: "string", possiblyNil: nil)
        let oneOfEverythingExample = """
        true 1 2 3 4 5 6 7 8 9 10 11.0 12.0 string
        """
        
        do {
            let astConstructor = AbstractSyntaxTreeConstructor()
            astConstructor.initializeCache(depth: 3, breadth: 3)
            
            let decoded = try ParsingDecoder().decode(OneOfEverything.self, using: astConstructor.build(oneOfEverythingExample, using: OneOfEverythingGrammar.generatedLanguage))
            XCTAssertEqual(decoded, oneOfEverythingReference)
            
            
        } catch {
            XCTFail("\(error)")
        }
        
    }

}
