import Foundation
import OysterKit
import STLR

fileprivate extension String {
    var escaped : String {
        return self.replacingOccurrences(of: "\n", with: "\\n").replacingOccurrences(of: "\t", with: "\\t")
    }
}

class ParseCommand : Command, IndexableOptioned, IndexableParameterized, GrammarConsumer {
    typealias OptionIndexType = Options
    typealias ParameterIndexType = Parameters
    
    enum Errors : Error {
        case couldNotParseInput, couldNotCreateRuntimeLanguage
    }
    
    enum Parameters : Int, ParameterIndex {
        case inputFile

        var parameter: Parameter {
            switch self {
            case .inputFile: return StandardParameterType.fileUrl.multiple(optional: true)
            }
        }
        
        static var all: [Parameter] = [ inputFile.parameter ]
    }
    
    var inputFiles : [URL] {
        var inputs = [URL]()
        
        for index in 0..<parameters[0].suppliedValues {
            if let url = parameters[0][index] as? URL {
                inputs.append(url)
            }
        }
        return inputs
    }
    
    var interactiveMode : Bool {
        return inputFiles.count == 0
    }
    
    enum Options : String, OptionIndex {
        case grammar
        var option : Option {
            switch self {
            case .grammar : return GrammarOption()
            }
        }
        static var all : [Option] { return [Options.grammar.option] }
    }
    
    init(){
        super.init("parse", description: "Parses a set of input files using the supplied grammar",
                   options: Options.all,
                   parameters: Parameters.all)
    }

    func parseInput(language:Language, input:String) throws {
        let ctr = AbstractSyntaxTreeConstructor()
        _ = try ctr.build(input, using: language)

        guard ctr.errors.count == 0 else {
            print("Parsing failed: ".color(.red))
            ctr.errors.report(in: input)
            return
        }
    }
    
    override func run() -> RunnableReturnValue {
        guard let grammar = grammar else {
            print("Could not load grammar \(grammarUrl?.path ?? "file note specified")")
            return RunnableReturnValue.failure(error: GrammarOption.Errors.couldNotParseGrammar, code: -1)
        }
        
        let language = Parser(grammar: grammar.grammar.dynamicRules) 

        if interactiveMode {
            print("stlr interactive mode. Send a blank line to parse, two to terminate. Parsing grammar \(grammar.grammar.scopeName)")
            
            var previous = ""
            var total = ""
            while let line = readLine(strippingNewline: false) {
                if line + total == "\n\n" {
                    print("Done")
                    return RunnableReturnValue.success
                }

                if line == "\n" && previous.hasSuffix("\n"){
                    do {
                        try parseInput(language: language, input: String(total.dropLast(1)))
                    } catch {
                        print([error].report(in: line, from: "input".style(.italic)))
                    }
                    total = ""
                    previous = ""
                } else {
                    previous = line
                    total += line
                }

            }
        } else {
            do {
                print("Parsing \(inputFiles.count) input file(s)")
                for inputFile in inputFiles {
                    print("\(inputFile.path)".style(.bold))

                    let input = try String(contentsOfFile: inputFile.path, encoding: String.Encoding.utf8)
                    
                    do {
                        try parseInput(language: language, input: input)
                        print("Done".color(.green))
                    } catch {
                        print([error].report(in: input, from: inputFile.lastPathComponent))
                        return RunnableReturnValue.failure(error: error, code: -1)
                    }
                }
            } catch {
                return RunnableReturnValue.failure(error: error, code: -1)
            }
            
            
        }
        
        return RunnableReturnValue.success
    }
}
