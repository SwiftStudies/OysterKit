//
//  FileManager+stlr.swift
//  stlr
//
//  Created by RED When Excited on 10/01/2018.
//

import Foundation

public extension FileManager{
    public func isDirectory(_ url:URL)->Bool{
        var isDirectory : ObjCBool = false
        
        fileExists(atPath: url.path, isDirectory: &isDirectory)
        
        return isDirectory.boolValue
    }
}
