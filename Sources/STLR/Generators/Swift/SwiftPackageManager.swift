//    Copyright (c) 2016, RED When Excited
//    All rights reserved.
//
//    Redistribution and use in source and binary forms, with or without
//    modification, are permitted provided that the following conditions are met:
//
//    * Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
//    * Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
//    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
//    FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//    SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import Foundation

/// A generator which creates a library for the grammar using Swift PM
public class SwiftPackageManager : Generator {
    public static func generate(for scope: STLRScope, grammar name: String, accessLevel:String) throws -> [Operation] {
        let writePackageFile = TextFile("Package.swift")
        writePackageFile.print(packageTemplate.replacingOccurrences(of: "$GRAMMAR_NAME$", with: name))
        let createMain = TextFile("main.swift")
        createMain.print(mainTemplate.replacingOccurrences(of: "$GRAMMAR_NAME$", with: name))

        return [
                    Check.ifFileExists(path: "\(name)/Package.swift").then([
                            System.changeDirectory(name: name),
                            System.setEnv(name: "new", value: "false")
                        ], else: [
                            System.makeDirectory(name: name),
                            System.changeDirectory(name: name),
                            System.shell("swift", arguments: ["package","init","--type","executable"]),
                            writePackageFile,
                            System.setEnv(name: "new", value: "true")
                        ]),
                    System.changeDirectory(name: "Sources/\(name)"),
                    try SwiftStructure.generate(for: scope, grammar: name, accessLevel: accessLevel),
                    Check.ifEnvEquals(name: "new", requiredValue: "true").then(
                        createMain
                    ),
        ]
    }
    
    
}

fileprivate let packageTemplate = """
// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "$GRAMMAR_NAME$",
    dependencies: [
            // Dependencies declare other packages that this package depends on.
            // .package(url: /* package url */, from: "1.0.0"),
            .package(url: "https://github.com/SwiftStudies/OysterKit.git", .branch("master"))
        ],
        targets: [
            // Targets are the basic building blocks of a package. A target can define a module or a test suite.
            // Targets can depend on other targets in this package, and on products in packages which this package depends on.
            .target(name: "$GRAMMAR_NAME$",dependencies: ["OysterKit"]),
        ]
    )
"""

fileprivate let mainTemplate = """
import OysterKit
import Foundation

// Enables signpost support if you want to debug with Instruments
if #available(OSX 10.14, *) {
    Log.parsing.enable()
}


print("Welcome to the default $GRAMMAR_NAME$ application. Type any string below to parse, pressing return twice will cause parsing to begin")

// Loop forever until they enter QUIT
var combinedString = ""
while let userInput = readLine(strippingNewline: false) {
    if combinedString.hasSuffix("\\n") && userInput == "\\n"{
        if combinedString == userInput {
            print("Thank you for running $GRAMMAR_NAME$")
            exit(EXIT_SUCCESS)
        }
        do{
            let ctr = AbstractSyntaxTreeConstructor()
            let ast = try ctr.build(String(combinedString.dropLast()), using: $GRAMMAR_NAME$.generatedLanguage)
            guard ctr.errors.count == 0 else {
                print("Parsing failed: \\(ctr.errors)")
                break
            }
            print(ast.description)
        } catch {
            print("\\(error)")
        }

        combinedString = ""
        print("\\nReady for next input")
    } else {
        combinedString += userInput
    }
}
"""
