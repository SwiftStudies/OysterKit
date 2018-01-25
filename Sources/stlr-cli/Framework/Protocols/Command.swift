//
//  Command.swift
//  CommandKit
//
//  Created by Sean Alling on 11/8/17.
//

import Foundation

open class Command : Optioned, Runnable, Parameterized{
    
    final let name : String
    final let description : String
    final public private(set) var options : [Option]
    
    
    final public private(set) var parameters : [Parameter]

    public init(_ name:String, description:String, options: [Option] = [], parameters : [Parameter] = []){
        self.name = name
        self.description = description
        self.parameters = parameters
        self.options = options
        self.options.append(HelpOption(forCommand: self))
    }
    
    private final subscript(optionCalled longForm:String)->Option?{
        for option in options {
            if option.longForm == longForm {
                return option
            }
            if let shortForm = option.shortForm, shortForm == longForm {
                return option
            }
        }
        return nil
    }
    
    final public func execute(withArguments arguments:Arguments) throws ->Int{
        
        //While we still have options to process
        while let nextArgument = arguments.top, nextArgument.type == .option {
            guard let option = self[optionCalled: nextArgument.value] else {
                throw Argument.ParsingError.optionNotFound
            }
            
            arguments.consume()
            
            try option.parse(arguments: arguments)
            
            option.isSet = true
            
            if let error = (option as? Runnable)?.run().error {
                throw error
            }
        }
        
        //Make sure we have all required options
        for option in options where option.required == true{
            if !option.isSet {
                throw Argument.ParsingError.requiredOptionNotFound(optionName: option.longForm)
            }
        }
        
        //Now if we have parameters parse those from the arguments
        try parse(arguments:arguments)
        
        switch run() {
        case .success:
            return RunnableReturnValue.success.code
        case .failure(let error, _):
            throw error
        }
    }
    
    open func run() -> RunnableReturnValue {
        return RunnableReturnValue.success
    }
    
    final class HelpOption : Option, Runnable {
        
        let command : Command
        init(forCommand command:Command){
            self.command = command
            super.init(shortForm: "h", longForm: "help", description: "Provides help, usage instructions and a list of any options for the \(command.name.style(.bold)) command.", parameterDefinition: [], required: false)
        }
        
        func run()->RunnableReturnValue{
            print(command.help)
            return RunnableReturnValue.success
        }
    }
    
    /**
     Returns a string with the auto-generated usage schema and a list of options (if present)
     */
    public var help: String {
        let numberOfTabs = options.numberOfTabs
        let lineWidth = 70
        
        return usageParagraph(maxLineWidth: lineWidth) + optionsParagraph(nOptionTabs: numberOfTabs, maxLineWidth: lineWidth)
    }
    
    /**
     Returns a string with the auto-generated usage schema
     */
    public var usage: String {
        let lineWidth = 70
        return usageParagraph(maxLineWidth: lineWidth)
    }
    
    /**
     Returns the formatted usage schema
     */
    func usageParagraph(maxLineWidth: Int) -> String {
        let title  = "Usage:".style(.underline)
        var schema = "\(Tool.executableName) \(self.name)"
        let returnIndent = 4
        
        let hasOptions = !self.options.isEmpty
        let hasParameters = !self.parameters.isEmpty
        switch (hasOptions, hasParameters) {
        case (true, true):
            schema += " OPTION | PARAMETER(s)"
        case (true, false):
            schema += " OPTION"
        case (false, true):
            schema += " PARAMETER(s)"
        case (false, false):
            break
        }
        schema = schema.color(.green)
        
        if !self.description.isEmpty {
            return title + "\n\n\t$ " + schema + "\n\n\t  " + self.description.wrap(width: (maxLineWidth - returnIndent), returnIndent: returnIndent) + "\n"
        }
        else {
            return title + "\n\n\t$ " + schema + "\n\n"
        }
    }
    
    /**
     Returns a formatted list of options
     */
    func optionsParagraph(nOptionTabs: Int, maxLineWidth: Int) -> String {
        guard !self.options.isEmpty else { return "" }
        
        let title = "Options:".style(.underline)
        let descriptionWidth = maxLineWidth - (nOptionTabs * 4)
        var optionsParagraph = title + "\n\n"
        
        for option in options {
            let optionName : String
            if let shortForm = option.shortForm {
                optionName = "-\(shortForm)|--\(option.longForm)"
            } else {
                optionName = "--\(option.longForm)"
            }
            optionsParagraph += "\t" + optionName.color(.magenta)
            
            for _ in 0..<(maxLineWidth - optionName.count) {
                optionsParagraph += " "
            }
            optionsParagraph += option.description.wrap(width: descriptionWidth, returnIndent: (maxLineWidth - descriptionWidth)) + "\n"
        }
        return optionsParagraph
    }
    
}

