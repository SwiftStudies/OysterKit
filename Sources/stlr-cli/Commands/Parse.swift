import Foundation
import OysterKit

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
    
    func prettyPrint(source:String, contents:[HeterogeneousNode], indent : String = ""){
        for node in contents {
            if node.children.count > 0 {
                print("\(indent)"+"\(node.token)".style(.bold))
                prettyPrint(source:source, contents: node.children, indent: indent+"\t")
            } else {
                print("\(indent)"+"\(node.token)".style(.bold)+" '\(node.stringValue(source: source).escaped)'")
            }
        }
    }
    
    func errorMessage(`in` input:String, failedBecause message:String,  at errorIndex:String.Index)->String{
        
        func occurencesOf(_ character: Character, `in` asString:String)->(count:Int,lastFound:String.Index) {
            var lastInstance = asString.startIndex
            var count = 0
            
            for (offset,element) in asString.enumerated() {
                if character == element {
                    count += 1
                    
                    lastInstance = asString.index(asString.startIndex, offsetBy: offset)
                }
            }
            
            return (count, lastInstance)
        }
        
        if errorIndex >= input.endIndex {
            return errorMessage(in: input, failedBecause: message,  at: input.index(before: input.endIndex))
        }
        
        let occurences      = occurencesOf("\n", in: String(input[input.startIndex..<errorIndex]))
        
        let offsetInLine    = input.distance(from: occurences.lastFound, to: errorIndex)
        let inputAfterError = input[input.index(after:errorIndex)..<input.endIndex]
        let nextCharacter   = inputAfterError.index(of: "\n") ?? inputAfterError.endIndex
        let errorLine       = String(input[occurences.lastFound..<nextCharacter])
        let prefix          = "\(message) at line \(occurences.count), column \(offsetInLine): "
        
        let pointerLine     = String(repeating:" ", count: prefix.count+offsetInLine)+"^"
        
        return "\(prefix)\(errorLine)\n\(pointerLine)"
    }
    
    func parseInput(language:Language, input:String) throws {
        let ast : DefaultHeterogeneousAST = language.build(source: input)
        
        guard ast.errors.count == 0 else {
            print("Parsing failed: ".color(.red))
            for error in ast.errors {
                if let humanReadable = error as? HumanConsumableError {
                    print(errorMessage(in: input, failedBecause: humanReadable.message, at: humanReadable.range.lowerBound))
                } else {
                    print("\(error)")
                }
            }
            return
        }
        
        prettyPrint(source: input, contents: ast.tokens)
    }
    
    override func run() -> RunnableReturnValue {
        guard let grammar = grammar else {
            print("Could not load grammar \(grammarUrl?.path ?? "file note specified")")
            return RunnableReturnValue.failure(error: GrammarOption.Errors.couldNotParseGrammar, code: -1)
        }
        
        guard let language = grammar.ast.runtimeLanguage else {
            return RunnableReturnValue.failure(error: Errors.couldNotCreateRuntimeLanguage, code: -1)
        }

        if interactiveMode {
            print("stlr interactive mode. Send a blank line to terminate. Parsing \(grammarName ?? grammarUrl?.path ?? "Grammar")")
            while let line = readLine(strippingNewline: true) {
                if line == "" {
                    print("Done")
                    return RunnableReturnValue.success
                }
                do {
                    try parseInput(language: language, input: line)
                } catch {
                    return RunnableReturnValue.failure(error: error, code: -1)
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
                        print("\(error)".color(.red).style(.blink))
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
