import Foundation
import OysterKit
import STLR

if let stlrSourceStlr = try? String(contentsOfFile: "/Volumes/Personal/SPM/OysterKit/Resources/STLR.stlr") {
    // First of all compile it into a run time rule set with the old version
    guard let stlrGrammar = STLR.STLRParser(source: stlrSourceStlr).ast.runtimeLanguage else {
        fatalError("Could not parse STLR with old STLR")
    }

    do {
        let homogenousTree = try AbstractSyntaxTreeConstructor().build(stlrSourceStlr, using: stlrGrammar)
        print(homogenousTree.description)
    } catch {
        print("Could not parse:\n\n\(source)\n\nERROR: \(error)")
    }
}

