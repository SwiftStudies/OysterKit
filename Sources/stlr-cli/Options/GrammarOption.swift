//
//  GrammarOption.swift
//  stlr
//
//  Created on 14/01/2018.
//

import Foundation
import STLR

protocol GrammarConsumer {
}

extension GrammarConsumer where Self : Optioned{
    
    private var grammarOption : GrammarOption? {
        return self[optionCalled:"grammar"]
    }
    
    var grammarUrl : URL? {
        return grammarOption?[parameter: GrammarOption.Parameters.inputGrammarFile]
    }
    
    var grammarFileName : String? {
        return grammarUrl?.lastPathComponent
    }
    
    var grammarName : String? {
        return grammarUrl?.deletingPathExtension().lastPathComponent
    }

    var grammar : STLRParser? {
        return grammarOption?.grammar
    }

}

class GrammarOption : Option, IndexableParameterized{
    
    typealias ParameterIndexType = Parameters
    
    enum Parameters : Int, ParameterIndex {
        case inputGrammarFile
        
        var parameter: Parameter {
            switch self {
            case .inputGrammarFile:
                return StandardParameterType.fileUrl.one(optional: false)
            }
        }
        
        static var all: [Parameter] = [Parameters.inputGrammarFile.parameter]
        
    }
    
    enum Errors : Error {
        case couldNotParseGrammar
    }
    
    init(){
        super.init(shortForm: "g", longForm: "grammar", description: "The grammar to use", parameterDefinition: Parameters.all, required: true)
    }
    
    lazy var grammar : STLRParser? = {
        guard let grammarUrl : URL = self[parameter: GrammarOption.Parameters.inputGrammarFile] else {
            return nil
        }
        
        let stlrGrammar : String
        
        do {
            stlrGrammar = try String(contentsOfFile: grammarUrl.path, encoding: String.Encoding.utf8)
        } catch {
            return nil
        }
        return STLRParser(source: stlrGrammar)
    }()
    
}
