//
//  OutputLocationOption.swift
//  stlr
//
//  Created on 14/01/2018.
//

import Foundation

protocol OutputLocationConsumer {
    
}

extension OutputLocationConsumer where Self : Optioned {
    private var outputLocationOption : OutputFileOption? {
        return self[optionCalled:"output-to"]
    }
    
    var outputLocation : OutputFileOption.OutputLocation? {
        return outputLocationOption?.outputLocation
    }
}

class OutputFileOption : Option, IndexableParameterized{
    typealias ParameterIndexType = Parameters
    enum Parameters : Int, ParameterIndex {
        case location
        var parameter : Parameter {
            switch self {
            case .location: return OutputLocation(withPath: "").one(optional: false)
            }
        }
        static var all : [Parameter] { return [Parameters.location.parameter] }
    }
    struct OutputLocation : ParameterType{
        var name: String = "directory"
        
        func transform(_ argumentValue: String) -> Any? {
            return OutputLocation(withPath:argumentValue)
        }
        
        var path : String
        var file : String?
        
        init(withPath path:String = "./"){
            if path.hasSuffix("/"){
                self.path = path
            } else {
                self.file = NSString(string:path).lastPathComponent
                self.path = NSString(string:path).deletingLastPathComponent
            }
        }
        
        var isDirectory : Bool {
            return file == nil
        }

        func url(defaultName:String)->URL {
            if let file = file {
                return URL(fileURLWithPath: "\(path)/\(file)")

            }
            return URL(fileURLWithPath: "\(path)/\(defaultName)")
        }
        
    }
    
    var outputLocation : OutputLocation? {
        return self[parameter: Parameters.location]
    }
    
    init(){
        super.init(shortForm: "ot", longForm: "output-to", description: "The desired output path. If the parameter ends with a / it is assumed to be the directory to store the file in, otherwise it's assumed to be the full filename", parameterDefinition: [
            OutputLocation(withPath: "").one(optional: false)
            ], required: true)
        
    }
}
