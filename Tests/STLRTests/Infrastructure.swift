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



class TestParser : StreamRepresentation<HomogenousNode, Lexer>{
    init(source: String, grammar: [Rule]) {
        super.init(source: source, language: TestLanguage(grammar: grammar))
    }
    
    required init(from source: String, with language: Language) {
        super.init(source: source, language: language)
    }
}

class TestableStream<N:Node> : StreamRepresentation<N,Lexer>{
    init(source: String, _ rules: [Rule]) {
        super.init(source: source, language: TestLanguage(grammar:rules))
    }
}

class TestLanguage : Language{
    
    let grammar : [Rule]
    
    init(){
        grammar = []
    }
    
    init(grammar:[Rule]){
        self.grammar = grammar
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

