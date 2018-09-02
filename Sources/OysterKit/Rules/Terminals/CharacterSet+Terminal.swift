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

//fileprivate let characterSetRangeExpression = try! NSRegularExpression(pattern: "<CFCharacterSet Range\\((\\d+),(\\d+)\\)>", options: [])
fileprivate let characterSetRangeExpression = try! NSRegularExpression(pattern: "(\\d+),(\\d+)", options: [])

/// Extends `CharacterSet` to implement `Terminal`
extension CharacterSet : Terminal {    
    public var matchDescription: String {
        if self == CharacterSet.letters {
            return ".letter"
        } else if self == CharacterSet.decimalDigits {
            return ".decimalDigit"
        } else if self == CharacterSet.uppercaseLetters {
            return ".uppercaseLetter"
        } else if self == CharacterSet.lowercaseLetters {
            return ".uppercaseLetter"
        } else if self == CharacterSet.alphanumerics {
            return ".alphaNumeric"
        } else if self == CharacterSet.whitespaces {
            return ".whitespace"
        } else if self == CharacterSet.newlines {
            return ".newline"
        } else if self == CharacterSet.whitespacesAndNewlines {
            return ".whitespaceOrNewline"
        }
        
        let selfDescription = "\(self)"
        
        if let rangeMatch = characterSetRangeExpression.firstMatch(in: selfDescription, options: [], range: NSRange(location: 0, length: selfDescription.count)){
            let selfNS = selfDescription as NSString
            return "\"\(selfNS.substring(with: rangeMatch.range(at: 1)))\"...\"\(selfNS.substring(with: rangeMatch.range(at: 2)))\""
        }
        
        return ".customCharacterSet"
    }
    
    public func test(lexer: LexicalAnalyzer, producing token:TokenType?) throws {
        do {
            try lexer.scan(oneOf: self)
        } catch {
            let failedAt = lexer.endOfInput ? "EOF" : lexer.current
            if let token = token {
                throw ProcessingError.parsing(message: "Failed to match \(token), expected \(matchDescription) but got \(failedAt)", range: lexer.index...lexer.index, causes: [error])
            } else {
                throw ProcessingError.scanning(message: "Expected \(matchDescription) but got \(failedAt)", position: lexer.index, causes: [])
            }
        }
    }
}
