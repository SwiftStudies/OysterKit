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
        super.init(name: "generate", description: "Creates source code in the specified format for the supplied grammar", options: [], parameters: [])
    }
    
    override func execute(arguments: Arguments) -> Int {
        print("Generated y'all")
        return 0
    }
}

let stlr = Tool(defaultCommand: ParseCommand(), version: "1.0.0")

stlr.commands.append(GenerateCommand())

exit(Int32(stlr.execute()))

//
//let application = CommandLineApplication(withOptions: StlrOptions.allValues)
//
//do {
//    let options = try application.parseOptions()
//
//    guard let operation : StlrOptions.Operation = options[StlrOptions.operation] else {
//        throw OptionError.invalidFormat(option: StlrOptions.operation, violation: "Supplied operation not recognized")
//    }
//
//    print(operation)
//
//    switch operation{
//    case .generate:
//        guard let language : StlrOptions.Language = options[StlrOptions.language] else {
//            throw OptionError.invalidFormat(option: StlrOptions.language, violation: "Supplied language not recognized")
//        }
//        guard let grammarFile : String = options[StlrOptions.grammar] else {
//            throw OptionError.missingRequiredOption(missing: [StlrOptions.grammar])
//        }
//        let stlrGrammar = try String(contentsOfFile: grammarFile, encoding: String.Encoding.utf8)
//        let path = grammarFile as NSString
//        let fileName = (path.pathComponents.last ?? "stlr")
//        let grammarName = String(fileName[fileName.startIndex..<(fileName.index(of: ".") ?? fileName.endIndex)])
//
//        let stlrParser = STLRParser(source: stlrGrammar)
//
//        let generatedLanguage : String?
//
//        switch language{
//        case .swift:
//            generatedLanguage = stlrParser.ast.swift(grammar: grammarName)
//        }
//
//        if let generatedLanguage = generatedLanguage {
//            try generatedLanguage.write(toFile: "\(grammarName).swift", atomically: true, encoding: String.Encoding.utf8)
//        }
//
//    case .dynamic:
//        break
//    }
//} catch (let error){
//    if let optionError = error as? OptionError {
//        switch optionError {
//        case .unknownFlag(let flag):
//            print("Unknown flag \(flag)")
//        case .missingRequiredOption(let missingRequiredOptions):
//            print("The following required options are missing:")
//            for missingOption in missingRequiredOptions{
//                print("\t• \(missingOption)")
//            }
//        case .invalidFormat(let option, let violation):
//            print("Invalid format for \(option). \(violation)")
//        }
//
//    } else {
//        print("Error: \(error)")
//    }
//    print("\nUsage:\n\t\(application.help) grammar-files...")
//}
//
