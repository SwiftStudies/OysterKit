//
//  STLR Decoder.swift
//  OysterKit
//
// Createed with heavy reference to: https://github.com/apple/swift-corelibs-foundation/blob/master/Foundation/JSONEncoder.swift#L802
//
//  Copyright © 2017 RED When Excited. All rights reserved.
//

import Foundation

let stlr = Tool(version: "1.0.0", description: "STLR Command Line Tool", defaultCommand: ParseCommand(), otherCommands: [GenerateCommand(), InstallCommand()])

exit(Int32(stlr.execute()))

