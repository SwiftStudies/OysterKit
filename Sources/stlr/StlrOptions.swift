//
//  StlrOptions.swift
//  OysterKitPackageDescription
//
//  Created by Swift Studies on 08/12/2017.
//

import CommandKit
import OysterKit


class STLROption : Option {
    public init(_ name: String, verbose: String, description:String,required:Bool = false, requiredParameters: RequiredParameters = RequiredParameters()) {
        super.init(name, verbose: verbose, description: description, required: required, requiredParameters: requiredParameters)
        
        apply = { [unowned self] (command,parameters) in
            guard let stlrCommand = command as? STLRCommand else {
                fatalError("Expected command to be a STLRCommand")
            }
            
            self.command = stlrCommand
            try self.apply(parameters: parameters)
        }
    }
    
    var command : STLRCommand?
    
    open func apply(parameters:[Any]) throws{
        
    }
}

class STLRCommand : Command {
    let name        : String
    let description : String
    
    var requiredParameters = RequiredParameters()
    
    var customOptions: [Option] = []
    
    var parameters: [Any] = []
    
    var run         : RunBlock = {_ in -1}
    
    var grammarFile : String?
    var grammar     : STLRParser?
    
    init(name:String, description:String, options : [Option] = [], parameters: RequiredParameters = []){
        self.name = name
        self.description = description
        
        customOptions.append(GrammarOption())
        customOptions.append(contentsOf: options)
        requiredParameters.append(contentsOf: parameters)
        self.run = {[unowned self] arguments in
            
            
            self.execute(arguments: arguments)
        }
    }
    
    open func execute(arguments:Arguments)->Int{
        return -1
    }
}

class GrammarOption : STLROption {
    
    init(){
        super.init("g", verbose: "grammar", description: "The grammar to use", required: true, requiredParameters: [
            ({$0},.one)
            ])
    }
    
    override func apply(parameters: [Any]) throws {
        guard let grammarFile = parameters.first as? String else {
            throw Tool.ArgumentError.commandNotFound(for: "This isn't a command not found message, it's because the parameter wasn't there or wasn't a string")
        }
        
        let stlrGrammar = try String(contentsOfFile: grammarFile, encoding: String.Encoding.utf8)
        
        command?.grammarFile = grammarFile
        command?.grammar     = STLRParser(source: stlrGrammar)
        
        // Pull off the top parameter and consume it as long as it's a parameter
        print("I'll use \(parameters[0]) as the grammar")

    }
}
