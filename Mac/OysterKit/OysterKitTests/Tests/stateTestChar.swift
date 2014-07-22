//
//  stateTestChar.swift
//  OysterKit Mac
//
//  Created by Nigel Hughes on 03/07/2014.
//  Copyright (c) 2014 RED When Excited Limited. All rights reserved.
//

import XCTest
import OysterKit

class stateTestChar: XCTestCase {
    var tokenizer = Tokenizer()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        tokenizer = Tokenizer()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testChar(){
        
        
        tokenizer.branch(
            char("xyz1").token("character"),
            OKStandard.eot
        )
                
        XCTAssert(tokenizer.tokenize("x1z") == [token("character",chars: "x"), token("character",chars: "1"),token("character",chars: "z"),])
    }
    
    


}
