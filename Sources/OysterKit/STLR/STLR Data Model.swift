//
//  STLRAbstractSyntaxTree.swift
//  OysterKit
//
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import Foundation

// MARK: -
public class STLRIntermediateRepresentation : CustomStringConvertible {
    // MARK: -
    public enum Expression : CustomStringConvertible {
        
        case element(Element)
        case sequence([Element])
        case choice ([Element])
        case group()
        
        var isSequence : Bool { switch self { case .sequence: return true default: return false } }
        var isChoice   : Bool { switch self { case .choice: return true default: return false } }
        var isGroup   : Bool { switch self { case .group: return true default: return false } }

        mutating func add(element:Element){
            switch self {
            case .sequence(var elements):
                elements.append(element)
                self = .sequence(elements)
            case .choice(var elements):
                elements.append(element)
                self = .choice(elements)
            case .group:
                fatalError("Cannot add elements to a group expression")
            case .element:
                fatalError("Cannot add elements to an element")
            }
        }
        
        public func firstToken(_ identifier:Identifier, context:STLRIntermediateRepresentation?, searchStack:[String])->Bool{
            switch self{
            case .element(let element):
                return element.firstToken(identifier, context: context, searchStack: searchStack)
            case .sequence(let elements):
                return elements.first?.firstToken(identifier, context:context, searchStack: searchStack) ?? false
            case .choice(let elements):
                for element in elements {
                    if element.firstToken(identifier, context: context, searchStack: searchStack) {
                        return true
                    }
                }
                return false
            case .group:
                return false
            }
        }
        
        public func references(_ identifier:Identifier, context:STLRIntermediateRepresentation?, searchStack:[String])->Bool{
            switch self{
            case .element(let element):
                return element.references(identifier, context: context, searchStack: searchStack)
            case .sequence(let elements), .choice(let elements):
                for element in elements{
                    if element.references(identifier, context: context, searchStack: searchStack) {
                        return true
                    }
                }
                return false
            case .group:
                return false
            }
        }
        
        public var description: String{
            switch self {
            case .element(let el):
                return "\(el)"
            case .group:
                return "Proto-group"
            case .sequence(let elements):
                return elements.map({ return "\($0.stlrDescription)"}).joined(separator: " ")
            case .choice(let elements):
                return elements.map({ return "\($0.stlrDescription)"}).joined(separator: " | ")
            }
        }
        
        public var  scannable : Bool {
            let elements : [STLRIntermediateRepresentation.Element]
            
            switch self {
            case .element(let element): elements = [element]
            case .choice(let all), .sequence(let all): elements = all
            default: return false
            }
            
            for element in elements {
                if !element.scannable {
                    return false
                }
            }
            
            return true
        }
    }
    
    // MARK: -
    public enum Modifier : CustomStringConvertible {
        case one
        case zeroOrOne
        case zeroOrMore
        case oneOrMore
        case not
        case consume
        
        public var isOne : Bool {
            switch self {
            case .one : return true
            default:    return false
            }
        }

        public var isZeroOrOne : Bool {
            switch self {
            case .zeroOrOne : return true
            default:    return false
            }
        }

        public var isZeroOrMore : Bool {
            switch self {
            case .zeroOrMore : return true
            default:    return false
            }
        }

        public var isOneOrMore : Bool {
            switch self {
            case .oneOrMore : return true
            default:    return false
            }
        }

        public var isNot : Bool {
            switch self {
            case .not : return true
            default:    return false
            }
        }

        public var isConsume : Bool {
            switch self {
            case .consume : return true
            default:        return false
            }
        }

        
        public init(from string : String){
            switch string {
            case "?":
                self = .zeroOrOne
            case "*":
                self = .zeroOrMore
            case "+":
                self = .oneOrMore
            case "-":
                self = .consume
            case "!":
                self = .not
            default:
                self = .one
            }
        }
        
        public var description: String{
            switch self {
            case .one:
                return ""
            case .zeroOrOne:
                return "?"
            case .zeroOrMore:
                return "*"
            case .oneOrMore:
                return "+"
            case .not:
                return "!"
            case .consume:
                return "-"
            }
        }
        
        ///
        public var minimumMatches : Int {
            switch self{
            case .one, .oneOrMore, .not, .consume:
                return 1
            case .zeroOrOne, .zeroOrMore:
                return 0
            }
        }

        /// Returns the maximum number of allowed matches. A response of `nil` means there is
        /// no limit (match until failure).
        public var maximumMatches : Int? {
            switch self{
            case .oneOrMore, .zeroOrMore:
                return nil
            case .one, .zeroOrOne, .consume:
                return 1
            case .not:
                return 0
            }
        }
        
        /// Returns true if there is no ceiling to the number of matches
        public var unlimited : Bool {
            return maximumMatches == nil
        }
        
        /// Return true if absolutely no action should be taken on successful match (but a match must still occur)
        public var consume : Bool {
            return self == .consume
        }

        
        public func rule(appliedTo rule:Rule, producing token:Token, quantifiersAnnotations:RuleAnnotations)->Rule{
            switch self {
            case .one:
                return rule
            case .consume:
                return rule.consume(annotations: quantifiersAnnotations)
            case .not:
                return rule.not(producing: token, annotations: quantifiersAnnotations)
            case .zeroOrOne:
                return rule.optional(producing: token, annotations: quantifiersAnnotations)
            case .zeroOrMore:
                return rule.repeated(min: 0, limit: nil, producing: token, annotations: quantifiersAnnotations)
            case .oneOrMore:
                return rule.repeated(min: 1, limit: nil, producing: token, annotations: quantifiersAnnotations)
            }
        }
    }

    // MARK: -
    public indirect enum   Element : CustomStringConvertible{
        case terminal   (Terminal,   Modifier, Bool, ElementAnnotations)
        case identifier (Identifier, Modifier, Bool, ElementAnnotations)
        case group      (Expression, Modifier, Bool, ElementAnnotations)
        
        init(_ terminal:Terminal, _ quantifier: Modifier? = nil,_ annotations:ElementAnnotations? = nil){
            self = .terminal(terminal, quantifier ?? .one, false, annotations ?? ElementAnnotations())
        }
        
        init(_ identifier:Identifier, _ quantifier : Modifier? = nil){
            self = .identifier(identifier, quantifier ?? .one, false, ElementAnnotations())
        }
        
        init(_ expression:Expression, _ quantifier : Modifier? = nil){
            self = .group(expression, quantifier ?? .one, false, ElementAnnotations())
        }
        
        public mutating func setLookahead(lookahead : Bool) {
            switch self{
            case .terminal(let t, let q,_, let a):
                self = .terminal(t, q, lookahead, a)
            case .identifier(let i, let q, _, let a):
                self = .identifier(i, q, lookahead, a)
            case .group(let e, let q, _, let a):
                self = .group(e, q, lookahead, a)
            }
        }
        
        public var quantifierAnnotations : ElementAnnotations {
            // If there is no quantifier, there are no quantifier annotations
            // otherwise all annotations on this element (but none from the identifier) apply to the quantifier
            if quantifier == .one {
                return []
            } else {
                switch self {
                case .terminal(_, _, _, let annotations), .group(_, _, _, let annotations), .identifier(_, _, _, let annotations):
                    //As the quantifier is not one (initial check at start of function) all annotations apply to this
                    return annotations
                }
            }
        }
        
        public var elementAnnotations : ElementAnnotations {
            switch self {
            case .terminal(_, let quantifier, _, let annotations), .group(_, let quantifier, _, let annotations):
                //If there is a quantifier, all the annotations will apply to that, not this. However if it's 
                //just one they can be applied to this
                if quantifier == .one {
                    return annotations
                } else {
                    return []
                }
            case .identifier(let definition, let quantifier, _, let instanceAnnotations):
                //If there is no quantifier, then merge the annotations from the definition
                //of the identifier with those on this instance. Otherwise just those from
                //the definition of the identifier apply
                if quantifier == .one{
                    return definition.annotations.merge(with: instanceAnnotations)
                } else {
                    return definition.annotations
                }
            }
        }
        
        public var quantifier : Modifier {
            switch self {
            case .terminal(_, let q,_,_), .identifier(_, let q,_,_), .group(_, let q,_,_):
                return q
            }
        }
        
        public var description: String{
            switch self{
            case .terminal(let t, let q,let l, _):
                if q == .not {
                    return (l ? ">>" : "")+q.description+t.description
                } else {
                    return (l ? ">>" : "")+t.description+q.description
                }
            case .identifier(let i, let q, let l, _):
                if q == .not {
                    return (l ? ">>" : "")+q.description+i.stlrReference
                } else {
                    return (l ? ">>" : "")+i.stlrReference+q.description
                }
            case .group(let e, let q, let l, _):
                if q == .not {
                    return (l ? ">>" : "")+q.description+"("+e.description+")"
                } else {
                    return (l ? ">>" : "")+"("+e.description+")"+q.description
                }
            }
        }

        public var stlrDescription: String{
            return "\(elementAnnotations.merge(with: quantifierAnnotations).stlrDescription) \(description)"
         }
        
        // At the moment the only scanner rule is for one of multiple strings
        public var scannable : Bool {
            switch self {
            case .terminal(let terminal, let quantity, let lookahead,  let annotations) where quantity == .one && lookahead == false && annotations.isEmpty:
                return terminal.string != nil
            default: return false
            }
        }
        
        fileprivate func firstToken(_ identifier:Identifier, context:STLRIntermediateRepresentation?, searchStack:[String])->Bool{
            switch self{
            case .terminal:
                return false
            case .group(let expr, _,_, _):
                return expr.firstToken(identifier, context:context, searchStack: searchStack)
            case .identifier(let id, _,_, _):
                if identifier == id {
                    return true
                }
                guard let context = context else {
                    return false
                }
                return context.identifiers[id.name]?.grammarRule?.firstToken(identifier, context: context, searchStack:searchStack) ?? false
            }
        }
        
        public func references(_ identifier:Identifier, context:STLRIntermediateRepresentation?, searchStack:[String])->Bool{
            switch self{
            case .terminal:
                return false
            case .group(let expr, _,_, _):
                return expr.references(identifier, context:context, searchStack: searchStack)
            case .identifier(let id, _,_, _):
                if identifier == id {
                    return true
                }
                guard let context = context else {
                    return false
                }
                return context.identifiers[id.name]?.grammarRule?.references(identifier, context: context, searchStack: searchStack) ?? false
            }
        }
    }
    
    // MARK: -
    public class Identifier : CustomStringConvertible, Hashable {
        public let name            : String
        public var rawValue        : Int
        public var annotations     : ElementAnnotations
        var references      = [Range<String.UnicodeScalarView.Index>]()
        var grammarRule     : GrammarRule?

        public init(name:String, rawValue:Int) {
            self.name = name
            self.rawValue = rawValue
            self.annotations = ElementAnnotations()
        }
        
        public var stlrReference : String {
            return "\(name)"
        }
        
        public var description: String{
            return name
        }
        
        public var hashValue: Int{
            return rawValue
        }
    }
    
    // MARK: -
    public typealias ElementAnnotations = [ElementAnnotationInstance]
    
    public struct ElementAnnotationInstance : CustomStringConvertible{
        public let annotation : ElementAnnotation
        public var value      : ElementAnnotationValue
        
        public var description: String{
            return "\(annotation)"+(value.description.isEmpty ? "" : "=\(value.description)")
        }
        
        var stlrDescription : String {
            return "@\(annotation)"+(value.description.isEmpty ? "" : "(\(value.description))")
        }
        
        public init(_ annotation:ElementAnnotation, value: ElementAnnotationValue){
            self.annotation = annotation
            self.value = value
        }
        
        public init(_ annotation:ElementAnnotation){
            self.annotation = annotation
            self.value = .set
        }
    }
    
    // MARK: -
    public enum ElementAnnotationValue : CustomStringConvertible {
        case int(Int), bool(Bool), string(String), set
        
        public var description: String{
            switch self{
            case .int(let value):
                return "\(value)"
            case .bool(let value):
                return "\(value)"
            case .string(let value):
                return value
            case .set:
                return ""
            }
        }
        
        public var ruleValue : RuleAnnotationValue{
            switch self {
            case .int(let value):
                return RuleAnnotationValue.int(value)
            case .bool(let value):
                return RuleAnnotationValue.bool(value)
            case .string(let value):
                return RuleAnnotationValue.string(value)
            case .set:
                return RuleAnnotationValue.set
            }
        }
    }
    
    // MARK: -
    public typealias ElementAnnotation = RuleAnnotation
    
    // MARK: -
    public enum TerminalCharacterSet : CustomStringConvertible {
        case whitespaces
        case newlines
        case whitespacesAndNewlines
        case decimalDigits
        case alphanumerics
        case letters
        case uppercaseLetters
        case lowercaseLetters
        case customRange(CharacterSet,start:UnicodeScalar,end:UnicodeScalar)
        case multipleSets([TerminalCharacterSet])
        case customString(String)
        
        public init?(rawValue:String){
            switch rawValue{
            case "whitespaces": self = .whitespaces
            case "newlines" : self = .newlines
            case "whitespacesAndNewlines" : self = .whitespacesAndNewlines
            case "decimalDigits" : self = .decimalDigits
            case "alphanumerics" : self = .alphanumerics
            case "letters" : self = .letters
            case "uppercaseLetters" : self = .uppercaseLetters
            case "lowercaseLetters" : self = .lowercaseLetters
            default: return nil
            }
        }
        
        init(from:String, to:String){
            if let first = from.unicodeScalars.first, let last = to.unicodeScalars.first , first < last{
                self = .customRange(CharacterSet(charactersIn: first...last), start:first, end:last)
                return
            }
            
            if let first = from.unicodeScalars.first{
                self = .customRange(CharacterSet(charactersIn: first...first), start:first, end:first)
                return
            }
            
            fatalError("Could not convert \(from)...\(to) to a range")
        }
        
        var characterSet : CharacterSet {
            switch self {
            case .whitespaces: return CharacterSet.whitespaces
            case .newlines: return CharacterSet.newlines
            case .whitespacesAndNewlines: return CharacterSet.whitespacesAndNewlines
            case .decimalDigits: return CharacterSet.decimalDigits
            case .alphanumerics: return CharacterSet.alphanumerics
            case .uppercaseLetters: return CharacterSet.uppercaseLetters
            case .lowercaseLetters: return CharacterSet.lowercaseLetters
            case .letters: return CharacterSet.letters
            case .customRange(let characterSet,_,_): return characterSet
            case .multipleSets(let sets):
                var baseSet = sets[0].characterSet
                for index in 1..<sets.count {
                    baseSet = baseSet.union(sets[index].characterSet)
                }
                return baseSet
            case .customString(let string):
                return CharacterSet(charactersIn: string)
            }
        }
        
        public var description: String {
            switch self {
            case .whitespaces: return ".whitespaces"
            case .newlines: return ".newlines"
            case .whitespacesAndNewlines: return ".whitespacesAndNewlines"
            case .decimalDigits: return ".decimalDigits"
            case .alphanumerics: return ".alphanumerics"
            case .uppercaseLetters: return ".uppercaseLetters"
            case .lowercaseLetters: return ".lowercaseLetters"
            case .letters: return ".letters"
            case .customRange(_, let start, let end):
                return "\"\(start)\"...\"\(end)\""
            case .multipleSets(let sets):
                return "("+sets.map({ $0.description }).joined(separator: "|")+")"
            case .customString(let string):
                return "("+string.map({ "\"\($0)\"" }).joined(separator: "|")+")"
            }
        }
        

    }
    
    // MARK: -
    public struct Terminal : CustomStringConvertible{
        let string       : String?
        let characterSet : TerminalCharacterSet?
        
        private static func unescapeString(_ string:String)->String{
            return string.replacingOccurrences(of: "\\\"", with: "\"").replacingOccurrences(of: "\\\\", with: "\\")
        }
        
        public init(with string:String){
            self.string = Terminal.unescapeString(string)
            self.characterSet = nil
        }
        
        public init(with characterSet:TerminalCharacterSet){
            self.string = nil
            self.characterSet = characterSet
        }
        
        public var description: String{
            switch (string,characterSet){
            case (let sv,_) where sv != nil:
                return "\"\(sv!)\""
            case (_, let cs) where cs != nil:
                return "\(cs!)"
            default:
                return "❌ not implemented"
            }
        }
    }
    
    // MARK: -
    public struct Text  : CustomStringConvertible{
        let string : String
        
        public init(_ string:String) {
            self.string = string
        }
        
        public var description: String{
            return string
        }
    }
    
    // MARK: -
    public class GrammarRule  : CustomStringConvertible{
        public var identifier : Identifier? = nil {
            didSet {
                if let id = identifier {
                    id.grammarRule = self
                }
            }
        }

        var location    : Range<String.UnicodeScalarView.Index>
        
        var _expression : Expression?
        var expression  : Expression?{
            get {
                return _expression
            }
            
            set {
                guard let newExpression = newValue else {
                    _expression = nil
                    return
                }
                
                guard let oldExpression = _expression else {
                    _expression = newExpression
                    return
                }
                
                if oldExpression.isChoice {
                    _expression?.add(element: Element.group(newExpression, .one, false, ElementAnnotations()))
                } else {
                    _expression = Expression.choice([Element.group(oldExpression, .one, false, ElementAnnotations())])
                    _expression?.add(element: Element.group(newExpression, .one, false, ElementAnnotations()))
                }
            }
        }
        
        let grammar : STLRIntermediateRepresentation
        
        init(_ ast:STLRIntermediateRepresentation, range:Range<String.UnicodeScalarView.Index>){
            grammar = ast
            location = range
        }
        
        public var description: String{
            let annotationString : String
            
            if let annotations = identifier?.annotations, !annotations.isEmpty {
                annotationString = annotations.stlrDescription+" "
            } else {
                annotationString = ""
            }
            
            return "\(annotationString)\(identifier?.name ?? "**Unnamed**") = \(expression?.description ?? "**No expression**")".replacingOccurrences(of: "  ", with: " ")
        }
        
        public func validate() throws{
            if identifier == nil {
                throw LanguageError.semanticError(at: location, referencing: nil, message: "Missing identifier for rule")
            }

            if expression == nil {
                throw LanguageError.semanticError(at: location, referencing: nil, message: "Missing expression for rule")
            }
            
            //If it's left hand recursive then
            if leftHandRecursive {
                if let identifier = identifier {
                    if firstToken(identifier, context:grammar){
                        throw LanguageError.semanticError(at: location, referencing: nil, message: "\(identifier.name) references itself without advancing the scanner")
                    }
                }
            }
        }
        
        func firstToken(_ identifier:Identifier, context:STLRIntermediateRepresentation?, searchStack:[String] = [])->Bool{
            let myName = self.identifier?.name ?? ""
            //Don't recurse if I am already being searched (that is, search everything else)
            if searchStack.contains(myName){
                return false
            }
            var searchStack = searchStack
            searchStack.append(myName)
            return expression?.firstToken(identifier, context: context ?? grammar, searchStack: searchStack) ?? false
        }
        
        func references(_ identifier:Identifier, context:STLRIntermediateRepresentation?, searchStack:[String] = [])->Bool{
            let myName = self.identifier?.name ?? ""
            //Don't recurse if I am already being searched (that is, search everything else)
            if searchStack.contains(myName){
                return false
            }
            var searchStack = searchStack
            searchStack.append(myName)
            return expression?.references(identifier, context: context, searchStack: searchStack) ?? false
        }
        
        public var leftHandRecursive : Bool {
            if let identifier = identifier {
                return references(identifier, context: grammar)
            }
            return false
        }
        
        public var directLeftHandRecursive : Bool {
            if let identifier = identifier {
                return references(identifier, context: nil)
            }
            return false
        }
    }
    
    public static func build(from source: String) {
        
    }
    
    // MARK: -
    var     rootRules : [STLRIntermediateRepresentation.GrammarRule] {
        var rootRules : [STLRIntermediateRepresentation.GrammarRule] = []
        
        for rootCandidate in rules{
            guard let candidateIdentifier = rootCandidate.identifier else {
                continue
            }
            var success = true
            for referencingCandidate in rules {
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
        return rootRules
    }
    
    
    public subscript(identifier name:String)->Int?{
        for (_,identifier) in identifiers{
            if name == identifier.name {
                return identifier.rawValue
            }
        }
        return nil
    }
    
    public subscript(t:Token)->String?{
        for (_,identifier) in identifiers{
            if t.rawValue == identifier.rawValue {
                return identifier.name
            }
        }
        return nil
    }
    
    public subscript(i:Int)->String?{
        for (_,identifier) in identifiers{
            if i == identifier.rawValue {
                return identifier.name
            }
        }
        return nil
    }
    
    public var rules : [GrammarRule] = []
    public var errors = [Error]()
    public var identifiers : [String : STLRIntermediateRepresentation.Identifier] = [ : ]
    
    
    public var description: String{
        var result = ""
        if errors.count > 0 {
            result += "Errors:\n\t"+errors.map({"\($0)"}).joined(separator: "\n\t")
        }
        
        result += "\nRules:\n\t"+rules.map({"\($0)"}).joined(separator: "\n\t")
        return result+"\n"
    }
    
    public required init(){
        
    }
}

// MARK: -
public func==(lhs:STLRIntermediateRepresentation.Identifier, rhs:STLRIntermediateRepresentation.Identifier)->Bool{
    return lhs.name == rhs.name && lhs.rawValue == rhs.rawValue
}


public extension Collection where Iterator.Element == STLRIntermediateRepresentation.ElementAnnotationInstance{
    
    public var asRuleAnnotations : RuleAnnotations {
        var ruleAnnotations = [RuleAnnotation : RuleAnnotationValue]()
        for entry in self {
            ruleAnnotations[entry.annotation] = entry.value.ruleValue
        }
        return ruleAnnotations
    }
    
    var stlrDescription : String {
        return self.map({
            "\($0.stlrDescription)"
        }).joined(separator: " ")
    }
    
    public func isSet(_ annotation:STLRIntermediateRepresentation.ElementAnnotation)->Bool{
        return self[annotation: annotation] != nil
    }
    
    public subscript(annotation key:STLRIntermediateRepresentation.ElementAnnotation)->STLRIntermediateRepresentation.ElementAnnotationValue?{
        for annotation in self {
            if annotation.annotation == key {
                return annotation.value
            }
        }
        
        return nil
    }
    
    public func remove(_ annotation:STLRIntermediateRepresentation.ElementAnnotation)->STLRIntermediateRepresentation.ElementAnnotations{
        if self.isEmpty{
            return []
        }
        
        let cleaned = self.flatMap({ (annotationInstance)->STLRIntermediateRepresentation.ElementAnnotationInstance? in
            if annotationInstance.annotation == annotation {
                return nil
            }
            
            return annotationInstance
        })
        
        return cleaned
    }
    
    // Merges the incoming annotations with the existing list. Incoming annotations override those already there
    public func merge(with incoming:STLRIntermediateRepresentation.ElementAnnotations)->STLRIntermediateRepresentation.ElementAnnotations{
        
        if self.isEmpty {
            return incoming
        }
        
        var merged = STLRIntermediateRepresentation.ElementAnnotations()
        
        for annotation in self {
            if let incomingAnnotation = incoming[annotation: annotation.annotation]{
                merged.append(STLRIntermediateRepresentation.ElementAnnotationInstance(annotation.annotation, value: incomingAnnotation))
            } else {
                merged.append(annotation)
            }
        }
        
        for annotation in incoming{
            if merged[annotation: annotation.annotation] == nil {
                merged.append(annotation)
            }
        }
        
        return merged
    }
}

public extension STLRIntermediateRepresentation.ElementAnnotation{
    public init(rawValue : String){
        switch rawValue {
        case "pin":
            self = .pinned
        case "error":
            self = .error
        case "void":
            self = .void
        case "token":
            self = .token
        case "transient":
            self = .transient
        default:
            self = .custom(label: rawValue)
        }
    }
}

