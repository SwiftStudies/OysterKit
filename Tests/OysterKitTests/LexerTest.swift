//
//  LexerTest.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import XCTest
@testable import OysterKit

class LexerTest: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testNestedScanSkipAtStart(){
        let source = "1234"
        let lexer = Lexer(source: source)
        
        do{
            lexer.mark(skipping: false)
            
            //Scan{Skip}
            lexer.mark(skipping: false)
            lexer.mark(skipping: true)
            try lexer.scanNext()
            _ = lexer.proceed()
            _ = lexer.proceed()

            //Do some scanning
            try lexer.scanNext()
            try lexer.scanNext()

            //Skip
            lexer.mark(skipping: true)
            try lexer.scanNext()
            _ = lexer.proceed()
            
            let match = lexer.proceed()
            XCTAssertEqual("23", match.matchedString)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    
    func testNestedScanSkipAtEnd(){
        let source = "1234"
        let lexer = Lexer(source: source)

        do{
            lexer.mark(skipping: false)
            
            //Skip
            lexer.mark(skipping: true)
                try lexer.scanNext()
            _ = lexer.proceed()
            
            //Do some scanning
            try lexer.scanNext()
            try lexer.scanNext()

            //Scan{Skip}
            lexer.mark(skipping: false)
                lexer.mark(skipping: true)
                    try lexer.scanNext()
                _ = lexer.proceed()
            _ = lexer.proceed()
            
            let match = lexer.proceed()
            XCTAssertEqual("23", match.matchedString)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testSkipAtStart(){
        let source = "1234"
        let lexer = Lexer(source: source)
        
        do{
            lexer.mark(skipping: false)
            lexer.mark(skipping: true)
            try lexer.scanNext()
            try lexer.scanNext()
            let skippedContext = lexer.proceed()
            XCTAssertEqual("", skippedContext.matchedString)
            try lexer.scanNext()
            try lexer.scanNext()
            let scannedContext = lexer.proceed()
            XCTAssertEqual("34", scannedContext.matchedString)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testSkipAtEnd(){
        let source = "1234"
        let lexer = Lexer(source: source)
        
        do{
            lexer.mark(skipping: false)
            try lexer.scanNext()
            try lexer.scanNext()
            lexer.mark(skipping: true)
            try lexer.scanNext()
            try lexer.scanNext()
            let skippedContext = lexer.proceed()
            XCTAssertEqual("", skippedContext.matchedString)
            let scannedContext = lexer.proceed()
            XCTAssertEqual("12", scannedContext.matchedString)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSkipAtStartAndEnd(){
        let source = "12345"
        let lexer = Lexer(source: source)
        
        do{
            lexer.mark(skipping: false)
            lexer.mark(skipping: true)
            try lexer.scanNext() //Skipping
            try lexer.scanNext() //Skipping
            var skippedContext = lexer.proceed()
            XCTAssertEqual(skippedContext.matchedString, "")
            try lexer.scanNext() //Scanning
            lexer.mark(skipping: true)
            try lexer.scanNext() //Skipping
            try lexer.scanNext() //Skipping
            skippedContext = lexer.proceed()
            XCTAssertEqual(skippedContext.matchedString, "")
            let scannedContext = lexer.proceed()
            XCTAssertEqual(scannedContext.matchedString,"3")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testScanScanSkipScanSkipAtStartAndEnd(){
        let source = "12345"
        let lexer = Lexer(source: source)
        
        do {
            lexer.mark(skipping: false)
            lexer.mark(skipping: false)

            lexer.mark(skipping: true)
            lexer.mark(skipping: false)
            try lexer.scanNext()
            _ = lexer.proceed()
            _ = lexer.proceed()
            lexer.mark(skipping: false)
            try lexer.scanNext()
            try lexer.scanNext()
            try lexer.scanNext()
            _ = lexer.proceed()
            lexer.mark(skipping: true)
            lexer.mark(skipping: false)
            try lexer.scanNext()
            _ = lexer.proceed()
            _ = lexer.proceed()

            _ = lexer.proceed()
            let all = lexer.proceed()
            
            XCTAssertEqual(all.matchedString, "234")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    
    func testScanScanSkipScanAtStartAndEnd(){
        let source = "12345"
        let lexer = Lexer(source: source)
        
        do {
            lexer.mark(skipping: false)
            lexer.mark(skipping: false)
            lexer.mark(skipping: true)
            lexer.mark(skipping: false)
            try lexer.scanNext()
            _ = lexer.proceed()
            _ = lexer.proceed()
            try lexer.scanNext()
            try lexer.scanNext()
            try lexer.scanNext()
            lexer.mark(skipping: true)
            lexer.mark(skipping: false)
            try lexer.scanNext()
            _ = lexer.proceed()
            _ = lexer.proceed()
            _ = lexer.proceed()
            _ = lexer.proceed()
            let all = lexer.proceed()
            
            XCTAssertEqual(all.matchedString, "234")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSkipInMiddle(){
        let source = "12345"
        let lexer = Lexer(source: source)
        
        do{
            lexer.mark(skipping: false)
            try lexer.scanNext() //Scanning
            try lexer.scanNext() //Scanning
            lexer.mark(skipping: true)
            try lexer.scanNext() //Skipping
            let skippedContext = lexer.proceed()
            XCTAssertEqual(skippedContext.matchedString, "")
            try lexer.scanNext() //Scanning
            try lexer.scanNext() //Scanning
            let scannedContext = lexer.proceed()
            //If you skip in the middle... tough
            XCTAssertEqual(scannedContext.matchedString,"12345")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testNestedSkip(){
        let source = "12345"
        let lexer = Lexer(source: source)
        
        do{
            lexer.mark(skipping: false)
            lexer.mark(skipping: true)
            try lexer.scanNext() //Skipping
            lexer.mark(skipping:false)
            try lexer.scanNext() //Nested skipping
            _ = lexer.proceed()  //Behaviour can be undefined at this point (will depend on lexer implementation)
            var skippedContext = lexer.proceed()
            XCTAssertEqual(skippedContext.matchedString, "")
            try lexer.scanNext() //Scanning
            lexer.mark(skipping: true)
            lexer.mark(skipping: false)
            try lexer.scanNext() //Nested skipping
            _ = lexer.proceed()
            try lexer.scanNext() //Skipping
            skippedContext = lexer.proceed()
            XCTAssertEqual(skippedContext.matchedString, "")
            let scannedContext = lexer.proceed()
            XCTAssertEqual(scannedContext.matchedString, "3")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testInitialMark(){
        let source = "Hello"
        let lexer = TestLexer(source: source)
        
        XCTAssert(lexer.markedLocation == source.unicodeScalars.startIndex)
    }
    
    func testNegativeMarkTestingFunctions(){
        let source = "Hello"
        let lexer = TestLexer(source: source)
        lexer.rewind()

        XCTAssert(lexer.markedLocation == source.unicodeScalars.startIndex)
    }
    
    func testMark(){
        let source = "Hello"
        let lexer = TestLexer(source: source)
        
        do{
            let _ = lexer.mark()
            XCTAssert(lexer.markedLocation == source.unicodeScalars.startIndex)
            try lexer.scan(oneOf: CharacterSet.letters)
            try lexer.scan(oneOf: CharacterSet.letters)
            let _ = lexer.mark()
            XCTAssert(lexer.markedLocation == source.unicodeScalars.index(source.unicodeScalars.startIndex, offsetBy: 2))
        } catch {
            XCTFail("Test shouldn't throw")
        }
    }
    
    func testDiscard(){
        let source = "Hello"
        let lexer = TestLexer(source: source)
        
        do{
            let _ = lexer.mark()                                                        //Marked at 0
            XCTAssert(lexer.markedLocation == source.unicodeScalars.startIndex)
            try lexer.scan(oneOf: CharacterSet.letters)
            let _ = lexer.mark()                                                        //Marked at 1
            try lexer.scan(oneOf: CharacterSet.letters)
            let _ = lexer.mark()                                                        //Marked at 2
            try lexer.scan(oneOf: CharacterSet.letters)
            lexer.rewind()                                                     //Marked at 1
            XCTAssert(lexer.markedLocation == source.unicodeScalars.index(source.unicodeScalars.startIndex, offsetBy: 1))
            lexer.rewind()                                                     //Marked at 0
            XCTAssert(lexer.markedLocation == source.unicodeScalars.index(source.unicodeScalars.startIndex, offsetBy: 0))
        } catch {
            XCTFail("Test shouldn't throw")
        }
    }

    func markAndScan(with lexer:TestLexer, _ characterSet : CharacterSet) {
        let _ = lexer.mark()
        var passed = true
        while passed {
            do{
                try lexer.scan(oneOf:characterSet)
                passed = true
            } catch {
                return
            }
            
        }
    }
    
    
    func testProceed(){
        let source = "Hello world"
        let lexer = TestLexer(source: source)
        
        markAndScan(with: lexer,CharacterSet.letters)
                
        let context = lexer.proceed()
            
        XCTAssert(context.matchedString == "Hello", "Expected 'Hello' but got '\(context.matchedString)'")
    }

    func testIssueChildCoalesce(){
        let source = "Goodbye cruel world."
        let lexer = TestLexer(source: source)
        
        let _ = lexer.mark()                                                            //Start of sentence
        
        markAndScan(with: lexer,CharacterSet.letters)                           //Word in sentence
        let goodbye = lexer.proceed()
        markAndScan(with: lexer, CharacterSet.whitespaces)                      //White space
        let _ = lexer.proceed()
        markAndScan(with: lexer,CharacterSet.letters)                           //Word in sentence
        let cruel = lexer.proceed()
        markAndScan(with: lexer, CharacterSet.whitespaces)                      //White space
        let _ = lexer.proceed()
        markAndScan(with: lexer,CharacterSet.letters)                           //Word in sentence
        let world = lexer.proceed()
        markAndScan(with: lexer,CharacterSet(charactersIn: "."))                //Period
        let period = lexer.proceed()
        
        //Check that each token is correct
        XCTAssert(goodbye.matchedString == "Goodbye", "Expected 'Goodbye' but got '\(goodbye.matchedString)'")
        XCTAssert(cruel.matchedString == "cruel", "Expected 'cruel' but got '\(cruel.matchedString)'")
        XCTAssert(world.matchedString == "world", "Expected 'world' but got '\(world.matchedString)'")
        XCTAssert(period.matchedString == ".", "Expected 'period' but got '\(period.matchedString)'")
    }
    
    func testRegularExpression(){
        let source = "Cat,Dog"
        let lexer = Lexer(source: source)
        
        let catRegex = try! NSRegularExpression(pattern: "Cat", options: [])
        
        do {
            try lexer.scan(regularExpression: catRegex)
        } catch {
            XCTAssert(false,"Regular expression should have matched")
            return
        }
        
        do {
            try lexer.scan(regularExpression: catRegex)
            XCTAssert(false,"Regular expression should have failed to match")
            return
        } catch {
            return
        }

    }
    
    func testNegativeScanCharacterInSet() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let source = "Hello"
        let lexer = TestLexer(source: source)
        
        do {
            try lexer.scan(oneOf: CharacterSet.lowercaseLetters)
            XCTFail("Scan should have thrown")
        } catch {
            XCTAssert(!lexer.endOfInput)
        }
        
    }
    
    
    func testNegativeScanString() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let source = "Hello"
        let lexer = TestLexer(source: source)
        
        do {
            try lexer.scan(terminal: "Hullo")

            XCTFail("Scan should have thrown")
        } catch {
            XCTAssert(!lexer.endOfInput)
        }
        
    }
    
    
    func testScanString() {
        let source = "Hello"
        let lexer = TestLexer(source: source)
        
        XCTAssert(!lexer.endOfInput)
        
        do {
            try lexer.scan(terminal: "Hello")
            let context = lexer.proceed()
            
            XCTAssert(source == context.matchedString, "Expected token to be \(source) but got \(context.matchedString)")
        } catch {
            XCTFail("Scan should not have thrown")
        }
        
        XCTAssert(lexer.endOfInput)
    }

    func testScanOneOfCharacterSet() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let source = "Hello"
        let lexer = TestLexer(source: source)
        
        XCTAssert(!lexer.endOfInput)
        
        var expected : Character
        
        do {
            for current in source {
                expected = current
                try lexer.scan(oneOf: CharacterSet.letters)
            }
            let context = lexer.proceed()
            
            XCTAssert(source == context.matchedString, "Expected token to be \(source) but got \(context.matchedString)")
        } catch {
            XCTFail("All characters are letters: \(expected)")
        }
        
        XCTAssert(lexer.endOfInput)
    }
    

}
