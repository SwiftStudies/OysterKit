//
//  Application.swift
//  OysterKitPackageDescription
//
//  Created by Nigel Hughes on 08/12/2017.
//

import Foundation

class CommandLineApplication {
    let optionSpecification : [CommandLineOption]
    
    init(withOptions options:[CommandLineOption]){
        optionSpecification = options
    }

    var executableName : String {
        let fullPath : NSString = CommandLine.arguments[0] as NSString
        
        return fullPath.lastPathComponent
    }
    
    var help : String {
        var result = "\(executableName) "
        for option in optionSpecification {
            result += "\(option.defaultValue == nil ? "" : "[")\( option.flagDescription)\(option.defaultValue == nil ? "" : "]") "
        }
        
        return result
    }
    
    func parseOptions() throws ->Options{
        let options = Options()
        
        options.options = optionSpecification
        
        let arguments = CommandLine.arguments
        var argumentIndex = 1
        
        while argumentIndex < arguments.count {
            let argument = arguments[argumentIndex]
            argumentIndex += 1
            
            if let suppliedOption = try options.optionForArgument(argument: argument){
                options.set(option:suppliedOption)
                while try argumentIndex < arguments.count && options.optionForArgument(argument: arguments[argumentIndex]) == nil {
                    options.addValue(option: suppliedOption, arguments[argumentIndex])
                    argumentIndex += 1
                }
            } else {
                options.addValue(option: Parameter(), argument)
            }
        }
        
        return options
    }
}
