//
//  StlrOptions.swift
//  OysterKitPackageDescription
//
//  Created by Swift Studies on 08/12/2017.
//

import Foundation

public enum StlrOptions : String, Equatable, CommandLineOption{
    private static let settings : [StlrOptions : (shortFlag: String?, defaultValue:String?, helpMessage:String)] = [
        .operation : ("\(StlrOptions.operation.rawValue.first!)",Operation.defaultValue,"By default stlr will generate swift implementations of the supplied grammar. However you may override this behaviour and apply a dynamically created implementation of the grammer to the specified input files"),
        .language : ("\(StlrOptions.language.rawValue.first!)",Language.defaultValue,"Specifiy the output language for source code generations"),
        .grammar : ("\(StlrOptions.grammar.rawValue.first!)",nil,"Specify the .stlr grammar file to be used"),
        ]
    
    case operation
    case language
    case grammar
    
    public static var allValues : [StlrOptions] {
        return [
            .operation,
            .language,
            .grammar
        ]
    }
    
    public var shortFlag: String?{
        return StlrOptions.settings[self]?.shortFlag
    }
    
    public var longFlag: String?{
        return self.rawValue
    }
    
    public var defaultValue: String?{
        return StlrOptions.settings[self]?.defaultValue
    }
    
    public var helpMessage: String{
        return StlrOptions.settings[self]?.helpMessage ?? "No help available for \(rawValue)"
    }
    
    
    public enum Operation : String, OptionValue{
        case dynamic
        case generate
        
        static var defaultValue : String? {
            return Operation.generate.rawValue
        }
    }
    
    public enum Language : String, OptionValue {
        case swift
        
        static var defaultValue : String? {
            return Language.swift.rawValue
        }
    }
}


