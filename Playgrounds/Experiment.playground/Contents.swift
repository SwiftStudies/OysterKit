import Foundation
import OysterKit

STLRTokens.group.rule.shortDescription
STLRTokens.group.rule.description
let groupRecursive = STLRTokens.group.rule as! BehaviouralRecursiveRule
let expressionRecursive = STLRTokens.rule.rule as? ReferenceRule
groupRecursive.behaviour.describe(match: "")
groupRecursive.surrogateRule

let groupSource = """
(.letter)
"""

let ruleSource = """
a = \(groupSource)
"""

let grammarSource = """
grammar Test

\(ruleSource)
"""

do {
    let ast1 = try AbstractSyntaxTreeConstructor(with: groupSource).build(using: Parser(grammar:[STLRTokens.element.rule]))
    print("\(ast1)")
    let ast2 = try AbstractSyntaxTreeConstructor(with: ruleSource).build(using: Parser(grammar:[STLRTokens.rule.rule]))
    print("\(ast2)")
} catch {
    print("\(error)")
}

do {
    let rule = "identifier = (.letter)"
    let result = try _STLR.build("grammar Test\n\n"+rule)
    print("Done!")
} catch {
    print("Unexpected error: \(error)")
}
