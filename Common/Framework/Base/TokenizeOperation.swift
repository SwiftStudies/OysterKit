//
//  TokenizeOperation.swift
//  OysterKit Mac
//
//  Created by Nigel Hughes on 15/07/2014.
//  Copyright (c) 2014 RED When Excited Limited. All rights reserved.
//

import Foundation

var __debugScanning = false

func scanDebug(message:String){
    if __debugScanning {
        println(message)
    }
}

protocol EmancipatedTokenizer {
    func scan(operation:TokenizeOperation)
}

class TokenizeOperation : Printable {
    class Context : Printable {
        var tokens = [Token]()
        var consumedCharacters : String = ""

        let states : [TokenizationState]
        
        var __startIndex : String.UnicodeScalarView.IndexType
        var __currentIndex : String.UnicodeScalarView.IndexType
        var startPosition : Int
        var currentPosition : Int
        
        init(atPosition:Int, withMarker:String.UnicodeScalarView.IndexType, withStates:[TokenizationState]){
            __startIndex = withMarker
            __currentIndex = __startIndex
            
            startPosition = atPosition
            currentPosition = atPosition
            states = withStates
        }
        
        var description : String {
            return "Started at: \(startPosition), now at: \(currentPosition), having consumed \(consumedCharacters) and holding \(tokens)"
        }
    }
    
    
    var  current : UnicodeScalar
    var  next : UnicodeScalar?
    
    var  scanAdvanced = false

    var  __tokenHandler : (Token)->Bool
    let  __startingStates : [TokenizationState]
    let  eot = UnicodeScalar(4)
    var  __marker : String.UnicodeScalarView.GeneratorType {
    didSet{
        scanAdvanced = true
    }
    }
    var  __contextStack = [Context]()
    var  __sourceString : String.UnicodeScalarView

    var  context : Context {
        return __contextStack[__contextStack.endIndex-1]
    }
    
    var  complete : Bool {
        return current == eot 
    }
    
    var description : String {
        var output = "Tokenization Operation State\n\tCurrent=\(current) Next=\(next) scanAdvanced=\(scanAdvanced) Complete=\(complete)\n"
            
//        println(__contextStack.endIndex)
            
        //Print the context stack
        for var i = __contextStack.endIndex-1; i>=0; i-- {
            output+="\t"+__contextStack[i].description+"\n"
        }
            
        return output
    }
    
    //For now, to help with compatibility
    init(legacyTokenizer:Tokenizer){
        __sourceString = "\x04".unicodeScalars
        __marker = __sourceString.generate()
        current = __marker.next()!
        next = __marker.next()
        
        __startingStates = legacyTokenizer.branches
        __tokenHandler = {(token:Token)->Bool in
            println("No token handler specified")
            return false
        }
    }
    
    //
    // The primary entry point for the class, the token receiver will be called
    // whenever a token is published
    //
    func tokenize(string:String, tokenReceiver : (Token)->(Bool)){
        __tokenHandler = tokenReceiver
        
        //Prepare stack and context
        __contextStack.removeAll(keepCapacity: true)
        __contextStack.append(Context(atPosition: 0, withMarker:__sourceString.startIndex, withStates: __startingStates))
        
        //Prepare string
        __sourceString = string.unicodeScalars
        __marker = __sourceString.generate()
        
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
    func advance(){
        let advancedChar = "\(current)"

        context.consumedCharacters += advancedChar

        if next {
            current = next!
            next = __marker.next()
        } else {
            current = eot
        }

        context.__currentIndex++
        context.currentPosition++
        
        debug(operation: "advance()")
    }
    
    func token(token:Token){
        if !(token is Token.EndOfTransmissionToken) {
            context.tokens.append(token)
        }
        
        context.consumedCharacters = ""
        context.startPosition = context.currentPosition
        context.__startIndex = context.__currentIndex
        
        debug(operation: "token()")
    }
    
    
    func __publishTokens(inContext:Context)->Bool{
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
        
        debug(operation:"publishTokens()")
        
        return true
    }

    func pushContext(states:[TokenizationState]){
        //Publish any tokens before moving into the new state
        __publishTokens(context)
        
        let newContext = Context(atPosition: context.currentPosition, withMarker:context.__currentIndex, withStates: states)
        __contextStack.append(newContext)
        debug(operation: "pushContext()")
    }
    
    
    func popContext(publishTokens:Bool=true){
        let publishedTokens = publishTokens && context.tokens.count > 0
        
        if publishTokens {
            __publishTokens(context)
        }
        
        if __contextStack.count == 1 {
            debug(operation: "popContext()")
            return
        }
        
        let poppedState = __contextStack.removeLast()
        
        //If we didn't publish tokens merge in the new characters parsed so far
        if !publishedTokens {
            let additionalSubstring = __sourceString[context.__currentIndex..<poppedState.__currentIndex]
            let oldConsumedCharacters = poppedState.consumedCharacters
            
            context.consumedCharacters += additionalSubstring
        }
        
        //Update the now current context with the progress achieved by the popped state
        context.currentPosition = poppedState.currentPosition
        context.__currentIndex = poppedState.__currentIndex
        
        debug(operation: "popContext()")
    }
}

extension TokenizeOperation : EmancipatedTokenizer {
    func scan(operation:TokenizeOperation) {
        
        scanAdvanced = true
        
        while scanAdvanced && !complete {
            scanAdvanced = false
            debug(operation: "rootScan Start")

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
                context.consumedCharacters = ""
                context.startPosition = context.currentPosition
                context.__startIndex = context.__currentIndex
                __publishTokens(context)
            }
            
            debug(operation: "rootScan End")
        }
    }
}