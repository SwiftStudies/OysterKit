//
//  CommandKit.swift
//  stlr
//
//  Copyright © 2017 RED When Excited. All rights reserved.
//

import Foundation

fileprivate let shortOptionPrefix = "-"
fileprivate let longOptionPrefix  = "--"

//MARK: -

public protocol CommandLineOption{
    var shortFlag: String? {get}
    var longFlag:  String? {get}
    var defaultValue: String? {get}
    var helpMessage : String {get}
}

public extension CommandLineOption {
    var flagDescription : String {
        switch (shortFlag, longFlag){
        case let (sf?, lf?):
            return "\(shortOptionPrefix)\(sf), \(longOptionPrefix)\(lf)"
        case (nil, let lf?):
            return "\(longOptionPrefix)\(lf)"
            
        case (let sf?, nil):
            return "\(shortOptionPrefix)\(sf)"
        default:
            return ""
        }
    }
}

private extension CommandLineOption {
    var hashable : HashableCommandLineOption {
        return HashableCommandLineOption(wrapping: self)
    }
}

private struct HashableCommandLineOption : Hashable{
    let hashValue: Int
    
    static func ==(lhs: HashableCommandLineOption, rhs: HashableCommandLineOption) -> Bool {
        return lhs.wrapped.helpMessage == rhs.wrapped.helpMessage
    }
    
    private let wrapped : CommandLineOption
    init(wrapping commandLineOption:CommandLineOption){
        wrapped = commandLineOption
        hashValue = wrapped.helpMessage.hashValue
    }
}

//MARK: -


public class GenericOption : CommandLineOption{
    public let shortFlag : String?
    public let longFlag  : String?
    public let helpMessage : String
    public let defaultValue : String?
    
    public init(shortFlag: String? = nil, longFlag:String? = nil, defaultValue : String? = nil, help:String = ""){
        if let shortFlag = shortFlag{
            assert(shortFlag.count == 1,"Short flag must be a single character")
        }
        if let longFlag = longFlag{
            assert(Int(longFlag) == nil && Double(longFlag) == nil, "Long flag cannot be a numeric value")
        }
        
        self.shortFlag = shortFlag
        self.longFlag = longFlag
        self.defaultValue = defaultValue
        self.helpMessage = help
    }
    
    public internal(set) var isSet = false
}

class Parameter : GenericOption {
    init(){
        super.init(help: "Any argument that doesn't have a flag")
    }
}

//MARK: -
public protocol OptionValue{
    static func instance(`for` value:String)->Self?
}

public extension OptionValue {
    static var defaultValue : String? {
        return nil
    }
}

public extension String {
    public func getValue<T:OptionValue>()->T?{
        return T.instance(for: self)
        
    }
}

extension OptionValue where Self : ExpressibleByStringLiteral,Self.StringLiteralType == String{
    public static func instance(for value: String) -> Self? {
        return Self.init(stringLiteral:  value)
    }
}

extension OptionValue where Self : RawRepresentable,Self.RawValue == String{
    
    public static func instance(for value: String) -> Self? {
        guard let convertedValue = Self.init(rawValue: value) else{
            return nil
        }
        
        return convertedValue
    }
}

extension String : OptionValue{
}


extension Int : OptionValue{
    public static func instance(for value: String) -> Int? {
        return Int(value)
    }
}

extension Double : OptionValue {
    public static func instance(for value: String) -> Double? {
        return Double(value)
    }
}

//MARK: -

class Options{
    var options = [CommandLineOption]()
    private var values  = [HashableCommandLineOption : [String]]()
    
    public subscript<T:OptionValue>(_ option:CommandLineOption)->T?{
        guard let value = values[option.hashable]?.first ?? option.defaultValue else {
            return nil
        }
        
        return T.instance(for: value)
    }

    public subscript<V:OptionValue>(_ option:CommandLineOption)->[V]?{
        guard let values = values[option.hashable] else {
            return nil
        }
        
        do {
            let convertedValues : [V] = try values.map({
                guard let value : V = $0.getValue() else {
                    throw OptionError.invalidFormat(option: option,violation: "`\($0)` is not valid")
                }
                return value
                }
            )
            
            return convertedValues
        } catch {
            guard let defaultValue : V = option.defaultValue?.getValue() else {
                return nil
            }
            
            return [defaultValue]
        }
    }

    
    public func get<T:CommandLineOption>()->T?{
        for option in options {
            if let option = option as? T {
                return option
            }
        }
        
        return nil
    }
    
    private func get<T:StringProtocol>(longFlag:T)->CommandLineOption?{
        for option in options {
            guard let optionLongFlag = option.longFlag else {
                continue
            }
            
            if optionLongFlag == longFlag {
                return option
            }
        }
        
        return nil
    }
    
    private func get<T:StringProtocol>(shortFlag:T)->CommandLineOption?{
        for option in options {
            guard let optionShortFlag = option.shortFlag else {
                continue
            }
            
            if optionShortFlag == shortFlag {
                return option
            }
        }
        
        return nil
    }

    func set(option:CommandLineOption){
        if values[option.hashable] == nil {
            values[option.hashable] = []
        }
    }
    
    func addValue(option:CommandLineOption, _ value:String){
        if var currentValues = values[option.hashable] {
            currentValues.append(value)
            values[option.hashable] = currentValues
        } else {
            values[option.hashable] = [value]
        }
    }
    
    func optionForArgument(argument:String) throws ->CommandLineOption?{
        if argument.hasPrefix(longOptionPrefix){
            guard let option = get(longFlag: argument[argument.index(argument.startIndex, offsetBy: longOptionPrefix.count)..<argument.endIndex]) else {
                throw OptionError.unknownFlag(flag: argument)
            }
            
            return option
        } else if argument.hasPrefix(shortOptionPrefix){
            guard let option = get(shortFlag: argument[argument.index(argument.startIndex, offsetBy: shortOptionPrefix.count)..<argument.endIndex]) else{
                throw OptionError.unknownFlag(flag: argument)
            }
            return option
        }
        
        return nil
    }
    

}

public enum OptionError : Error {
    case missingRequiredOption(missing: [CommandLineOption])
    case unknownFlag(flag:String)
    case invalidFormat(option:CommandLineOption, violation:String)
}
