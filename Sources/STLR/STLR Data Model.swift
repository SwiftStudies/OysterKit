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

// MARK: -
/**
 This classes is a bespoke implementation of an `IntermediateRepresentation` used when parsing STLR. Unlike generic
 implementations it specifies a concrete data structure that is populated during parsing
 */
public class STLRIntermediateRepresentation : CustomStringConvertible {
    // MARK: -
    /// Represents a STLR Expression
    public enum Expression : CustomStringConvertible {
        /// An expression which has a single element
        case element(Element)
        
        /// An expression which represents a sequence of elements
        case sequence([Element])
        
        /// An expression which represents a choice of elements
        case choice ([Element])
        
        /// An expression which represents a group
        case group()
        
        /// `true` if the element is a sequence
        var isSequence : Bool { switch self { case .sequence: return true default: return false } }
        
        /// `true` if the element is a choice
        var isChoice   : Bool { switch self { case .choice: return true default: return false } }
        
        /// `true` if the element is a group
        var isGroup   : Bool { switch self { case .group: return true default: return false } }

        /**
         Adds an element to a sequence or choice. Attempting to add to any other case will result in a fatal error
         
         - Parameter element: The `Element` to add
        */
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
        
        /**
         Evaluates if the supplied identifier is the first element in the `Expression`
         
         - Parameter identifier: The identifier being searched for
         - Parameter context: The STLR AST being evaluated in
         - Parameter searchState: The identifiers already searched (to avoid infinite recursion)
         - Returns: `true` if it is, false if it isn't
        */
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
        
        /**
         Evaluates if the supplied identifier is referenced by this `Expression`
         
         - Parameter identifier: The identifier being searched for
         - Parameter context: The STLR AST being evaluated in
         - Parameter searchState: The identifiers already searched (to avoid infinite recursion)
         - Returns: `true` if it is, false if it isn't
         */
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
        
        /// A human readable description
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
        
        /// `true` if this expression can be entirely scanned (that is, it is just a collection of terminals)
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
    /// Represents a modifier on an `Expression` such as `!` or `*`
    public enum Modifier : CustomStringConvertible {
        /// Match just one
        case one
        /// Match one or none
        case zeroOrOne
        /// Match none or any number
        case zeroOrMore
        
        /// Match at least one up to any number
        case oneOrMore
        
        /// Invert the expression logical result
        case not
        
        /// Just consume the result
        case consume
        
        /// `true` if it's an isOne case
        public var isOne : Bool {
            switch self {
            case .one : return true
            default:    return false
            }
        }

        /// 'true' if it's a zero or one case
        public var isZeroOrOne : Bool {
            switch self {
            case .zeroOrOne : return true
            default:    return false
            }
        }

        
        /// `true` if it's a zero or more case
        public var isZeroOrMore : Bool {
            switch self {
            case .zeroOrMore : return true
            default:    return false
            }
        }

        /// `true` if it's a one or more case
        public var isOneOrMore : Bool {
            switch self {
            case .oneOrMore : return true
            default:    return false
            }
        }

        /// `true` if it's a not case
        public var isNot : Bool {
            switch self {
            case .not : return true
            default:    return false
            }
        }

        /// `true` if it's a consume case
        public var isConsume : Bool {
            switch self {
            case .consume : return true
            default:        return false
            }
        }

        /**
         Creates a new instance from the supplied string
         
         - Parameter from: The String which should be one of ?*+-! or nothing
        */
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
        
        /// A human readable description
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
        
        /// The smallest number of matches to satisfy the quantifier
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

        /**
         Creates a rule wrappng the supplied rule and appying the specified modifier
         
         - Parameter appliedTo: The rule to be wrapped
         - Parameter producing: The token to produce
         - Parameter quantifiersAnnotations: The annotations that should be applied to the token
         - Returns: The `Rule`
        */
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
    /// Captures a single element of an `Expression`
    public indirect enum   Element : CustomStringConvertible{
        /// A terminal (purely scannable)
        case terminal   (Terminal,   Modifier, Bool, ElementAnnotations)
        
        /// An identifier (a reference to another rule)
        case identifier (Identifier, Modifier, Bool, ElementAnnotations)
        
        /// A group (an adhoc collection sub-expression)
        case group      (Expression, Modifier, Bool, ElementAnnotations)
        
        /**
         Creates a new instance of an element for a terminal
         
         - Paramerter terminal: The required terminal
         - Parameter quantifier: Any quantifier to be applied to the terminal
         - Parameter annotations: Any annotations
        */
        init(_ terminal:Terminal, _ quantifier: Modifier? = nil,_ annotations:ElementAnnotations? = nil){
            self = .terminal(terminal, quantifier ?? .one, false, annotations ?? ElementAnnotations())
        }
        
        /**
         Creates a new instance of an element for an identifier
         
         - Paramerter identifier: The identifier
         - Parameter quantifier: Any quantifier to be applied to the terminal
         */
        init(_ identifier:Identifier, _ quantifier : Modifier? = nil){
            self = .identifier(identifier, quantifier ?? .one, false, ElementAnnotations())
        }
        
        /**
         Creates a new instance of an element for an group
         
         - Paramerter expression: The expression for the group
         - Parameter quantifier: Any quantifier to be applied to the terminal
         */
        init(_ expression:Expression, _ quantifier : Modifier? = nil){
            self = .group(expression, quantifier ?? .one, false, ElementAnnotations())
        }
        
        /**
         Changes the `Modifier` on the `Element` to be (or not be) lookahead
         
         - Parameter lookahead: `true` if this should be lookahead, `false` otherwise
        */
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
        
        /// Returns the annotations on the quantifier (rather than the element it is applied to)
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
        
        /// The annotations on the lement itself (rather than the quantifier)
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
        
        /// The quantifier on the element
        public var quantifier : Modifier {
            switch self {
            case .terminal(_, let q,_,_), .identifier(_, let q,_,_), .group(_, let q,_,_):
                return q
            }
        }
        
        /// A human readable description of the `Element`
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

        /// A `String` representing the `Element` in STLR
        public var stlrDescription: String{
            return "\(elementAnnotations.merge(with: quantifierAnnotations).stlrDescription) \(description)"
         }
        
        /// `true` if the `Element` can be represented using solely scanning rules. At the moment the only scanner rule is for one of multiple strings
        public var scannable : Bool {
            switch self {
            case .terminal(let terminal, let quantity, let lookahead,  let annotations) where quantity == .one && lookahead == false && annotations.isEmpty:
                return terminal.string != nil
            default: return false
            }
        }
        
        /**
         Evaluates if the supplied identifier is the first element in the `Expression`
         
         - Parameter identifier: The identifier being searched for
         - Parameter context: The STLR AST being evaluated in
         - Parameter searchState: The identifiers already searched (to avoid infinite recursion)
         - Returns: `true` if it is, false if it isn't
         */
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
        
        /**
         Evaluates if the supplied identifier is the referenced by the `Expression`
         
         - Parameter identifier: The identifier being searched for
         - Parameter context: The STLR AST being evaluated in
         - Parameter searchState: The identifiers already searched (to avoid infinite recursion)
         - Returns: `true` if it is, false if it isn't
         */
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
    /// Represents an identifier (a reference to, or definition of, a rule)
    public class Identifier : CustomStringConvertible, Hashable {
        /// The name of the identifier
        public let name            : String
        
        /// The identifier's raw `Int` value needed for its `Token`
        public var rawValue        : Int
        
        /// Any annotations on the `Identifier`
        public var annotations     : ElementAnnotations
        
        /// An index of locations in the STLR source where the identifier is referenced
        var references      = [Range<String.UnicodeScalarView.Index>]()
        
        /// The associated `GrammarRule`. Can be `nil` if the identifier is only referenced an never defined
        var grammarRule     : GrammarRule?

        /**
         Creates a new instance
         
         - Parameter name: The name of the identifier
         - Parameter rawValue: The value of the token created for the identifier
        */
        public init(name:String, rawValue:Int) {
            self.name = name
            self.rawValue = rawValue
            self.annotations = ElementAnnotations()
        }
        
        /// A string representing the identifier in STLR
        public var stlrReference : String {
            return "\(name)"
        }
        
        /// A human readable description
        public var description: String{
            return name
        }
        
        /// The hashing value of teh identifier
        public var hashValue: Int{
            return rawValue
        }
    }
    
    // MARK: -
    /// Annotations made on `Elements`
    public typealias ElementAnnotations = [ElementAnnotationInstance]
    
    /// An instance of an annotation
    public struct ElementAnnotationInstance : CustomStringConvertible{
        /// The annotation (e.g. Pinned)
        public let annotation : ElementAnnotation
        
        /// The value of the annotation
        public var value      : ElementAnnotationValue
        
        /// A human readable description of the annotation
        public var description: String{
            return "\(annotation)"+(value.description.isEmpty ? "" : "=\(value.description)")
        }
        
        /// The annotation expresed as in STLR
        var stlrDescription : String {
            return "@\(annotation)"+(value.description.isEmpty ? "" : "(\(value.description))")
        }
        
        /**
         Creates a new instance
         
         - Parameter annotation: The annotation
         - Parameter value: The value of the annotation
        */
        public init(_ annotation:ElementAnnotation, value: ElementAnnotationValue){
            self.annotation = annotation
            self.value = value
        }
        
        /**
         Creates a new instance of an annotation so it can be marked as `.set`
         
         - Parameter annotation: The annotation
        */
        public init(_ annotation:ElementAnnotation){
            self.annotation = annotation
            self.value = .set
        }
    }
    
    // MARK: -
    /// Captures the value of an annotation
    public enum ElementAnnotationValue : CustomStringConvertible {
        /// An integeger
        case int(Int)
        
        /// A boolean
        case bool(Bool)
        
        /// A string
        case string(String)
        
        /// Is set
        case set
        
        /// A human reabable description of the value
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
        
        /// The `RuleAnnotationValue` value of the AST representation
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
    /// An alias identifying the actual annotations as being just `RuleAnnotations`
    public typealias ElementAnnotation = RuleAnnotation
    
    // MARK: -
    /// Represents the different build in character sets that are provided in STLR
    public enum TerminalCharacterSet : CustomStringConvertible {
        /// White space characters
        case whitespaces
        /// New line characters
        case newlines
        /// Both white spaces and new lines
        case whitespacesAndNewlines
        /// All decimal digits
        case decimalDigits
        /// All characters from the Roman alphabet and all decimal digits
        case alphanumerics
        /// All characters from the Roman alphabet
        case letters
        /// All upper case Roman characters
        case uppercaseLetters
        /// All lower case Roman characters
        case lowercaseLetters
        /// A custom range
        case customRange(CharacterSet,start:UnicodeScalar,end:UnicodeScalar)
        /// A combination of mulitple sets
        case multipleSets([TerminalCharacterSet])
        /// A string where each character defines an element in the set
        case customString(String)
        
        /**
         Creates a new instance based on the supplied value
         
         - Parameter rawValue: The string captured during parsing
        */
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
        
        /**
         Creates a new instance base on a start and end character
         
         - Parameter from: The first character in the range
         - Parameter to: The last character in the range
        */
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
        
        /// The Foundation `CharacterSet` that represents this instance
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
        
        /// A human readable description
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
    /// Represents either a string or a character set and is called a Terminal because it cannot be further decomposed
    public struct Terminal : CustomStringConvertible{
        let string       : String?
        let characterSet : TerminalCharacterSet?
        
        private static func unescapeString(_ string:String)->String{
            return string.replacingOccurrences(of: "\\\"", with: "\"").replacingOccurrences(of: "\\\\", with: "\\")
        }
        
        /**
         Create a new instance with the supplied string
         
         - Parameter with: The string to use
        */
        public init(with string:String){
            self.string = Terminal.unescapeString(string)
            self.characterSet = nil
        }
        
        /**
         Create a new instance with the supplied character set
         
         - Parameter with: The character set to use
         */
        public init(with characterSet:TerminalCharacterSet){
            self.string = nil
            self.characterSet = characterSet
        }
        
        /// A human readable description
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
    /// The repsentation of a rule in the AST
    public class GrammarRule  : CustomStringConvertible{
        /// The identifier for the rule
        public var identifier : Identifier? = nil {
            didSet {
                if let id = identifier {
                    id.grammarRule = self
                }
            }
        }

        /// The rules location in the source STLR
        var location    : Range<String.UnicodeScalarView.Index>
        
        /// The expression the rule represents
        var _expression : Expression?
        
        /// The expression the rule represents, if called multiple times the expression is converted into a choice between those two and the values
        /// added by all subsequent calls
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
        
        /// The grammar the rule is in
        let grammar : STLRIntermediateRepresentation
        
        /**
         Creates a new instance
         
         - Parameter ast: The AST the rule is part of
         - Parameter range: The range of the rule in source STLR
        */
        init(_ ast:STLRIntermediateRepresentation, range:Range<String.UnicodeScalarView.Index>){
            grammar = ast
            location = range
        }
        
        /// A human readable description of the rule
        public var description: String{
            let annotationString : String
            
            if let annotations = identifier?.annotations, !annotations.isEmpty {
                annotationString = annotations.stlrDescription+" "
            } else {
                annotationString = ""
            }
            
            return "\(annotationString)\(identifier?.name ?? "**Unnamed**") = \(expression?.description ?? "**No expression**")".replacingOccurrences(of: "  ", with: " ")
        }
        
        /**
         Validates the rule looking for errors such as not having an identifier or missing the expression (never defined)
        */
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
        
        /**
         Evaluates if the supplied identifier is the first element in the rule
         
         - Parameter identifier: The identifier being searched for
         - Parameter context: The STLR AST being evaluated in
         - Parameter searchState: The identifiers already searched (to avoid infinite recursion)
         - Returns: `true` if it is, false if it isn't
         */
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
        
        /**
         Evaluates if the supplied identifier is referenced in the rule
         
         - Parameter identifier: The identifier being searched for
         - Parameter context: The STLR AST being evaluated in
         - Parameter searchState: The identifiers already searched (to avoid infinite recursion)
         - Returns: `true` if it is, false if it isn't
         */
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
        
        /// `true` if the rule is left hand recursive (the LHS is used in the RHS)
        public var leftHandRecursive : Bool {
            if let identifier = identifier {
                return references(identifier, context: grammar)
            }
            return false
        }
        
        /// `true` if the rule uses itself directly (rather than through an identifier in the rhs that eventually comes back to this rule)
        public var directLeftHandRecursive : Bool {
            if let identifier = identifier {
                return references(identifier, context: nil)
            }
            return false
        }
    }
    
    
    // MARK: -
    /// All of the rules is the grammar that are never referenced
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
    
    /// The `Token` value for the specified identifier
    public subscript(identifier name:String)->Int?{
        for (_,identifier) in identifiers{
            if name == identifier.name {
                return identifier.rawValue
            }
        }
        return nil
    }
    
    /// The name of the identifier for the specified `Token`
    public subscript(t:Token)->String?{
        for (_,identifier) in identifiers{
            if t.rawValue == identifier.rawValue {
                return identifier.name
            }
        }
        return nil
    }
    
    /// The name of the identifier for the specified `Token`'s raw value
    public subscript(i:Int)->String?{
        for (_,identifier) in identifiers{
            if i == identifier.rawValue {
                return identifier.name
            }
        }
        return nil
    }
    
    /// The parsed rules
    public var rules : [GrammarRule] = []
    
    /// The errrors generated during parsing
    public var errors = [Error]()
    
    /// The symbol table (identifiers and their representation in the AST
    public var identifiers : [String : STLRIntermediateRepresentation.Identifier] = [ : ]
    
    /// A human readable description of the AST
    public var description: String{
        var result = ""
        if errors.count > 0 {
            result += "Errors:\n\t"+errors.map({"\($0)"}).joined(separator: "\n\t")
        }
        
        result += "\nRules:\n\t"+rules.map({"\($0)"}).joined(separator: "\n\t")
        return result+"\n"
    }
    
    /// Creates a new instance of the AST
    public required init(){
        
    }
}

// MARK: -
/**
 An equality operator for two identifiers which checks only the names (not their expressions) are the same
 
 - Parameter lhs: The first identifier
 - Parameter rhs: The second identifier
 */
public func==(lhs:STLRIntermediateRepresentation.Identifier, rhs:STLRIntermediateRepresentation.Identifier)->Bool{
    return lhs.name == rhs.name && lhs.rawValue == rhs.rawValue
}

/// An extension to collection that contain instances of annotations
public extension Collection where Iterator.Element == STLRIntermediateRepresentation.ElementAnnotationInstance{
    
    /// The collection as `RuleAnnotations` usable directly by `Rule`
    public var asRuleAnnotations : RuleAnnotations {
        var ruleAnnotations = [RuleAnnotation : RuleAnnotationValue]()
        for entry in self {
            ruleAnnotations[entry.annotation] = entry.value.ruleValue
        }
        return ruleAnnotations
    }
    
    /// The annotations in STLR source form
    var stlrDescription : String {
        return self.map({
            "\($0.stlrDescription)"
        }).joined(separator: " ")
    }
    
    /**
     Determines if the given annotation is present in the collection
     
     - Parameter annotation: The annotation to look for
    */
    public func isSet(_ annotation:STLRIntermediateRepresentation.ElementAnnotation)->Bool{
        return self[annotation: annotation] != nil
    }
    
    /// The value for the given annotation
    public subscript(annotation key:STLRIntermediateRepresentation.ElementAnnotation)->STLRIntermediateRepresentation.ElementAnnotationValue?{
        for annotation in self {
            if annotation.annotation == key {
                return annotation.value
            }
        }
        
        return nil
    }
    
    /**
     Removes the annotation with the given key from the Collection and returns a new collection with the annotation removed
     
     - Parameter annotation: The annotation to remove
    */
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
    
    /**
     Merges the incoming annotations with the existing list. Incoming annotations override those already there
     
     - Parameter with: The annotations which should augment or override the existing annotations
     - Returns: The resultant `ElementAnnotations`
    */
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

/// Provides a utility initialiser to create a new instance of an annotation based on the supplied string
public extension STLRIntermediateRepresentation.ElementAnnotation{
    /**
     Creates a new instance based on the string captured during parsing
     
     - Parameter rawValue: A string captured during parsing
    */
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

