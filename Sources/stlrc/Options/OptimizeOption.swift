//
//  OptimizeOption.swift
//  stlrc
//
//  Created on 18/06/2018.
//

import Foundation

class OptimizeOption : Option {
    init(){
        super.init(shortForm: "o", longForm: "optimize", description: "Optimize any parsed grammar before it is used for subsequent parsing or generation", parameterDefinition: [], required: false)
    }
}
