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
    public static func generate(for scope: STLRScope, grammar name: String) throws -> [Operation] {
        
        var newPackageOperations = [Operation]()

        newPackageOperations.append(System.makeDirectory(name: name))
        newPackageOperations.append(System.changeDirectory(name: name))
        newPackageOperations.append(System.shell("swift", arguments: ["package","init","--type","executable"]))
        
        let packageFile = TextFile("Package.swift")
        packageFile.print(packageTemplate.replacingOccurrences(of: "$GRAMMAR_NAME$", with: name))
        newPackageOperations.append(packageFile)
        
        var existingPackageOperations = [Operation]()
        existingPackageOperations.append(System.changeDirectory(name: name))

        var operations = [Operation]()
        operations.append(BranchingOperation(with: .fileExists(path: "\(name)/Package.swift", ifTrue: existingPackageOperations, ifFalse: newPackageOperations)))
        
        operations.append(System.changeDirectory(name: "Sources/Calculator"))
        #warning("Don't update main if the package exists")
        let mainFile = TextFile("main.swift")
        mainFile.print(mainTemplate.replacingOccurrences(of: "$GRAMMAR_NAME$", with: name))
        operations.append(mainFile)
        operations.append(contentsOf: try SwiftStructure.generate(for: scope, grammar: name))


        return operations
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

print("Welcome to the default $GRAMMAR_NAME$ application. Type any string below to parse, pressing return twice will cause parsing to begin")

// Loop forever until they enter QUIT
var combinedString = ""
while let userInput = readLine(strippingNewline: false) {
    if combinedString.hasSuffix("\\n") && userInput == "\\n"{
        do{
            let ctr = AbstractSyntaxTreeConstructor()
            let ast = try ctr.build(combinedString, using: $GRAMMAR_NAME$.generatedLanguage)
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
