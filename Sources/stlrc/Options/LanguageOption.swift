//
//  StlrOptions.swift
//  OysterKitPackageDescription
//
//  Created by Swift Studies on 08/12/2017.
//

import Foundation
import OysterKit
import STLR

class LanguageOption : Option, IndexableParameterized {
    typealias ParameterIndexType    = Parameters
    
    /**
     Parameters
     */
    public enum Parameters : Int, ParameterIndex {
        case language = 0
        
        public var parameter: Parameter{
            switch self {
            case .language:
                return Language().one(optional: false)
            }
        }
        
        public static var all: [Parameter]{
            return [
                Parameters.language.parameter
            ]
        }
    }
    
    public struct Language : ParameterType{
        enum Supported : String{
            case swift
            case swiftIR
            case swiftPM

            var fileExtension : String? {
                switch self {
                case .swift:
                    return rawValue
                default:
                    return nil
                }
            }
            
            func operations(in scope:_STLR, for grammarName:String) throws ->[STLR.Operation]? {
                switch self {
                case .swift:
                    return nil
                case .swiftIR:
                    return try SwiftStructure.generate(for: scope, grammar: grammarName, accessLevel: "public")
                case .swiftPM:
                    return try SwiftPackageManager.generate(for: scope, grammar: grammarName, accessLevel: "public")
                }
            }
            
            
            func generate(grammarName: String, from stlr:_STLR, optimize:Bool, outputTo:String) throws {
                if optimize {
                    _STLR.register(optimizer: InlineIdentifierOptimization())
                    _STLR.register(optimizer: CharacterSetOnlyChoiceOptimizer())
                } else {
                    _STLR.removeAllOptimizations()
                }
                
                stlr.grammar.optimize()
                
                /// Use operation based generators
                if let operations = try operations(in: stlr, for: grammarName) {
                    let workingDirectory = URL(fileURLWithPath: outputTo).deletingLastPathComponent().path
                    let context = OperationContext(with: URL(fileURLWithPath: workingDirectory)){
                        print($0)
                    }
                    do {
                        try operations.perform(in: context)
                    } catch OperationError.error(let message){
                        print(message.color(.red))
                        exit(EXIT_FAILURE)
                    } catch {
                        print(error.localizedDescription.color(.red))
                        exit(EXIT_FAILURE)
                    }
                } else {
                    switch self {
                    case .swift:
                        let file = TextFile(grammarName+".swift")
                        stlr.swift(in: file)
                        let workingDirectory = URL(fileURLWithPath: outputTo).deletingLastPathComponent().path
                        let context = OperationContext(with: URL(fileURLWithPath: workingDirectory)) { (message) in
                            print(message)
                        }
                        
                        try file.perform(in: context)
                    default:
                        throw OperationError.error(message: "Language did not produce operations")
                    }
                }
                
                
             }
            
        }
        
        public var name = "Language"
        
        public func transform(_ argumentValue: String) -> Any? {
            return Supported(rawValue: argumentValue)
        }
    }
    
    init(){
        super.init(shortForm: "l", longForm: "language", description: "The language to generate", parameterDefinition: Parameters.all, required: false)
    }

}



