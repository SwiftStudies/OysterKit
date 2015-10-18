/*
Copyright (c) 2014, RED When Excited
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation

public class OKScriptTokenizer : Tokenizer {
    
    public override init(){
        super.init()
        //Eventually this will be it's own file
        
        self.branch(
            Characters(from:" \t\n,"),
            Delimited(delimiter: "\"", states:
                Repeat(state:Branch().branch(
                    LoopingCharacters(except: "\"\\").token("character"),
                    Characters(from:"\\").branch(
                        Characters(from:"x").branch(
                            Repeat(state: Branch().branch(
                                Characters(from: "0123456789abcdefABCDEF").token("hex")
                                ),min: 2,max: 2).token("character")
                        ),
                        Characters(from:"trn\"\\").token("character")
                    )
                ), min: 1, max: nil).token("Char")
            ).token("quote"),
            Delimited(delimiter: "'", states:
                Repeat(state:Branch().branch(
                    LoopingCharacters(except: "'\\").token("character"),
                    Characters(from:"\\").branch(
                        Characters(from:"'\\").token("character")
                    )
                ), min: 1).token("delimiter")
            ).token("single-quote"),
            Characters(from: "!").token("not"),
            Characters(from: "-").sequence(
                Characters(from:">").token("token")
            ),
            Characters(from:"^").token("exit-state"),
            Characters(from:"*").token("loop"),
            Characters(from:".").token("then"),
            Characters(from:"{").token("start-branch"),
            Characters(from:"}").token("end-branch"),
            Characters(from:"(").token("start-repeat"),
            Characters(from:")").token("end-repeat"),
            Characters(from:"<").token("start-delimited"),
            Characters(from:">").token("end-delimited"),
            Characters(from:"[").token("start-keyword"),
            Characters(from:"]").token("end-keyword"),
            Characters(from:"=").token("assign"),
            Keywords(validStrings: ["begin"]).branch(
                LoopingCharacters(from:lowerCaseLetterString+upperCaseLetterString+decimalDigitString+"_").token("variable"),
                Exit().token("tokenizer")
                ),
            Characters(from:"@").token("keyword").branch(
                    Characters(from:lowerCaseLetterString+upperCaseLetterString).sequence(
                        LoopingCharacters(from:lowerCaseLetterString+upperCaseLetterString+decimalDigitString+"_").token("state-name")
                    )
                ),
            OKStandard.number,
            OKStandard.Code.variableName
        )
    }
    
}


class State:Token{
    var state : TokenizationState
    
    init(state:TokenizationState){
        self.state = state
        super.init(name: "state",withCharacters: "")
    }
    
    override var description:String {
        return "State: "+state.description+state.pseudoTokenNameSuffix()
    }
}

class Operator : Token {
    init(characters:String){
        super.init(name: "operator", withCharacters: characters)
    }

    func applyTo(token:Token, parser:OKScriptParser)->Token?{
        return nil
    }
}

class EmitTokenOperator : Operator {
    override func applyTo(token: Token, parser:OKScriptParser) -> Token? {
        //TODO: Probably an error, should report that
        if !parser.hasTokens() {
            parser.errors.append("Expected a state to assign the token to")
            return nil
        }
        
        let topToken = parser.popToken()!
        
        if let stateToken = topToken as? State {
            stateToken.state.token(token.characters)
            return stateToken
        } else {
            if topToken.name == "state-name" {
                var error = "Trying to emit a token from a named state '\(topToken.characters)', but named state does not exist in: "
                var first = true
                for (name,_) in parser.definedNamedStates {
                    if !first {
                        error+=", "
                    } else {
                        first = false
                    }
                    error+="'\(name)'"
                }
                parser.errors.append(error)
            } else {
                parser.errors.append("Only states can emit tokens, and I received a \(topToken)")
            }
            parser.pushToken(topToken)
        }
        
        return nil
    }
}

class ChainStateOperator : Operator {
}

public class OKScriptParser:StackParser{
    var invert:Bool = false
    var loop:Bool = false
    public var errors = [String]()
    var finishedNamedStates = false
    
    var definedNamedStates = [String:Named]()
    
    public override init(){
        super.init()
    }
    
    func invokeOperator(onToken:Token){
        if hasTokens() {
            if topToken()! is Operator {
                let op = popToken()! as! Operator
                if let newToken = op.applyTo(onToken, parser: self) {
                    pushToken(newToken)
                }
            } else {
                errors.append("Expected an operator")
                pushToken(onToken)
            }
        } else {
            errors.append("Expected an operator, there were none")
            pushToken(onToken)
        }
    }
    
    override public func pushToken(symbol: Token) {
        if let state = symbol as? State {
            if let topTokenName = topToken()?.name {
                if topTokenName == "assign" {
                    popToken()
                    if let _ = topToken()?.name {
                        let stateName = popToken()!
                        //Now we need to create a named state, we only specify the root state
                        //we won't know the end state for some time
                        let namedState = Named(name: stateName.characters, root:state.state)
                        debug("Created state with charcters "+stateName.characters+" which results in a state that describes itself as "+namedState.description)
                        super.pushToken(State(state: namedState))
                        return
                    } else {
                        errors.append("Expected a state name to assign to the state")
                    }
                }
            }
        }
        
        super.pushToken(symbol)
    }
    
    func popTo(tokenNamed:String)->Array<Token> {
        var tokenArray = Array<Token>()
        
        var token = popToken()
        
        if token == nil {
            errors.append("Failed to pop to \(tokenNamed), there were no tokens on the stack")
            return tokenArray
        }
        
        while (token!.name != tokenNamed) {
            if let nextToken = token{
                tokenArray.append(nextToken)
            } else {
                errors.append("Stack exhausted before finding \(tokenNamed) token")
                return tokenArray
            }
            token = popToken()
            if token == nil {
                errors.append("Stack exhausted before finding \(tokenNamed) token")
                return Array<Token>()
            }
        }
        
        //Now we have an array of either states, or chains of states
        //and the chains need to be unwound and entire array reversed
        var finalArray = Array<Token>()
        var op : ChainStateOperator?
        
        for token in tokenArray {
            if let stateToken = token as? State {
                if op != nil {
                    //The last state needs to be removed, 
                    //chained to this state, 
                    ///and this state added to final
                    if finalArray.count == 0 {
                        errors.append("Incomplete state definition")
                        return Array<Token>()
                    }
                    let lastToken = finalArray.removeLast()
                    if let lastStateToken = lastToken as? State {
                        stateToken.state.branch(lastStateToken.state)
                        op = nil
                    } else {
                        errors.append("Only states can emit tokens")
                        return Array<Token>()
                    }
                }
                finalArray.append(stateToken)
            } else if token is ChainStateOperator {
                op = token as? ChainStateOperator
            } else {
                //It's just a parameter
                finalArray.append(token)
            }
        }
        
        return Array(finalArray.reverse())
    }
    
    func endBranch(){
        
        let branch = Branch()
        
        for token in popTo("start-branch"){
            if let stateToken = token as? State {
                branch.branch(stateToken.state)
            }
        }
        
        pushToken(State(state: branch))
    }
    
    func endRepeat(){
        var parameters = popTo("start-repeat")
        
        if (parameters.count == 0){
            errors.append("At least a state is required")
            return
        }
        
        if !(parameters[0] is State) {
            errors.append("Expected a state")
            return
        }
        
        var minimum = 1
        var maximum : Int? = nil
        let repeatingState = parameters[0] as! State
        
        if parameters.count > 1 {
            if let minimumNumberToken = parameters[1] as? NumberToken {
                minimum = Int(minimumNumberToken.numericValue)
                if parameters.count > 2 {
                    if let maximumNumberToken = parameters[2] as? NumberToken {
                        maximum = Int(maximumNumberToken.numericValue)
                    } else {
                        errors.append("Expected a number")
                        return
                    }
                }
            } else {
                errors.append("Expected a number")
                return
            }
        }
        
        let `repeat` = Repeat(state: repeatingState.state, min: minimum, max: maximum)
        
        pushToken(State(state:`repeat`))
    }
    
    func endDelimited(){
        var parameters = popTo("start-delimited")
        
        if parameters.count < 2 || parameters.count > 3{
            errors.append("At least two parameters are required for a delimited state")
            return
        }
        
        
        if parameters[0].name != "delimiter" {
            errors.append("At least one delimiter must be specified")
            return
        }

        var openingDelimiter = parameters[0].characters
        var closingDelimiter = openingDelimiter
        
        if parameters.count == 3{
            if parameters[1].name != "delimiter" {
                errors.append("Expected delimiter character as second parameter")
                return
            }
            closingDelimiter = parameters[1].characters
        }
        
        openingDelimiter = unescapeDelimiter(openingDelimiter)
        closingDelimiter = unescapeDelimiter(closingDelimiter)
        
        if let delimitedStateToken = parameters[parameters.endIndex-1] as? State {
            let delimited = Delimited(open: openingDelimiter, close: closingDelimiter, states: delimitedStateToken.state)
            
            pushToken(State(state:delimited))
        } else {
            errors.append("Final parameter must be a state")
            return
        }
    }
    
    func endKeywords(){
        let keyWordCharTokens = popTo("start-keyword")
        
        var keywordsArray = [String]()
        
        for token in keyWordCharTokens {
            if let stateToken = token as? State {
                if let charState = stateToken.state as? Characters {
                    keywordsArray.append("\(charState.allowedCharacters)")
                } else {
                    errors.append("Expected a char state but got \(stateToken.state)")
                }
            } else {
                errors.append("Only comma seperated strings expected for keywords, got \(token)")
            }
        }

        pushToken(State(state: Keywords(validStrings: keywordsArray)))
        
    }
    
    
    func unescapeChar(characters:String)->String{
        if characters.characters.count == 1 {
            return characters
        }
        
        let simpleTokenizer = Tokenizer()
        simpleTokenizer.branch(
                OKStandard.eot.token("ignore"),
                Characters(from:"\\").branch(
                    Characters(from:"\\").token("backslash"),
                    Characters(from:"\"").token("quote"),
                    Characters(from:"n").token("newline"),
                    Characters(from:"r").token("return"),
                    Characters(from:"t").token("tab"),
                    Characters(from:"x").branch(
                        Repeat(state: Branch().branch(Characters(from: "0123456789ABCDEFabcdef").token("hex")), min: 2, max: 4).token("unicode")
                    )
                ),
                Characters(except: "\\").token("character")
            )
        
        var output = ""
        for token in simpleTokenizer.tokenize(characters){
            switch token.name {
            case "unicode":
                let hexDigits = token.characters[token.characters.startIndex.successor().successor()..<token.characters.endIndex]
                if let intValue = Int(hexDigits) {
                    let unicodeCharacter = UnicodeScalar(intValue)
                    output += "\(unicodeCharacter)"
                } else {
                    errors.append("Could not create unicode scalar from \(token.characters)")
                }
            case "return":
                output+="\r"
            case "tab":
                output+="\t"
            case "newline":
                output+="\n"
            case "quote":
                output+="\""
            case "backslash":
                output+="\\"
            case "ignore":
                output += ""
            default:
                output+=token.characters
            }
        }
        
        return output
    }
    
    func unescapeDelimiter(character:String)->String{
        if character == "\\'" {
            return "'"
        } else if character == "\\\\" {
            return "\\"
        }
        return character
    }
    
    func createCharState(characters:String, inverted:Bool, looped:Bool)->State{
        var state : TokenizationState
        
        if inverted {
            state = looped ? LoopingCharacters(except:characters) : Characters(except:characters)
        } else {
            state = looped ? LoopingCharacters(from:characters) : Characters(from:characters)
        }
        
        return State(state: state)
    }
    
    func debugState(){
        if __okDebug {
            print("Current stack is:")
            for token in symbolStack {
                print("\t\(token)")
            }
            print("\n")
        }
    }
    
    func debug(message:String){
        if __okDebug {
            print(message)
        }
    }
    
    override public func parse(token: Token) -> Bool {
        
        debug("\n>Processing: \(token)\n")

        switch token.name {
        case "loop":
            loop = true
        case "not":
            invert = true
        case "Char":
            pushToken(createCharState(unescapeChar(token.characters), inverted: invert, looped: loop))
            invert = false
            loop = false
        case "then":
            pushToken(ChainStateOperator(characters:token.characters))
        case "token":
            pushToken(EmitTokenOperator(characters:token.characters))
        case "state-name":
            if let namedState = definedNamedStates[token.characters] {
                pushToken(State(state:namedState.clone()))
                debugState()
                return true
            }
            fallthrough
        case "delimiter","assign":
            pushToken(token)
        case "integer":
            pushToken(NumberToken(usingToken: token))
        case "variable":
            invokeOperator(token)
        case "exit-state":
            pushToken(State(state: Exit()))
        case "end-repeat":
            endRepeat()
        case "end-branch":
            endBranch()
        case "end-delimited":
            endDelimited()
        case "end-keyword":
            endKeywords()
        case "tokenizer":
            foldUpNamedStates()
        case let name where name.hasPrefix("start"):
            invert = false
            pushToken(token)
        default:
            return true
        }
        
        debugState()
        
        return true
    }

    func parseState(string:String) ->TokenizationState {
        OKScriptTokenizer().tokenize(string,newToken:parse)
        
        _ = Tokenizer()
        
        if let rootState = popToken() as? State {
            let flattened = rootState.state.flatten()

            return flattened
        } else {
            errors.append("Could not create root state")
            return Branch()
        }
    }
    
    func registerNamedState(inout stateSequence:[TokenizationState], inout endState:TokenizationState?)->Bool{
        //The last item in the list should be the named state, anything else should be a sequence
        if let namedState = stateSequence.removeLast() as? Named {
            debug("Registering the named state, putting the state back on the stack")
            debug("Sequence is: ")
            for state in stateSequence {
                debug("\t"+state.description)
            }
            if stateSequence.count > 0 {
                debug("Setting up sequence")
                namedState.sequence(Array(stateSequence.reverse()))
                namedState.endState = endState!
            }
            
            debug("Registering state and resetting sequence")
            debug("\t\(namedState)")
            definedNamedStates[namedState.name] = namedState
            
            endState = nil
        } else {
            errors.append("Expected a named state, but didn't get one. Aborting named state processing")
            return false
        }
        return true
    }
    
    func foldUpNamedStates(){
        
        debug("Folding and defining named states:")

        var endState:TokenizationState?
        var stateSequence = [TokenizationState]()
        var concatenate = false
        
        while hasTokens() {
            
            debugState()
    
            if let topStateToken = popToken()! as? State {
                debug("Top token was a state")
                
                if concatenate {
                    debug("Appending to state sequence")
                    stateSequence.append(topStateToken.state)
                } else {
                    //Is this the start of a chain?
                    if endState == nil {
                        debug("Creating a new state sequence")
                        endState = topStateToken.state
                        stateSequence.removeAll(keepCapacity: false)
                        stateSequence.append(endState!)
                    } else {
                        debug("Preparing to register a named state")
                        //This is actually the start of the next chain, put it back and unwind the chain
                        pushToken(topStateToken)
                        
                        if !registerNamedState(&stateSequence, endState: &endState){
                            return
                        }
                        
                    }
                }
                
                concatenate = false
            } else {
                debug("Assuming it was a concatenate operator")
                //This should be the then token
                concatenate = true
            }
        }
        
        if stateSequence.count > 0 {
            registerNamedState(&stateSequence, endState: &endState)
        }
        
        debugState()        
    }
    
    public func parse(string: String) -> Tokenizer {
        let tokenizer = Tokenizer()
        
        tokenizer.branch(parseState(string))
        tokenizer.namedStates = definedNamedStates
        
        tokenizer.flatten()
        
        return tokenizer
    }
}