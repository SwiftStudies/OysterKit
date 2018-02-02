//    Copyright (c) 2014, RED When Excited
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
import OysterKit

/// Used to hold the language that is generated
fileprivate struct DynamicLanguage : Language{
    
    /// The rules for the generated language
    fileprivate let grammar: [Rule]
}

// The key thing is generators are just extensions, so if someone wanted to 
// create and distribute a generator, they can just create a module with their
// own extension (perhaps cool if it's somehow scoped) to Grammar.AST
public extension STLRIntermediateRepresentation {
    public var runtimeLanguage:Language?{
        var rules = [Rule]()
        
        let generationContext = GenerationContext()
        
        var rootRules : [STLRIntermediateRepresentation.GrammarRule] = []
        
        for rootCandidate in self.rules{
            guard let candidateIdentifier = rootCandidate.identifier else {
                continue
            }
            var success = true
            for referencingCandidate in self.rules {
                guard let referencingCandidateIdentifier = referencingCandidate.identifier, referencingCandidateIdentifier != candidateIdentifier else {
                    continue
                }
                
                if referencingCandidate.references(candidateIdentifier, context: self){
                    success = false
                    break
                }
            }
            if success {
                rootRules.append(rootCandidate)
            }
        }
        
        for rule in rootRules {
            if let newRule = rule.rule(from: self,inContext: generationContext, annotations: [:]){
                rules.append(newRule)
            }
        }
        
        let language = DynamicLanguage(grammar: rules)
        
        return language
    }
}

fileprivate extension STLRIntermediateRepresentation{
    struct DynamicToken : Token, CustomStringConvertible{
        let rawValue : Int
        let name     : String?
        
        init(rawValue: Int) {
            self.rawValue = rawValue
            self.name = nil
        }
        
        init(rawValue:Int, name:String){
            self.rawValue = rawValue
            self.name = name
        }
        
        fileprivate var description: String{
            return name ?? "\(rawValue)"
        }
    }
    
    subscript(identifier named:String)->Token{
        let id = identifiers[named]?.rawValue ?? -1
        
        return DynamicToken(rawValue: id)
    }
}

internal final class GenerationContext{
    var cachedRules : [Int : Rule]
    
    init() {
        cachedRules = [:]
    }
}

fileprivate extension STLRIntermediateRepresentation.GrammarRule{
    fileprivate func rule(from grammar:STLRIntermediateRepresentation, inContext context:GenerationContext, creating token:Token? = nil, annotations: RuleAnnotations)->Rule? {
        let createToken = token ?? identifier?.token

        if let token = createToken{
            if var cachedRule = context.cachedRules[token.rawValue]{
                //Replace any cached annotations with those for the current instance
                cachedRule.annotations = annotations
                
                return cachedRule
            }
            
            // For both of these code paths... the annotations get passed in to the generated expresion. If the rules are then
            // wrapped, those annotations could be duplicated. What happens now is, they probably get lost.
            if let _ = identifier , leftHandRecursive {
                
                let rule = RecursiveRule()
                context.cachedRules[token.rawValue] = rule
                
                let expressionsRule = expression?.rule(from: grammar, creating: token, inContext:context, annotations: annotations)
                if expressionsRule?.produces.rawValue != token.rawValue {
                    let wrappedRule = ParserRule.sequence(produces: token, [rule], [ : ])
                    rule.surrogateRule = wrappedRule
                } else {
                    rule.surrogateRule = expressionsRule
                }

                return rule
            } else {
                if let rule = expression?.rule(from: grammar, creating: token, inContext:context, annotations: annotations){
                    //Sometimes the thing is folded completely flat
                    if rule.produces.rawValue != token.rawValue {
                        //This is inefficient, but provides a more accurate representation of the rule in the resultant AST
                        //More efficient would be to just change the token returned
                        let wrappedRule = ParserRule.sequence(produces: token, [rule], [ : ])
                        
                        // NOTE 1: IF YOU ARE DEBUGGING HERE note the rule.annotations up there could be a bug, it may need to be the passed in annotations
                        // NOTE 2: SO I WAS DEBUGGING HERE and noted that both the sequence and the contained expression were being tagged with the annotations, which did indeed look 
                        //         like a bug, so the line was changed from let wrappedRule = ParserRule.sequence(produces: token, [rule], rule.annotations) to let wrappedRule = ParserRule.sequence(produces: token, [rule], [:])
                        // NOTE 3: SEE IMPLEMENTATION FOR RECURSIVE RULE. That looks right. The wrappingrule gets the original annotations identified for the token
                        // So I'm going to chang the line above AGAIN to have annotations instead of an empty block which I think would lose annotations on the token identifier
                        // NOTE 4: I decided to change it back as duplicates are even worse than lost. This all needs reworking.
                        context.cachedRules[token.rawValue] = wrappedRule
                        return wrappedRule
                    } else {
                        context.cachedRules[token.rawValue] = rule
                        return rule
                    }
                } else {
                    return nil
                }
            }
        }
        
        return expression!.rule(from:grammar, creating:STLRIntermediateRepresentation.DynamicToken(rawValue: -1), inContext:context, annotations: [ : ])
    }
}

public extension STLRIntermediateRepresentation.GrammarRule{
    public func rule(from grammar:STLRIntermediateRepresentation, creating token:Token? = nil)->Rule? {
        return rule(from:grammar, inContext: GenerationContext(), creating:token, annotations: [:])
    }
}

extension STLRIntermediateRepresentation.Terminal{
    func rule(from grammar:STLRIntermediateRepresentation, creating token:Token, with annotations:RuleAnnotations?)->Rule? {
        if let string = string {
            return ParserRule.terminal(produces: token, string, annotations)
        }
        
        if let terminalCharacterSet = characterSet {
            return ParserRule.terminalFrom(produces: token, terminalCharacterSet.characterSet, annotations)
        }
        
        fatalError("No character set or string for terminal")
    }
}

extension STLRIntermediateRepresentation.Expression{
    func rule(from grammar:STLRIntermediateRepresentation, creating token:Token, inContext context:GenerationContext, annotations: RuleAnnotations)->Rule? {
        switch self{
        case .group:
            return nil
        case .element(let element):
            return element.rule(from: grammar, creating: token, inContext:context, annotations: annotations)
        case .choice(let elements):
            //Both choice and sequence currently just generate the originating token, with an intermediate rule that is DynamicToken(0)
            //Ideally these would be turned into a string for the name of the intermediate token
            if scannable {
                var strings = [String]()
                for element in elements{
                    if case .terminal(let terminal,_,_,_) = element , terminal.string != nil{
                        strings.append(terminal.string!)
                    }
                }
                return ScannerRule.oneOf(token: token, strings, annotations)
            } else {
                let rules = elements.flatMap(){
                    $0.rule(from: grammar, creating: $0.token, inContext:context, annotations: [:])
                }
                // Replaced the previously generated token which I suspect was done because the transient child behaviour was not right
                // with the actual supplied token which is lost. This does mean that you will get both the token from the choice and this
                // token, but that has to be right
                return rules.oneOf(token: token, annotations: annotations)
            }
        case .sequence(let elements):
            let rules = elements.flatMap(){
                $0.rule(from: grammar, creating: $0.token, inContext:context, annotations: [:])
            }
            return rules.sequence(token: token, annotations: annotations)
            
            
        }
    }
}

public extension STLRIntermediateRepresentation.Identifier{
    public var token : Token {
        return STLRIntermediateRepresentation.DynamicToken(rawValue: rawValue, name: name)
    }
    
    public func rule(from grammar:STLRIntermediateRepresentation, creating token:Token?)->Rule? {
        return rule(from: grammar, creating: token, inContext: GenerationContext(), annotations: [:] )
    }
}

fileprivate extension STLRIntermediateRepresentation.Identifier{
    func rule(from grammar:STLRIntermediateRepresentation, creating token:Token?, inContext context:GenerationContext, annotations: RuleAnnotations)->Rule? {
        guard let grammarRule = grammarRule else {
            return nil
        }
        
        return grammarRule.rule(from: grammar, inContext: context, creating: token, annotations: annotations)
    }
}

fileprivate extension STLRIntermediateRepresentation.Modifier{
    func wrapped(token:Token, annotations: RuleAnnotations)->Token{
        var rawValue    : Int?
        var identifier  : String?
        
        if let value = annotations[RuleAnnotation.token]{
            switch value {
            case .int(let intValue):
                rawValue = intValue
            case .string(let id):
                rawValue = id.hashValue
                identifier = id
            default:
                break
            }
        }
        
        let tokenRawValue = rawValue ?? transientTokenValue
        
        switch self{
        case .one:
            return token
        case .not:
            return STLRIntermediateRepresentation.DynamicToken.init(rawValue: tokenRawValue, name: identifier ?? "!\(token)")
        case .consume:
            return STLRIntermediateRepresentation.DynamicToken.init(rawValue: tokenRawValue, name: identifier ?? "\(token)-")
        case .zeroOrOne:
            return STLRIntermediateRepresentation.DynamicToken.init(rawValue: tokenRawValue, name: identifier ?? "\(token)?")
        case .oneOrMore:
            return STLRIntermediateRepresentation.DynamicToken.init(rawValue: tokenRawValue, name: identifier ?? "\(token)+")
        case .zeroOrMore:
            return STLRIntermediateRepresentation.DynamicToken.init(rawValue: tokenRawValue, name: identifier ?? "\(token)*")
        }
    }
}

extension STLRIntermediateRepresentation.Element{
    func rule(from grammar:STLRIntermediateRepresentation, creating token:Token, inContext context:GenerationContext, annotations:RuleAnnotations)->Rule? {
        let mergedElementAnnotations     = quantifier == .one ? elementAnnotations.asRuleAnnotations.merge(with: annotations) : elementAnnotations.asRuleAnnotations
        let mergedQuantifierAnnotations  = quantifier == .one ? quantifierAnnotations.asRuleAnnotations                       : quantifierAnnotations.asRuleAnnotations.merge(with: annotations)
        
        let elementToken        = quantifier == .one ? token : STLRIntermediateRepresentation.DynamicToken(rawValue: transientTokenValue)
        let quantifierToken     = quantifier != .one ? token : STLRIntermediateRepresentation.DynamicToken(rawValue: transientTokenValue)

        //For groups and terminals the token should be attached to the quantifier not the group/terminal rule
        switch self {
        case .terminal(let terminal, _,let lookahead, _):
            guard let r = terminal.rule(from: grammar, creating: elementToken, with: mergedElementAnnotations) else {
                return nil
            }
            if lookahead {
                return ParserRule.lookahead(r, mergedElementAnnotations)
            }
            return quantifier.rule(appliedTo: r, producing: quantifierToken, quantifiersAnnotations: mergedQuantifierAnnotations)
        case .group(let expression, _,let lookahead, _):
            guard let r = expression.rule(from: grammar, creating: elementToken,inContext:context, annotations: mergedElementAnnotations) else {
                return nil
            }
            if lookahead {
                return ParserRule.lookahead(r, mergedElementAnnotations)
            }
            return quantifier.rule(appliedTo: r, producing: quantifierToken, quantifiersAnnotations: mergedQuantifierAnnotations)
        case .identifier(let identifier, _,let lookahead, _):
            let identifiersAnnotations = identifier.annotations.asRuleAnnotations
            
            guard let r = identifier.rule(from: grammar, creating: identifier.token, inContext: context, annotations: mergedElementAnnotations) else {
                return nil
            }
            if lookahead {
                return ParserRule.lookahead(r,mergedElementAnnotations)
            }
            
            
            var finalRule = quantifier.rule(appliedTo: r, producing: quantifier.wrapped(token: identifier.token, annotations: mergedQuantifierAnnotations), quantifiersAnnotations: mergedQuantifierAnnotations)
            
            finalRule.annotations = identifiersAnnotations.merge(with: finalRule.annotations)
            
            return finalRule
        }
    }

    
    public var token : Token {
        switch self {
        case .identifier(let identifier, _,let lookahead, _) where lookahead == false:
            return identifier.token
        case .terminal(let terminal, _,let lookahead,_) where lookahead == false:
            return STLRIntermediateRepresentation.DynamicToken(rawValue: transientTokenValue, name: "\(terminal)")
        default:
            return STLRIntermediateRepresentation.DynamicToken(rawValue: transientTokenValue)
        }
    }
    
    
}
