import Foundation
import OysterKit
import STLR

let source = """
grammar Arrows

@forArrow  arrow  = ">" arrows?
@forArrows arrows = arrow
"""

do{
    
    let dynamicLanguage = try Parser(grammar:STLR._STLR.build(source).grammar.dynamicRules)
    let arrowsRule = (dynamicLanguage.grammar[0] as? BehaviouralRecursiveRule)?.surrogateRule
    
    print(String(repeating: "\n", count: 4))
    
    let arrowSource = ">"
    let lexer = Lexer(source: arrowSource)
    let ir = AbstractSyntaxTreeConstructor(with: arrowSource)
    
    try dynamicLanguage.grammar[0].test(with: lexer, for: ir)
} catch {
    print("\(error)")
}
