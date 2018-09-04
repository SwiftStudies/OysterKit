import Foundation
import OysterKit

/// Intermediate Representation of the grammar
internal enum AnnotationTestTokens : Int, TokenType, CaseIterable, Equatable {
    typealias T = AnnotationTestTokens
    // Cache for compiled regular expressions
    private static var regularExpressionCache = [String : NSRegularExpression]()
    
    /// Returns a pre-compiled pattern from the cache, or if not in the cache builds
    /// the pattern, caches and returns the regular expression
    ///
    /// - Parameter pattern: The pattern the should be built
    /// - Returns: A compiled version of the pattern
    ///
    private static func regularExpression(_ pattern:String)->NSRegularExpression{
        if let cached = regularExpressionCache[pattern] {
            return cached
        }
        do {
            let new = try NSRegularExpression(pattern: pattern, options: [])
            regularExpressionCache[pattern] = new
            return new
        } catch {
            fatalError("Failed to compile pattern /\(pattern)/\n\(error)")
        }
    }    
    /// The tokens defined by the grammar
    case `terminal`, `group`, `identifier`, `recursive`, `recursiveItem`, `normal`, `overrides`
    
    /// The rule for the token
    var rule : Rule {
        switch self {
            /// terminal
            case .terminal:
                return "term ".reference(.structural(token: self), annotations: [RuleAnnotation.custom(label:"terminal"):RuleAnnotationValue.bool(true)])
                            
            /// group
            case .group:
                return T.terminal.rule.reference(.structural(token: self), annotations: [RuleAnnotation.custom(label:"group"):RuleAnnotationValue.bool(true)])
                            
            /// identifier
            case .identifier:
                return T.terminal.rule.reference(.structural(token: self), annotations: [RuleAnnotation.custom(label:"identifier"):RuleAnnotationValue.bool(true)])
                            
            /// recursive
            case .recursive:
                guard let cachedRule = T.leftHandRecursiveRules[self.rawValue] else {
                    // Create recursive shell
                    let recursiveRule = RecursiveRule(stubFor: Behaviour(.structural(token: self), cardinality: Cardinality.one), with: [RuleAnnotation.custom(label:"recursive"):RuleAnnotationValue.bool(true)])
                    T.leftHandRecursiveRules[self.rawValue] = recursiveRule
                    // Create the rule we would normally generate
                    let rule = [    "recurse ",    T.recursiveItem.rule].sequence.reference(.structural(token: self), annotations: [RuleAnnotation.custom(label:"recursive"):RuleAnnotationValue.bool(true)])
                                        
                    recursiveRule.surrogateRule = rule
                    return recursiveRule
                }
                
                return cachedRule
            
            /// recursiveItem
            case .recursiveItem:
                guard let cachedRule = T.leftHandRecursiveRules[self.rawValue] else {
                    // Create recursive shell
                    let recursiveRule = RecursiveRule(stubFor: Behaviour(.structural(token: self), cardinality: Cardinality.one), with: [:])
                    T.leftHandRecursiveRules[self.rawValue] = recursiveRule
                    // Create the rule we would normally generate
                    let rule = T.recursive.rule.reference(.scanning)
                                        
                    recursiveRule.surrogateRule = rule
                    return recursiveRule
                }
                
                return cachedRule
            
            /// normal
            case .normal:
                return [    T.terminal.rule,    T.group.rule,    T.identifier.rule,    T.recursive.rule].sequence.reference(.structural(token: self))
                            
            /// overrides
            case .overrides:
                return [    T.terminal.rule.annotatedWith([RuleAnnotation.custom(label:"terminal"):RuleAnnotationValue.bool(false)]),    T.group.rule.annotatedWith([RuleAnnotation.custom(label:"group"):RuleAnnotationValue.bool(false)]),    T.identifier.rule.annotatedWith([RuleAnnotation.custom(label:"identifier"):RuleAnnotationValue.bool(false)]),    T.recursive.rule.annotatedWith([RuleAnnotation.custom(label:"recursive"):RuleAnnotationValue.bool(false)])].sequence.reference(.structural(token: self))
                            
        }
    }
    
    /// Cache for left-hand recursive rules
    private static var leftHandRecursiveRules = [ Int : Rule ]()
    
    /// Create a language that can be used for parsing etc
    public static var generatedRules: [Rule] {
        return [T.normal.rule, T.overrides.rule]
    }
}

public struct AnnotationTest : Codable {
    
    /// Group 
    public struct Group : Codable {
        public let terminal: Swift.String
    }
    
    /// Identifier 
    public struct Identifier : Codable {
        public let terminal: Swift.String
    }
    
    /// Normal 
    public struct Normal : Codable {
        public let group: Group
        public let identifier: Identifier
        public let recursive: Swift.String
        public let terminal: Swift.String
    }
    
    /// Overrides 
    public struct Overrides : Codable {
        public let group: Group
        public let identifier: Identifier
        public let recursive: Swift.String
        public let terminal: Swift.String
    }
    public let normal : Normal
    public let overrides : Overrides
    /**
     Parses the supplied string using the generated grammar into a new instance of
     the generated data structure
    
     - Parameter source: The string to parse
     - Returns: A new instance of the data-structure
     */
    public static func build(_ source : Swift.String) throws ->AnnotationTest{
        let root = HomogenousTree(with: StringToken("root"), matching: source, children: [try AbstractSyntaxTreeConstructor().build(source, using: AnnotationTest.generatedLanguage)])
        // print(root.description)
        return try ParsingDecoder().decode(AnnotationTest.self, using: root)
    }
    
    public static var generatedLanguage : Grammar {return AnnotationTestTokens.generatedRules}
}
