//
//  Infrastructure.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation
@testable import OysterKit
import STLR

class TestParser : TokenStream{
    init(source: String, grammar: [Rule]) {
        super.init(source, using: TestLanguage(grammar: grammar))
    }
    
    required init(from source: String, with language: Grammar) {
        super.init(source, using: language)
    }
}

class TestableStream : TokenStream{
    init(source: String, _ rules: [Rule]) {
        super.init(source, using: TestLanguage(grammar: rules))
    }
}

class TestLanguage : Grammar{
    
    let rules : [Rule]
    
    init(){
        rules = []
    }
    
    init(grammar:[Rule]){
        self.rules = grammar
    }
    
    func createLexer(for source:String)->LexicalAnalyzer{
        fatalError("This shouldn't happen, it's just a mock up")
    }
    
    func createIR<IR : IntermediateRepresentation>(source: String) -> IR {
        fatalError("This shouldn't happen, it's just a mock up")
    }
}

extension Array {
    subscript(rangeChecked index:Int)->Element?{
        guard (startIndex..<endIndex).contains(index) else {
            return nil
        }
        
        return self[index]
    }
}

