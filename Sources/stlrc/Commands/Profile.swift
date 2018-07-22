//
//  Profile.swift
//  stlrc
//
//  Created on 10/07/2018.
//

import Foundation
import OysterKit

#if canImport(NaturalLanguage)
@available(OSX 10.14, *)
class ProfileCommand : Command, IndexableOptioned, GrammarConsumer {
    typealias OptionIndexType       = Options
    
    /**
     How options are indexed
     */
    public enum Options : String, OptionIndex {
        case grammar
        
        var option : Option {
            switch self {
            case .grammar:  return GrammarOption()
            }
        }
        
        static var all : [Option] {
            return [
                grammar.option,
            ]
        }
    }
    
    public enum ProfileError : Error {
        case missingGrammarFile
        case couldNotParseProfiledGrammar
    }
    
    init(){
        super.init("profile", description: "Enables signposts and parses the supplied grammar", options: Options.all, parameters: [])
    }
    
    
    override func run() -> RunnableReturnValue {
        guard let grammarFileName = grammarFileName else {
            return RunnableReturnValue.failure(error: ProfileError.missingGrammarFile, code: 0)
        }
        
        print("Profiling \(grammarFileName.style(.italic))")
        Log.parsing.enable()

        if let _ = grammar {
            print("Done")
            return RunnableReturnValue.success
        } else {
            print("Parsing failed")
            return RunnableReturnValue.failure(error: ProfileError.couldNotParseProfiledGrammar, code: 10)
        }
        
    }
}
#endif
