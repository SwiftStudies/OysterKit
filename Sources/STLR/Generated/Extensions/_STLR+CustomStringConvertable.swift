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

extension STLR : CustomStringConvertible {
    public var description: Swift.String {
        let result = TextFile(grammar.scopeName+".STLR")

        result.print("grammar \(grammar.scopeName)","")
        for module in grammar.modules ?? [] {
            result.print("import \(module.moduleName)")
        }
        result.print("")
        
        for rule in grammar.rules {
            result.print(rule.description)
        }
        
        return result.content
    }
}

extension STLR.Rule : CustomStringConvertible{
    public var description : String {
        return "\(identifier)\(tokenType == nil ? "" : "\(tokenType!)") \(assignmentOperators.rawValue) \(expression)"
    }
}

extension STLR.Expression : CustomStringConvertible {
    public var description : String {
        switch  self {
        case .element(let element):
            return element.description
        case .sequence(let sequence):
            return sequence.map({$0.description}).joined(separator: " ")
        case .choice(let choices):
            return choices.map({$0.description}).joined(separator: " | ")
        }
    }
}

extension STLR.Element : CustomStringConvertible {
    public var description : String {
        let quantity = quantifier?.rawValue ?? ""
        let allAttribs = annotations?.map({"\($0)"}).joined(separator: " ") ?? ""
        let prefix = allAttribs+(allAttribs.isEmpty ? "" : " ")+[lookahead,negated,transient,void].compactMap({$0}).joined(separator: "")
        var core : String
        if let group = group {
            core = "\(prefix)(\(group.expression))\(quantity)"
        } else if let identifier = identifier {
            core = "\(prefix)\(identifier)\(quantity)"
        } else if let terminal = terminal {
            core = "\(prefix)\(terminal.description)\(quantity)"
        } else {
            core = "!!UNKNOWN ELEMENT TYPE!!"
        }
        return core
    }
}

extension STLR.Annotation : CustomStringConvertible {
    public var description : String {
        return "@\(label)"+(literal == nil ? "" : "(\(literal!))")
    }
}

extension STLR.Literal : CustomStringConvertible {
    public var description : String {
        switch self {
        case .boolean(let value):
            return "\(value)"
        case .number(let value):
            return "\(value)"
        case .string(let value):
            return value.stringBody.debugDescription
        }
    }
}

extension STLR.Terminal : CustomStringConvertible {
    public var description : String {
        switch self {
        case .characterSet(let characterSet):
            return ".\(characterSet.characterSetName)"
        case .regex(let regex):
            return "/\(regex)/"
        case .terminalString(let terminalString):
            return terminalString.terminalBody.debugDescription
        case .characterRange(let characterRange):
            return "\(characterRange[0].terminalBody)...\(characterRange[0].terminalBody)"
        }
    }
}
