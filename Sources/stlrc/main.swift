//
//  STLR Decoder.swift
//  OysterKit
//
// Createed with heavy reference to: https://github.com/apple/swift-corelibs-foundation/blob/master/Foundation/JSONEncoder.swift#L802
//
//  Copyright © 2017 RED When Excited. All rights reserved.
//

import Foundation


#if canImport(NaturalLanguage)
    let commands = [GenerateCommand(), InstallCommand(), ProfileCommand()]
#else
    let commands = [GenerateCommand(), InstallCommand()]
#endif


let stlr = Tool(version: "1.0.0", description: "STLR Command Line Tool", defaultCommand: ParseCommand(), otherCommands: commands)

exit(Int32(stlr.execute()))

