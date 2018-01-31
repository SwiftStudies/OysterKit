//
//  Version.swift
//  CommandKit
//
//  Created by Sean Alling on 11/27/17.
//

import Foundation


/**
     Version Option
 */
public class VersionOption: Option, Runnable {
    
    let tool : Tool
    
    init(_ tool:Tool) {
        self.tool = tool
        super.init(longForm: "version", description: "Provides the version of \(tool.name)", parameterDefinition: [], required: false)
    }
    
    public func run() -> RunnableReturnValue {
        print(tool.version.style(.bold))
        return RunnableReturnValue.success
    }
}
