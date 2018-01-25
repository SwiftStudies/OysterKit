//
//  Argument.swift
//  CommandKit
//
//  Created by Sean Alling on 11/8/17.
//

import Foundation


/**
     An object that represents a parsed command line interface argument. Every argument is seperated by a single space.
 */
public struct Argument {
    public var value:   String
    public var type:    ParsedType
    
    /**
         Represents the kind or type of Argument
     */
    public enum ParsedType {
        case tool
        case command
        case option
        case parameter
    }
    
    /**
     An error relating to improper user input
     */
    enum ParsingError: Error {
        case invalidToolName
        case commandNotFound(for: String)
        case optionNotFound
        case noCommandProvided
        case parametersNotFound
        case insufficientParameters(requiredOccurence: Cardinality)
        case invalidParameterType
        case tooManyParameters
        case unrecognizedOptionParameterSignature
        case incorrectParameterFormat(expected:String, actual:String)
        case requiredOptionNotFound(optionName:String)
    }
    
    
    public init(value: String, type: ParsedType) {
        self.value = value
        self.type = type
    }
}

public class Arguments {
    private var unprocessed = [Argument]()
    
    init(forTool tool:Tool){
        for (index, element) in CommandLine.arguments.enumerated() {
            
            switch index {
            case 0:
                unprocessed.append(Argument(value: element, type: .tool))
            case 1:
                if tool[commandNamed: element] != nil {
                    unprocessed.append(Argument(value: element, type: .command))
                    break
                }
                fallthrough
            default:
                if element.hasPrefix("-") {
                    let start : String.Index
                    
                    if element.hasPrefix("--"){
                        start = element.index(element.startIndex, offsetBy: 2)
                    } else {
                        start = element.index(after: element.startIndex)
                    }
                    unprocessed.append(Argument(value: String(element[start..<element.endIndex]), type: .option))
                } else {
                    // Parameter
                    let newArg = Argument(value: element, type: .parameter)
                    unprocessed.append(newArg)
                }
            }
        }
    }

    public var top : Argument? {
        return unprocessed.first
    }
    
    public var count : Int {
        return unprocessed.count
    }
    
    public func consume(){
        assert(unprocessed.count > 0, "Attempt to consume an argument when none remain")
        unprocessed.removeFirst()
    }
}
