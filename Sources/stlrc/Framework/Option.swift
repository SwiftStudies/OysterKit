//
//  Option.swift
//  CommandKit
//
//  Created by Sean Alling on 11/8/17.
//

import Foundation

public protocol Optioned {
    var options : [Option] {get}
}

public extension Optioned {
    public subscript<O:Option>(optionCalled longForm:String)->O?{
        for option in options {
            if option.longForm == longForm {
                return option as? O
            }
        }
        
        return nil
    }
}

public protocol OptionIndex {
    var rawValue : String {get}
    var option   : Option {get}
    
    static var all : [Option] {get}
}

public protocol IndexableOptioned : Optioned{
    associatedtype OptionIndexType : OptionIndex
}



public extension IndexableOptioned{
    
    subscript<T:Option>(option optionIndex :OptionIndexType)->T?{
        for option in options {
            if option.longForm == optionIndex.rawValue {
                return option as? T
            }
        }
        
        return nil
    }
    
    subscript<T>(_ option:OptionIndexType, _ parameter:ParameterIndex)->T?{
        return self[option,parameter,0]
    }
    
    subscript<V>(_ option:OptionIndexType, _ parameter:ParameterIndex, _ valueIndex : Int)->V?
    {
        guard let option = self[option:option] else {
            return nil
        }
        
        
        
        return option.parameters[parameter.rawValue] as? V
    }

}

open  class Option : Parameterized{
    public final let shortForm: String?
    public final let longForm: String
    public final let description: String
    public final let required: Bool

    final public private(set) var parameters : [Parameter]
    
    final public internal(set) var isSet = false
    
    public init(shortForm:String? = nil, longForm:String, description:String, parameterDefinition parameters:[Parameter], required : Bool = false) {
        self.shortForm = shortForm
        self.longForm = longForm
        self.description = description
        self.parameters = parameters
        self.required = required
    }
    
    func matches(argument:String)->Bool{
        if argument.hasPrefix("--"){
            if argument.substring(2..<argument.count) == longForm {
                return true
            }
        } else if let shortForm = shortForm, argument.hasPrefix("-"){
            if argument.substring(1..<argument.count) == shortForm {
                return true
            }
        }
        
        return false
    }

}

public final class Flag : Option {
    public init(shortForm: String? = nil, longForm:String, description:String){
        super.init(shortForm: shortForm, longForm: longForm, description: description, parameterDefinition: [], required: false)
    }
}

internal extension String {
    internal func substring(_ range:CountableRange<Int>)->Substring{
        let first = index(startIndex, offsetBy: range.startIndex)
        let last = index(first, offsetBy: range.upperBound-range.lowerBound)
        
        return self[first..<last]
    }
}



