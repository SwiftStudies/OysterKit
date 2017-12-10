//
//  STLR Decoder.swift
//  OysterKit
//
// Createed with heavy reference to: https://github.com/apple/swift-corelibs-foundation/blob/master/Foundation/JSONEncoder.swift#L802
//
//  Copyright © 2017 RED When Excited. All rights reserved.
//

import Foundation
import OysterKit
import CommandKit

class ParseCommand : STLRCommand {
    init(){
        super.init(name: "parse", description: "Parses a set of input files using the supplied grammar", options: [], parameters: [])
    }
    
    override func execute(arguments: Arguments) -> Int {
        print("Parsed y'all")
        return 0
    }
}

class GenerateCommand : STLRCommand {
    init(){
        super.init(name: "generate", description: "Creates source code in the specified format for the supplied grammar", options: [
            LanguageOption()
            ], parameters: [])
    }
    
    var language : LanguageOption.Language = .swift
    
    override func execute(arguments: Arguments) -> Int {
        guard let generatedGrammarName = grammarName, let parserOutput = grammar else {
            fatalError("Grammar has no name".color(.red))
        }
        print("Generating \(generatedGrammarName) as \(language)")
        
        do {
            try language.generate(grammarName: generatedGrammarName, from: parserOutput)
        } catch {
            print("\(error)".color(.red))
        }
        
        print("Done".color(.green))
        
        return 0
    }
}

let stlr = Tool(defaultCommand: ParseCommand(), version: "1.0.0")

stlr.commands.append(GenerateCommand())

exit(Int32(stlr.execute()))

