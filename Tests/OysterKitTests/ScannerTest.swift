//
//  ScannerTest.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import XCTest
import OysterKit

class ScannerTest: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testScanCharactersFrom(){
        var source = "Hello"
        var scanner = StringScanner(source)
        XCTAssert(scanner.scan(charactersFrom:CharacterSet.letters))
        
        
        source = "1234"
        scanner = StringScanner(source)
        XCTAssert(!scanner.scan(charactersFrom:CharacterSet.letters))
        XCTAssert(scanner.scanLocation == source.unicodeScalars.startIndex)
        
        source = "He234"
        scanner = StringScanner(source)
        XCTAssert(scanner.scan(charactersFrom:CharacterSet.letters))
    
        source = ""
        scanner = StringScanner(source)
        XCTAssert(!scanner.scan(charactersFrom:CharacterSet.letters))
    }
    
    func testScanNext(){
        var source = "Hello"
        var scanner = StringScanner(source)
        
        var nextScalar = scanner.scanNext()
        guard nextScalar != nil else {
            XCTFail("Expected to get a scalar")
            return
        }
        var nextString = "\(nextScalar!)"
        
        XCTAssert("H" == nextString)
        
        source = "    Hello"
        scanner = StringScanner(source)
        nextScalar = scanner.scanNext()
        guard nextScalar != nil else {
            XCTFail("Expected to get a scalar")
            return
        }
        nextString = "\(nextScalar!)"
        XCTAssert(" " == nextString)
        
        source = ""
        scanner = StringScanner(source)
        XCTAssert(scanner.scanNext() == nil)
    }
    
    func testIsAtEnd() {
        let source = "Hello world"
        
        let scanner = StringScanner(source)
        
        XCTAssert(!scanner.isAtEnd)
        
        scanner.scanLocation = source.unicodeScalars.endIndex
        
        XCTAssert(scanner.isAtEnd)
    }
    
    func testScanUpToCharactersFrom(){
        var source = "Hello"
        var scanner = StringScanner(source)
        
        XCTAssert(scanner.scanUpTo(characterFrom:CharacterSet.letters))
        XCTAssert("\(scanner.scanNext()!)" == "H")
        
        source = "1234H"
        scanner = StringScanner(source)
        XCTAssert(scanner.scanUpTo(characterFrom:CharacterSet.letters))
        XCTAssert("\(scanner.scanNext()!)" == "H")
        
        source = "1234"
        scanner = StringScanner(source)
        XCTAssert(!scanner.scanUpTo(characterFrom:CharacterSet.letters))
    }
    
    func testScanUpToString(){
        var source = "Hello"
        var scanner = StringScanner(source)
        
        XCTAssert(scanner.scanUpTo(string:"Hello"))
        XCTAssert("\(scanner.scanNext()!)" == "H")
        
        source = "1234Hello1234"
        scanner = StringScanner(source)
        XCTAssert(scanner.scanUpTo(string:"Hello"))
        XCTAssert("\(scanner.scanNext()!)" == "H")

        source = "1234Hell"
        scanner = StringScanner(source)

        XCTAssert(!scanner.scanUpTo(string:"Hello"))
        XCTAssert(scanner.scanLocation == source.unicodeScalars.startIndex)

        source = ""
        scanner = StringScanner(source)
        XCTAssert(!scanner.scanUpTo(string:"Hello"))
        XCTAssert(scanner.scanLocation == source.unicodeScalars.startIndex)
    }
    
    func testScanString(){
        var source = "Hello"
        var scanner = StringScanner(source)
        
        XCTAssert(scanner.scan(string:"Hello"))
        XCTAssert(scanner.isAtEnd)
        
        source = "1234Hello1234"
        scanner = StringScanner(source)
        XCTAssert(!scanner.scan(string:"Hello"))
        XCTAssert(scanner.scanLocation == source.unicodeScalars.startIndex)
        
        source = "Hell"
        scanner = StringScanner(source)
        XCTAssert(!scanner.scan(string:"Hello"))
        XCTAssert(scanner.scanLocation == source.unicodeScalars.startIndex)        
    }

}
