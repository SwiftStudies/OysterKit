import Foundation
import STLR
import OysterKit

let context = OperationContext(with: URL(fileURLWithPath: "/Users/nhughes/Desktop/")) { (message) in
    print(message)
}

let source = """
    grammar Test

    -whitespace  = .whitespaceOrNewline

    @characterSet("roman")
    ~letter     = .letter

     word       = letter+   // Should result in a reference, e.g. letter().refence().require(.oneOrMore).parse(as:word)

     end        = "." | "!" | "?"

     break      = "," | ";"

    // The interesting one is whitespace. It should come out as a skipping one or more reference (as the skipping should
    // be pulled from the declaration overriding default scan and then the cardinality
     sentance   = >>.uppercaseLetter word (break? whitespace+ word)* end
"""

do {
    let stlrAST = try _STLR.build(source)
    let swiftSource = TextFile("\(stlrAST.grammar.name).swift")
    stlrAST.swift(in:swiftSource)
    try swiftSource.perform(in: context)
    
    let rules = stlrAST.grammar.dynamicRules
    
    print(rules[0].description)
} catch {
    print("\(error)")
}

