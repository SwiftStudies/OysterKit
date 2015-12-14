//
//  TokenizeOperation.swift
//  OysterKit Mac
//
//  Created by Nigel Hughes on 15/07/2014.
//  Copyright (c) 2014 RED When Excited Limited. All rights reserved.
//

import Foundation

public var __debugScanning = false

func scanDebug(message:String){
    if __debugScanning {
        print(message)
    }
}

public protocol EmancipatedTokenizer {
    func scan(operation:TokenizeOperation)
}

public class TokenizeOperation : CustomStringConvertible {
    public class Context : CustomStringConvertible {
        var tokens = [Token]()
        var consumedCharacters : String {
            let substring = __sourceString[__startIndex..<__currentIndex]

            return substring
        }

        let states : [TokenizationState]
        private let __sourceString : String

        private var __startIndex : String.Index
        private var __currentIndex : String.Index

        var startPosition : Int
        var currentPosition : Int

        private init(atPosition:Int, withMarker:String.Index, withStates:[TokenizationState], forString:String){
            __startIndex = withMarker
            __currentIndex = __startIndex
            __sourceString = forString

            startPosition = atPosition
            currentPosition = atPosition
            states = withStates
        }

        internal func flushConsumedCharacters(){
            __startIndex = __currentIndex
            startPosition = currentPosition
        }

        public var description : String {
            return "Started at: \(startPosition), now at: \(currentPosition), having consumed \(consumedCharacters) and holding \(tokens)"
        }
    }


    var  current : Character
    var  next : Character?

    var  scanAdvanced = false

    private var  __tokenHandler : (Token)->Bool
    private let  __startingStates : [TokenizationState]
    let  eot : Character = "\u{04}"
    private var  __marker : IndexingGenerator<String.CharacterView> {
        didSet{
            scanAdvanced = true
        }
    }
    private var  __contextStack = [Context]()
    private var  __sourceString : String

    var  context : Context
    var  complete : Bool {
        return current == eot
    }

    public var description : String {
        var output = "Tokenization Operation State\n\tCurrent=\(current) Next=\(next) scanAdvanced=\(scanAdvanced) Complete=\(complete)\n"

        //Print the context stack
        for var i = __contextStack.endIndex-1; i>=0; i-- {
            output+="\t"+__contextStack[i].description+"\n"
        }

        return output
    }

    //For now, to help with compatibility
    init(legacyTokenizer:Tokenizer){
        __sourceString = "\u{0004}"
        __marker = __sourceString.characters.generate()
        current = __marker.next()!
        next = __marker.next()

        __startingStates = legacyTokenizer.branches
        __tokenHandler = {(token:Token)->Bool in
            print("No token handler specified")
            return false
        }

        context = Context(atPosition: 0, withMarker: "".startIndex, withStates: [], forString: "")
    }

    //
    // The primary entry point for the class, the token receiver will be called
    // whenever a token is published
    //
    public func tokenize(string:String, tokenReceiver : (Token)->(Bool)){
        __tokenHandler = tokenReceiver

        //Prepare string
        __sourceString = string
        __marker = __sourceString.characters.generate()

        //Prepare stack and context
        __contextStack.removeAll(keepCapacity: true)
        __contextStack.append(Context(atPosition: 0, withMarker:__sourceString.startIndex, withStates: __startingStates, forString:__sourceString))
        context = __contextStack[0]

        if let first = __marker.next() {
            current = first
            next = __marker.next()
        } else {
            return
        }

        scan(self)
    }

    func debug(operation:String=""){
        if __debugScanning {
            scanDebug("\(operation) \(self)")
        }
    }

    //
    // Moves forward in the supplied string
    //
    public func advance(){
        if next != nil {
            current = next!
            next = __marker.next()
        } else {
            current = eot
        }

        context.__currentIndex++
        context.currentPosition++
    }

    public func token(token:Token){
        if !(token is Token.EndOfTransmissionToken) {
            context.tokens.append(token)
        }

        context.startPosition = context.currentPosition
        context.__startIndex = context.__currentIndex

        debug("token()")
    }


    private func __publishTokens(inContext:Context)->Bool{
        //Do we need to do this at all?
        if inContext.tokens.count == 0 {
            return true
        }

        for token in inContext.tokens {
            if !__tokenHandler(token){
                inContext.tokens.removeAll(keepCapacity: true)
                return false
            }
        }

        inContext.tokens.removeAll(keepCapacity: true)

        debug("publishTokens()")

        return true
    }

    public func pushContext(states:[TokenizationState]){
        //Publish any tokens before moving into the new state
        __publishTokens(context)

        let newContext = Context(atPosition: context.currentPosition, withMarker:context.__currentIndex, withStates: states, forString:__sourceString)
        __contextStack.append(newContext)
        context = newContext
        debug("pushContext()")
    }


    public func popContext(publishTokens:Bool=true){
        let publishedTokens = publishTokens && context.tokens.count > 0

        if publishTokens {
            __publishTokens(context)
        }

        if __contextStack.count == 1 {
            debug("popContext()")
            return
        }

        let poppedState = __contextStack.removeLast()
        context = __contextStack[__contextStack.count-1]

        //If we didn't publish tokens merge in the new characters parsed so far
        if !publishedTokens {
            _ = __sourceString[context.__currentIndex..<poppedState.__currentIndex]
            _ = poppedState.consumedCharacters
        }

        //Update the now current context with the progress achieved by the popped state
        context.currentPosition = poppedState.currentPosition
        context.__currentIndex = poppedState.__currentIndex

        debug("popContext()")
    }
}

extension TokenizeOperation : EmancipatedTokenizer {
    public func scan(operation:TokenizeOperation) {

        scanAdvanced = true

        while scanAdvanced && !complete {
            scanAdvanced = false
            debug("rootScan Start")

            //Scan through our branches
            for tokenizer in context.states {
                tokenizer.scan(operation)
                if scanAdvanced {
                    break
                }
            }

            //TODO: I would like this to be tidier. Feels wierd in the main loop, I don't like that not
            //issuing a token doesn't get you failure, don't like
            //If I am my own state
            if __contextStack.count == 1 {
                context.startPosition = context.currentPosition
                context.__startIndex = context.__currentIndex
                __publishTokens(context)
            }

            debug("rootScan End")
        }
    }
}