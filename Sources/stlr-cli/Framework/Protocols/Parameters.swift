//
//  Parameters.swift
//  CommandKit
//
//  Created by Sean Alling on 11/8/17.
//

import Foundation


/**
 Defines the number of times a parameter of a particular type can appear.
 */
public enum Cardinality {
    case one(optional:Bool)
    case range(Range<Int>)
    case multiple(optional:Bool)
    
    var required:Bool {
        switch self {
        case .one(let optional):
            return !optional
        case .range(let range):
            return range.lowerBound > 0
        case .multiple(let optional):
            return !optional
            
        }
    }
    
    var min:Int {
        switch self {
        case .one(let optional):
            return optional ? 0 : 1
        case .range(let range):
            return range.lowerBound
        case .multiple(let optional):
            return optional ? 0 : 1
        
        }
    }
    
    var max:Int? {
        switch self {
        case .one(_):
            return 1
        case .range(let range):
            return range.upperBound
        case .multiple(_):
            return nil
            
        }
    }
}

public protocol ParameterType {
    var  name        : String { get }
    func transform(_ argumentValue : String )->Any?
}

public extension ParameterType {
    private func parameter(withCardinality cardinality:Cardinality)->Parameter{
        return Parameter(definition: PrarameterDefinition(type: self, requiredCardinality: cardinality))
    }
    
    public func between(_ min:Int, and max:Int)->Parameter{
        return parameter(withCardinality: Cardinality.range(min..<max))
    }
    
    public func multiple(optional:Bool)->Parameter{
        return parameter(withCardinality: Cardinality.multiple(optional: optional))
    }
    public func one(optional:Bool)->Parameter{
        return parameter(withCardinality: Cardinality.one(optional: optional))
    }
}

public enum StandardParameterType : ParameterType {
    
    case int, string, fileUrl
    
    public var name : String {
        return "\(self)"
    }
    
    public func transform(_ argumentValue: String) -> Any? {
        switch self {
        case .fileUrl:
            return URL(fileURLWithPath: argumentValue)
        case .string:
            return argumentValue
        case .int:
            return Int(argumentValue)
        }
    }
}

public struct PrarameterDefinition {
    let type                : ParameterType
    let requiredCardinality : Cardinality
}

public class Parameter{
    let definition : PrarameterDefinition
    var values     = [Any]()
    
    public init(definition:PrarameterDefinition){
        self.definition = definition
    }
    
    public var suppliedValues : Int {
        return values.count
    }
    
    public subscript(_ index:Int)->Any{
        assert(index<values.count,"Invalid index \(index)")
        return values[index]
    }
    
    public func consume(argument:Argument) throws {
        
        guard let parameterValue = definition.type.transform(argument.value) else {
            throw Argument.ParsingError.incorrectParameterFormat(expected: definition.type.name, actual: argument.value)
        }
        values.append(parameterValue)
    }
}


/**
     Defines an object that can accept parameter requirements.
 */
public protocol Parameterized {
    var parameters : [Parameter] {get}
}

public protocol ParameterIndex {
    var rawValue : Int { get }
    
    var parameter : Parameter { get }
    
    static var all : [Parameter] { get }
}

public protocol IndexableParameterized : Parameterized{
    associatedtype ParameterIndexType : ParameterIndex
}

public extension IndexableParameterized {
    subscript(parameter parameterIndex:ParameterIndexType)->Parameter{
        return parameters[parameterIndex.rawValue]
    }
    
    subscript<T>(parameter parameterIndex:ParameterIndexType)->T?{
        return parameters[parameterIndex.rawValue].values.first as? T
    }

    subscript<T>(parameter parameterIndex:ParameterIndexType, valueIndex:Int)->T?{
        return parameters[parameterIndex.rawValue].values[valueIndex] as? T
    }
}

extension Parameterized {
    
    func parse(arguments:Arguments) throws {
        for parameter in parameters {
            var captured = 0
            
            while let argument = arguments.top, captured < parameter.definition.requiredCardinality.max ?? Int.max && argument.type == .parameter{
                try parameter.consume(argument: argument)
                arguments.consume()
                captured = captured + 1
            }
            
            if captured < parameter.definition.requiredCardinality.min {
                throw Argument.ParsingError.insufficientParameters(requiredOccurence: parameter.definition.requiredCardinality)
            }
            
        }
    }
}

