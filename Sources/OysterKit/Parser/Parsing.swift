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

/**
 At this point this is a singleton to enforce the absence of any non-explicit state. It captures the current strategy for
 parsing used by all the different consumers of languages. If it turns out there is a need for multiple strategies this
 will be turned into a protocol, and multiple implementations can be provided.
 */
enum ParsingStrategy {
    
    /**
     Encapsulates all of the state associated with a parsing operation meaning that the two supplied static functions do not
     require any storage and are inherently thread safe. This is desireable as concurrent evaluation of rules is a generic goal
     of this project
    */
    class ParsingContext {
        let lexer                       : LexicalAnalyzer
        let ir                          : IntermediateRepresentation
        let language                    : Language
        var complete                    = false
        
        init(lexer:LexicalAnalyzer, ir:IntermediateRepresentation, language:Language){
            self.lexer      = lexer
            self.language   = language
            self.ir         = ir
        }
    }
    
    static func parse(_ source : String, using language:Language, with lexerType:LexicalAnalyzer.Type = Lexer.self, into ir:IntermediateRepresentation) throws {
        let context = ParsingContext(lexer: lexerType.init(source: source), ir: ir, language: language)
        
        do {
            while !context.complete {
                if try !pass(in: context) {
                    throw ProcessingError.interpretation(message: "Failure reported in pass(), but no error was thrown", causes: [])
                }
            }
        }
    }
    
    static func pass(`in`  context :ParsingContext) throws -> Bool{
        if context.complete {
            return false
        }
        var productionErrors = [Error]()
        var success = false
        
        if !context.lexer.endOfInput {
            let positionBeforeParsing = context.lexer.index
            for rule in context.language.grammar {
                do {
                    try rule.match(with: context.lexer, for: context.ir)
                    success = true
                    productionErrors.removeAll()
                    break
                } catch let error as CausalErrorType where error.isFatal {
                    throw error
                } catch {
                    productionErrors.append(error)
                    
                }
            }
            
            if !productionErrors.isEmpty {
                throw ProcessingError.parsing(message: "No rules matched input", range: productionErrors.range ?? context.lexer.index...context.lexer.index, causes: productionErrors)
            }
            
            if context.lexer.index == positionBeforeParsing {
                throw ProcessingError.scanning(message: "Lexer not advanced", position: context.lexer.index, causes: [])
            }
            
            if context.lexer.endOfInput {
                context.complete = true
            }
            
            return success
        } else {
            throw ProcessingError.scanning(message: "Unexpected end of input", position: context.lexer.source.unicodeScalars.endIndex, causes: [])
        }
    }
    
}


