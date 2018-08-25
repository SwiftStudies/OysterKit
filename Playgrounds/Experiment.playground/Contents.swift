import Foundation
import STLR

func updateExampleLanguagesSTLR() throws {
    ///
    ///
    let source = try String(contentsOfFile: "/Users/nhughes/Documents/Code/SPM/OysterKit/Resources/STLR.stlr")
    let operations = try SwiftStructure.generate(for: try _STLR.build(source), grammar: "Test", accessLevel: "public")
    
    let context = OperationContext(with: URL(fileURLWithPath: "/Users/nhughes/Documents/Code/SPM/OysterKit/Sources/ExampleLanguages")){
        print($0)
    }
    
    for operation in operations {
        try operation.perform(in: context)
    }
}

do {
    try updateExampleLanguagesSTLR()
    
    let source = """
        grammar Test
        
        -another = /test/
        -ows = another
    """
    
    let stlr = try _STLR.build(source)
    
    stlr.grammar["ows"].isVoid
    stlr.grammar["ows"].void
    
    let file = TextFile("test")
    stlr.swift(in: file)
    file.content
    
 
} catch {
    print("Error: \(error)")
}
