//    Copyright (c) 2018, RED When Excited
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

public protocol Terminal : RuleProducer {
    /**
     Tests the the `Terminal` is available at the current scanner head position,
     throwing an `Error` if not
     
     - Parameter lexer: The lexer being used for scanning
     - Parameter token: The token produced if any. 
    */
    func test(lexer: LexicalAnalyzer, producing token:Token?) throws
}

/// Extends any terminal to be a `RuleProducer`
public extension Terminal {
    /**
     Creates a rule that tests for the terminal (with the specified cardinality)
     moving the scanner head forward but not including the range of the result
     in any match.
     
     - Parameter cardinality: The desired cardinality of the match
     - Returns: A rule
     */
    public func skip(_ cardinality:Cardinality = .one)->BehaviouralRule{
        return TerminalRule(Behaviour(.skipping, cardinality: cardinality), and: [:], for: self)
    }
    
    /**
     Creates a rule that tests for the terminal (with the specified cardinality)
     that includes the range of the result in any matched string
     
     - Parameter cardinality: The desired cardinality of the match
     - Returns: A rule
     */
    public func scan(_ cardinality:Cardinality = .one)->BehaviouralRule{
        return TerminalRule(Behaviour(.scanning, cardinality: cardinality), and: [:], for: self)
    }
    
    /**
     Creates a rule that tests for the terminal (with the specified cardinality)
     that will produce the defined token
     
     - Parameter token: The token to be produced
     - Parameter cardinality: The desired cardinality of the match
     - Returns: A rule
     */
    public func token(_ token:Token,from cardinality:Cardinality = .one)->BehaviouralRule{
        return TerminalRule(Behaviour(.structural(token: token), cardinality: cardinality), and: [:], for: self)

    }
}

// Extends collections of terminals to support creation of Choice scanners
extension Array: Terminal, RuleProducer where Element : Terminal {
    
    public func test(lexer: LexicalAnalyzer, producing token:Token?) throws {
        
        var errors = [Error]()
        for terminal in self {
            do {
                let _ = try terminal.test(lexer: lexer, producing: token)
                return
            } catch {
                errors.append(error)
            }
        }
        
        if let token = token {
            throw TestError.parsingError(message: "Failed to match \(token)", range: lexer.index...lexer.index, causes: errors)
        } else {
            throw TestError.scanningError(message: "Expected one of \(map({"\($0)"}).joined(separator: ", "))", position: lexer.index, causes: [])
        }
    }
}
