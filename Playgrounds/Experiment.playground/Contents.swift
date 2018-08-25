import Foundation
import OysterKit

let plus    = -"+"
let number  = CharacterSet.decimalDigits.require(.oneOrMore).parse(as: LabelledToken(withLabel: "number"))
let sum     = [ number, plus, number ].sequence.parse(as: LabelledToken(withLabel: "sum"))

do {
    let ast = try AbstractSyntaxTreeConstructor(with: "10+2").build(using: Parser(grammar: [sum]))
    print(ast.description)
} catch {
    print("😢 \(error)")
}
