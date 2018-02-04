//#!/usr/bin/env xcrun swift -I .build/debug

import OysterKit
import STLR
import Foundation

print(CommandLine.arguments.reduce(""){ (result,element)->String in
    return result+element+"\n"
})
print("Hello World")
