//
//  DSLTest.swift
//  OysterKitTests
//
//  Created by Nigel Hughes on 12/08/2019.
//

import XCTest
import OysterKit

class DSLTest: XCTestCase {

    func testStringTerminal() {
        enum Tokens : Int, TokenType {
            case hello
        }
        
        let singleTerminalString = grammar {
            "hello".parse(as: Tokens.hello)
        }
        
        guard let token = singleTerminalString.tokenize("hello").makeIterator().next() else {
            XCTFail("No tokens in stream")
            return
        }
        
        XCTAssertEqual(token.token.rawValue, Tokens.hello.rawValue)
    }

    func testSequence() {
        enum Tokens : Int, TokenType {
            case greeting
        }
        
        let language = grammar {
            sequence {
                "Hello"
                ","
                CharacterSet.whitespaces
                "World"
            }.parse(as: Tokens.greeting)
        }
        
        guard let token = language.tokenize("Hello, World").makeIterator().next() else {
            XCTFail("No tokens in stream")
            return
        }
        
        XCTAssertEqual(token.token.rawValue, Tokens.greeting.rawValue)
    }
    
    func testChoice() {
        enum Tokens : Int, TokenType {
            case greeting
        }
        
        let language = grammar {
            oneOf {
                "Hello"
                "Hi"
            }.parse(as: Tokens.greeting)
        }
        
        if let casualGreeting = language.tokenize("Hi").makeIterator().next() {
            XCTAssertEqual(casualGreeting.token.rawValue, Tokens.greeting.rawValue)
        } else {
            XCTFail("Casual greeting not recognised")
        }

        if let formalGreeting = language.tokenize("Hello").makeIterator().next() {
            XCTAssertEqual(formalGreeting.token.rawValue, Tokens.greeting.rawValue)
        } else {
            XCTFail("Formal not recognised")
        }

    }

    
}
