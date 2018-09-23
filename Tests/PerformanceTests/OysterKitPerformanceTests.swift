//
//  OysterKitPerformanceTests.swift
//  OysterKitPerformanceTests
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import XCTest
import OysterKit
@testable import STLR
@testable import TestingSupport

class OysterKitPerformanceTests: XCTestCase {

    let swiftSource = """
//
// STLR Generated Swift File
//
// Generated: 2016-08-19 10:45:49 +0000
//
import OysterKit

//
// FullSwiftParser Parser
//
class FullSwiftParser : Parser{

    // Convenience alias
    private typealias GrammarToken = Tokens

    // TokenType & Rules Definition
    enum Tokens : Int, TokenType {
        case _transient, comment, ws, eol, access, scope, number, key, entry, dictionary, dictionary, array, string, variable, inherit, parameter, parameters, index, import, class, alias, enum, case, caseBlock, func, switch, return, reference, var, call, guard, assignment, block, statement, swift

        func _rule(_ annotations: RuleAnnotations = [ : ])->Rule {
            switch self {
            case ._transient:
                return CharacterSet(charactersIn: "").terminal(token: GrammarToken._transient)
            // comment
            case .comment:
                return [
                    "//".terminal(token: GrammarToken._transient),
                    CharacterSet.newlines.terminal(token: GrammarToken._transient).not(producing: GrammarToken._transient).repeated(min: 0, producing: GrammarToken._transient),
                    ].sequence(token: GrammarToken.comment)
            // ws
            case .ws:
                return [
                    GrammarToken.comment._rule(),
                    CharacterSet.whitespacesAndNewlines.terminal(token: GrammarToken._transient),
                    ].oneOf(token: GrammarToken.ws)
            // eol
            case .eol:
                return [
                    GrammarToken.comment._rule().optional(producing: GrammarToken._transient),
                    CharacterSet.newlines.terminal(token: GrammarToken._transient).not(producing: GrammarToken._transient).repeated(min: 0, producing: GrammarToken._transient),
                    CharacterSet.newlines.terminal(token: GrammarToken._transient).optional(producing: GrammarToken._transient),
                    ].sequence(token: GrammarToken.eol)
            // access
            case .access:
                return ScannerRule.oneOf(token: GrammarToken.access, ["static", "private", "fileprivate", "open", "internal", "public"])
            // scope
            case .scope:
                return [
                    GrammarToken.access._rule(),
                    [
                                    GrammarToken.ws._rule().repeated(min: 1, producing: GrammarToken._transient),
                                    GrammarToken.access._rule(),
                                    ].sequence(token: GrammarToken._transient).optional(producing: GrammarToken._transient),
                    ].sequence(token: GrammarToken.scope)
            // number
            case .number:
                return CharacterSet.decimalDigits.terminal(token: GrammarToken._transient).repeated(min: 1, producing: GrammarToken.number)
            // key
            case .key:
                return [
                    GrammarToken.string._rule(),
                    GrammarToken.number._rule(),
                    GrammarToken.variable._rule(),
                    ].oneOf(token: GrammarToken.key)
            // entry
            case .entry:
                guard let cachedRule = FullSwiftParser.leftHandRecursiveRules[self.rawValue] else {
                    // Create recursive shell
                    let recursiveRule = RecursiveRule()
                    FullSwiftParser.leftHandRecursiveRules[self.rawValue] = recursiveRule
                    // Create the rule we would normally generate
                    let rule = [
                                GrammarToken.key._rule().optional(producing: GrammarToken._transient),
                                GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                ":".terminal(token: GrammarToken._transient),
                                GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                GrammarToken.reference._rule().optional(producing: GrammarToken._transient),
                                ].sequence(token: GrammarToken.entry)
                    recursiveRule.surrogateRule = rule
                    return recursiveRule
                }
                return cachedRule
            // dictionary
            case .dictionary:
                guard let cachedRule = FullSwiftParser.leftHandRecursiveRules[self.rawValue] else {
                    // Create recursive shell
                    let recursiveRule = RecursiveRule()
                    FullSwiftParser.leftHandRecursiveRules[self.rawValue] = recursiveRule
                    // Create the rule we would normally generate
                    let rule = [
                    [
                                    "[".terminal(token: GrammarToken._transient),
                                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                    GrammarToken.entry._rule(),
                                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                    "]".terminal(token: GrammarToken._transient),
                                    ].sequence(token: GrammarToken._transient),
                    [
                                    "[".terminal(token: GrammarToken._transient),
                                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                    GrammarToken.entry._rule().optional(producing: GrammarToken._transient),
                                    [
                                                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                                    ",".terminal(token: GrammarToken._transient),
                                                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                                    GrammarToken.entry._rule(),
                                                    ].sequence(token: GrammarToken._transient).repeated(min: 0, producing: GrammarToken._transient),
                                    ",".terminal(token: GrammarToken._transient).optional(producing: GrammarToken._transient),
                                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                    "]".terminal(token: GrammarToken._transient),
                                    ].sequence(token: GrammarToken._transient),
                    ].oneOf(token: GrammarToken.dictionary)
                    recursiveRule.surrogateRule = rule
                    return recursiveRule
                }
                return cachedRule
            // dictionary
            case .dictionary:
                guard let cachedRule = FullSwiftParser.leftHandRecursiveRules[self.rawValue] else {
                    // Create recursive shell
                    let recursiveRule = RecursiveRule()
                    FullSwiftParser.leftHandRecursiveRules[self.rawValue] = recursiveRule
                    // Create the rule we would normally generate
                    let rule = [
                    [
                                    "[".terminal(token: GrammarToken._transient),
                                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                    GrammarToken.entry._rule(),
                                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                    "]".terminal(token: GrammarToken._transient),
                                    ].sequence(token: GrammarToken._transient),
                    [
                                    "[".terminal(token: GrammarToken._transient),
                                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                    GrammarToken.entry._rule().optional(producing: GrammarToken._transient),
                                    [
                                                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                                    ",".terminal(token: GrammarToken._transient),
                                                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                                    GrammarToken.entry._rule(),
                                                    ].sequence(token: GrammarToken._transient).repeated(min: 0, producing: GrammarToken._transient),
                                    ",".terminal(token: GrammarToken._transient).optional(producing: GrammarToken._transient),
                                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                    "]".terminal(token: GrammarToken._transient),
                                    ].sequence(token: GrammarToken._transient),
                    ].oneOf(token: GrammarToken.dictionary)
                    recursiveRule.surrogateRule = rule
                    return recursiveRule
                }
                return cachedRule
            // array
            case .array:
                guard let cachedRule = FullSwiftParser.leftHandRecursiveRules[self.rawValue] else {
                    // Create recursive shell
                    let recursiveRule = RecursiveRule()
                    FullSwiftParser.leftHandRecursiveRules[self.rawValue] = recursiveRule
                    // Create the rule we would normally generate
                    let rule = [
                    "[".terminal(token: GrammarToken._transient),
                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                    [
                                    GrammarToken.reference._rule(),
                                    [
                                                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                                    ",".terminal(token: GrammarToken._transient),
                                                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                                    GrammarToken.reference._rule(),
                                                    ].sequence(token: GrammarToken._transient).repeated(min: 0, producing: GrammarToken._transient),
                                    ",".terminal(token: GrammarToken._transient).optional(producing: GrammarToken._transient),
                                    ].sequence(token: GrammarToken._transient).optional(producing: GrammarToken._transient),
                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                    "]".terminal(token: GrammarToken._transient),
                    ].sequence(token: GrammarToken.array)
                    recursiveRule.surrogateRule = rule
                    return recursiveRule
                }
                return cachedRule
            // string
            case .string:
                return [
                    "\"".terminal(token: GrammarToken._transient),
                    [
                                    [
                                                    "\\".terminal(token: GrammarToken._transient),
                                                    CharacterSet(charactersIn: "\"\\").terminal(token: GrammarToken._transient),
                                                    ].sequence(token: GrammarToken._transient),
                                    "\"".terminal(token: GrammarToken._transient).not(producing: GrammarToken._transient),
                                    ].oneOf(token: GrammarToken._transient).repeated(min: 0, producing: GrammarToken._transient),
                    "\"".terminal(token: GrammarToken._transient),
                    ].sequence(token: GrammarToken.string)
            // variable
            case .variable:
                return [
                    CharacterSet.letters.union(CharacterSet(charactersIn: "_")).terminal(token: GrammarToken._transient),
                    CharacterSet.letters.union(CharacterSet.decimalDigits).union(CharacterSet(charactersIn: "_")).terminal(token: GrammarToken._transient).repeated(min: 0, producing: GrammarToken._transient),
                    ].sequence(token: GrammarToken.variable)
            // inherit
            case .inherit:
                return [
                    ":".terminal(token: GrammarToken._transient),
                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                    GrammarToken.variable._rule(),
                    [
                                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                    ",".terminal(token: GrammarToken._transient),
                                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                    GrammarToken.variable._rule(),
                                    ].sequence(token: GrammarToken._transient).repeated(min: 0, producing: GrammarToken._transient),
                    ].sequence(token: GrammarToken.inherit)
            // parameter
            case .parameter:
                guard let cachedRule = FullSwiftParser.leftHandRecursiveRules[self.rawValue] else {
                    // Create recursive shell
                    let recursiveRule = RecursiveRule()
                    FullSwiftParser.leftHandRecursiveRules[self.rawValue] = recursiveRule
                    // Create the rule we would normally generate
                    let rule = [
                    [
                                    [
                                                    [
                                                                    GrammarToken.variable._rule(),
                                                                    GrammarToken.ws._rule().repeated(min: 1, producing: GrammarToken._transient),
                                                                    GrammarToken.variable._rule().optional(producing: GrammarToken._transient),
                                                                    ].sequence(token: GrammarToken._transient),
                                                    [
                                                                    "_".terminal(token: GrammarToken._transient),
                                                                    GrammarToken.variable._rule(),
                                                                    GrammarToken.ws._rule().repeated(min: 1, producing: GrammarToken._transient),
                                                                    GrammarToken.variable._rule(),
                                                                    ].sequence(token: GrammarToken._transient),
                                                    GrammarToken.variable._rule(),
                                                    ].oneOf(token: GrammarToken._transient),
                                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                    ":".terminal(token: GrammarToken._transient),
                                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                    ].sequence(token: GrammarToken._transient).optional(producing: GrammarToken._transient),
                    GrammarToken.reference._rule(),
                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                    [
                                    "=".terminal(token: GrammarToken._transient),
                                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                    [
                                                    GrammarToken.variable._rule(),
                                                    GrammarToken.dictionary._rule(),
                                                    ].oneOf(token: GrammarToken._transient),
                                    ].sequence(token: GrammarToken._transient).optional(producing: GrammarToken._transient),
                    ].sequence(token: GrammarToken.parameter)
                    recursiveRule.surrogateRule = rule
                    return recursiveRule
                }
                return cachedRule
            // parameters
            case .parameters:
                guard let cachedRule = FullSwiftParser.leftHandRecursiveRules[self.rawValue] else {
                    // Create recursive shell
                    let recursiveRule = RecursiveRule()
                    FullSwiftParser.leftHandRecursiveRules[self.rawValue] = recursiveRule
                    // Create the rule we would normally generate
                    let rule = [
                    "(".terminal(token: GrammarToken._transient),
                    [
                                    GrammarToken.parameter._rule(),
                                    [
                                                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                                    ",".terminal(token: GrammarToken._transient),
                                                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                                    GrammarToken.parameter._rule(),
                                                    ].sequence(token: GrammarToken._transient).repeated(min: 0, producing: GrammarToken._transient),
                                    ].sequence(token: GrammarToken._transient).optional(producing: GrammarToken._transient),
                    ")".terminal(token: GrammarToken._transient),
                    ].sequence(token: GrammarToken.parameters)
                    recursiveRule.surrogateRule = rule
                    return recursiveRule
                }
                return cachedRule
            // index
            case .index:
                guard let cachedRule = FullSwiftParser.leftHandRecursiveRules[self.rawValue] else {
                    // Create recursive shell
                    let recursiveRule = RecursiveRule()
                    FullSwiftParser.leftHandRecursiveRules[self.rawValue] = recursiveRule
                    // Create the rule we would normally generate
                    let rule = [
                    "[".terminal(token: GrammarToken._transient),
                    GrammarToken.reference._rule(),
                    "]".terminal(token: GrammarToken._transient),
                    ].sequence(token: GrammarToken.index)
                    recursiveRule.surrogateRule = rule
                    return recursiveRule
                }
                return cachedRule
            // import
            case .import:
                return [
                    "import".terminal(token: GrammarToken._transient),
                    GrammarToken.ws._rule().repeated(min: 1, producing: GrammarToken._transient),
                    GrammarToken.variable._rule(),
                    GrammarToken.eol._rule(),
                    ].sequence(token: GrammarToken.import)
            // class
            case .class:
                guard let cachedRule = FullSwiftParser.leftHandRecursiveRules[self.rawValue] else {
                    // Create recursive shell
                    let recursiveRule = RecursiveRule()
                    FullSwiftParser.leftHandRecursiveRules[self.rawValue] = recursiveRule
                    // Create the rule we would normally generate
                    let rule = [
                    GrammarToken.scope._rule().optional(producing: GrammarToken._transient),
                    "class".terminal(token: GrammarToken._transient),
                    GrammarToken.ws._rule().repeated(min: 1, producing: GrammarToken._transient),
                    GrammarToken.variable._rule(),
                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                    GrammarToken.inherit._rule(),
                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                    GrammarToken.block._rule(),
                    ].sequence(token: GrammarToken.class)
                    recursiveRule.surrogateRule = rule
                    return recursiveRule
                }
                return cachedRule
            // alias
            case .alias:
                return [
                    [
                                    GrammarToken.scope._rule(),
                                    GrammarToken.ws._rule().repeated(min: 1, producing: GrammarToken._transient),
                                    ].sequence(token: GrammarToken._transient).optional(producing: GrammarToken._transient),
                    "typealias".terminal(token: GrammarToken._transient),
                    GrammarToken.ws._rule().repeated(min: 1, producing: GrammarToken._transient),
                    GrammarToken.variable._rule(),
                    GrammarToken.ws._rule().repeated(min: 1, producing: GrammarToken._transient),
                    "=".terminal(token: GrammarToken._transient),
                    GrammarToken.ws._rule().repeated(min: 1, producing: GrammarToken._transient),
                    GrammarToken.variable._rule(),
                    GrammarToken.eol._rule(),
                    ].sequence(token: GrammarToken.alias)
            // enum
            case .enum:
                guard let cachedRule = FullSwiftParser.leftHandRecursiveRules[self.rawValue] else {
                    // Create recursive shell
                    let recursiveRule = RecursiveRule()
                    FullSwiftParser.leftHandRecursiveRules[self.rawValue] = recursiveRule
                    // Create the rule we would normally generate
                    let rule = [
                    [
                                    GrammarToken.scope._rule(),
                                    GrammarToken.ws._rule().repeated(min: 1, producing: GrammarToken._transient),
                                    ].sequence(token: GrammarToken._transient).optional(producing: GrammarToken._transient),
                    "enum".terminal(token: GrammarToken._transient),
                    GrammarToken.ws._rule().repeated(min: 1, producing: GrammarToken._transient),
                    GrammarToken.variable._rule(),
                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                    GrammarToken.inherit._rule().optional(producing: GrammarToken._transient),
                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                    GrammarToken.block._rule(),
                    ].sequence(token: GrammarToken.enum)
                    recursiveRule.surrogateRule = rule
                    return recursiveRule
                }
                return cachedRule
            // case
            case .case:
                return [
                    "case".terminal(token: GrammarToken._transient),
                    GrammarToken.ws._rule().repeated(min: 1, producing: GrammarToken._transient),
                    GrammarToken.variable._rule(),
                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                    [
                                    ",".terminal(token: GrammarToken._transient),
                                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                    GrammarToken.variable._rule(),
                                    ].sequence(token: GrammarToken._transient).repeated(min: 0, producing: GrammarToken._transient),
                    ].sequence(token: GrammarToken.case)
            // caseBlock
            case .caseBlock:
                return [
                    [
                                    [
                                                    "case".terminal(token: GrammarToken._transient),
                                                    GrammarToken.ws._rule().repeated(min: 1, producing: GrammarToken._transient),
                                                    ".".terminal(token: GrammarToken._transient),
                                                    GrammarToken.variable._rule(),
                                                    [
                                                                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                                                    ",".terminal(token: GrammarToken._transient),
                                                                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                                                    ".".terminal(token: GrammarToken._transient),
                                                                    GrammarToken.variable._rule(),
                                                                    ].sequence(token: GrammarToken._transient).repeated(min: 0, producing: GrammarToken._transient),
                                                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                                    ].sequence(token: GrammarToken._transient),
                                    "default".terminal(token: GrammarToken._transient),
                                    ].oneOf(token: GrammarToken._transient),
                    ":".terminal(token: GrammarToken._transient),
                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                    ].sequence(token: GrammarToken.caseBlock)
            // func
            case .func:
                guard let cachedRule = FullSwiftParser.leftHandRecursiveRules[self.rawValue] else {
                    // Create recursive shell
                    let recursiveRule = RecursiveRule()
                    FullSwiftParser.leftHandRecursiveRules[self.rawValue] = recursiveRule
                    // Create the rule we would normally generate
                    let rule = [
                    GrammarToken.scope._rule().optional(producing: GrammarToken._transient),
                    [
                                    [
                                                    "func".terminal(token: GrammarToken._transient),
                                                    GrammarToken.ws._rule().repeated(min: 1, producing: GrammarToken._transient),
                                                    GrammarToken.variable._rule(),
                                                    ].sequence(token: GrammarToken._transient),
                                    "init".terminal(token: GrammarToken._transient),
                                    ].oneOf(token: GrammarToken._transient),
                    GrammarToken.parameters._rule(),
                    [
                                    "->".terminal(token: GrammarToken._transient),
                                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                    GrammarToken.variable._rule(),
                                    "?".terminal(token: GrammarToken._transient).optional(producing: GrammarToken._transient),
                                    ].sequence(token: GrammarToken._transient).optional(producing: GrammarToken._transient),
                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                    GrammarToken.block._rule(),
                    ].sequence(token: GrammarToken.func)
                    recursiveRule.surrogateRule = rule
                    return recursiveRule
                }
                return cachedRule
            // switch
            case .switch:
                guard let cachedRule = FullSwiftParser.leftHandRecursiveRules[self.rawValue] else {
                    // Create recursive shell
                    let recursiveRule = RecursiveRule()
                    FullSwiftParser.leftHandRecursiveRules[self.rawValue] = recursiveRule
                    // Create the rule we would normally generate
                    let rule = [
                    "switch".terminal(token: GrammarToken._transient),
                    GrammarToken.ws._rule().repeated(min: 1, producing: GrammarToken._transient),
                    GrammarToken.variable._rule(),
                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                    GrammarToken.block._rule(),
                    ].sequence(token: GrammarToken.switch)
                    recursiveRule.surrogateRule = rule
                    return recursiveRule
                }
                return cachedRule
            // return
            case .return:
                return [
                    "return".terminal(token: GrammarToken._transient),
                    GrammarToken.ws._rule().repeated(min: 1, producing: GrammarToken._transient),
                    GrammarToken.reference._rule(),
                    ].sequence(token: GrammarToken.return)
            // reference
            case .reference:
                guard let cachedRule = FullSwiftParser.leftHandRecursiveRules[self.rawValue] else {
                    // Create recursive shell
                    let recursiveRule = RecursiveRule()
                    FullSwiftParser.leftHandRecursiveRules[self.rawValue] = recursiveRule
                    // Create the rule we would normally generate
                    let rule = [
                    [
                                    GrammarToken.call._rule(),
                                    [
                                                    GrammarToken.variable._rule(),
                                                    GrammarToken.index._rule().optional(producing: GrammarToken._transient),
                                                    ].sequence(token: GrammarToken._transient),
                                    GrammarToken.string._rule(),
                                    GrammarToken.array._rule(),
                                    GrammarToken.number._rule(),
                                    GrammarToken.dictionary._rule(),
                                    ].oneOf(token: GrammarToken._transient),
                    [
                                    ".".terminal(token: GrammarToken._transient),
                                    GrammarToken.reference._rule(),
                                    ].sequence(token: GrammarToken._transient).optional(producing: GrammarToken._transient),
                    "!".terminal(token: GrammarToken._transient).optional(producing: GrammarToken._transient),
                    ].sequence(token: GrammarToken.reference)
                    recursiveRule.surrogateRule = rule
                    return recursiveRule
                }
                return cachedRule
            // var
            case .var:
                guard let cachedRule = FullSwiftParser.leftHandRecursiveRules[self.rawValue] else {
                    // Create recursive shell
                    let recursiveRule = RecursiveRule()
                    FullSwiftParser.leftHandRecursiveRules[self.rawValue] = recursiveRule
                    // Create the rule we would normally generate
                    let rule = [
                    [
                                    GrammarToken.scope._rule(),
                                    GrammarToken.ws._rule().repeated(min: 1, producing: GrammarToken._transient),
                                    ].sequence(token: GrammarToken._transient).optional(producing: GrammarToken._transient),
                    ScannerRule.oneOf(token: GrammarToken._transient, ["var", "let"]),
                    GrammarToken.ws._rule().repeated(min: 1, producing: GrammarToken._transient),
                    GrammarToken.variable._rule(),
                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                    [
                                    [
                                                    ":".terminal(token: GrammarToken._transient),
                                                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                                    GrammarToken.variable._rule(),
                                                    "?".terminal(token: GrammarToken._transient),
                                                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                                    GrammarToken.block._rule().optional(producing: GrammarToken._transient),
                                                    ].sequence(token: GrammarToken._transient),
                                    [
                                                    "=".terminal(token: GrammarToken._transient),
                                                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                                                    GrammarToken.reference._rule(),
                                                    ].sequence(token: GrammarToken._transient),
                                    ].oneOf(token: GrammarToken._transient),
                    ].sequence(token: GrammarToken.var)
                    recursiveRule.surrogateRule = rule
                    return recursiveRule
                }
                return cachedRule
            // call
            case .call:
                guard let cachedRule = FullSwiftParser.leftHandRecursiveRules[self.rawValue] else {
                    // Create recursive shell
                    let recursiveRule = RecursiveRule()
                    FullSwiftParser.leftHandRecursiveRules[self.rawValue] = recursiveRule
                    // Create the rule we would normally generate
                    let rule = [
                    [
                                    "#".terminal(token: GrammarToken._transient).optional(producing: GrammarToken._transient),
                                    GrammarToken.variable._rule(),
                                    [
                                                    ".".terminal(token: GrammarToken._transient),
                                                    GrammarToken.variable._rule(),
                                                    ].sequence(token: GrammarToken._transient).repeated(min: 0, producing: GrammarToken._transient),
                                    ].sequence(token: GrammarToken._transient).optional(producing: GrammarToken._transient),
                    GrammarToken.parameters._rule(),
                    ].sequence(token: GrammarToken.call)
                    recursiveRule.surrogateRule = rule
                    return recursiveRule
                }
                return cachedRule
            // guard
            case .guard:
                guard let cachedRule = FullSwiftParser.leftHandRecursiveRules[self.rawValue] else {
                    // Create recursive shell
                    let recursiveRule = RecursiveRule()
                    FullSwiftParser.leftHandRecursiveRules[self.rawValue] = recursiveRule
                    // Create the rule we would normally generate
                    let rule = [
                    "guard".terminal(token: GrammarToken._transient),
                    GrammarToken.ws._rule().repeated(min: 1, producing: GrammarToken._transient),
                    GrammarToken.var._rule(),
                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                    "else".terminal(token: GrammarToken._transient),
                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                    GrammarToken.block._rule(),
                    ].sequence(token: GrammarToken.guard)
                    recursiveRule.surrogateRule = rule
                    return recursiveRule
                }
                return cachedRule
            // assignment
            case .assignment:
                return [
                    GrammarToken.reference._rule(),
                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                    "=".terminal(token: GrammarToken._transient),
                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                    GrammarToken.reference._rule(),
                    ].sequence(token: GrammarToken.assignment)
            // block
            case .block:
                guard let cachedRule = FullSwiftParser.leftHandRecursiveRules[self.rawValue] else {
                    // Create recursive shell
                    let recursiveRule = RecursiveRule()
                    FullSwiftParser.leftHandRecursiveRules[self.rawValue] = recursiveRule
                    // Create the rule we would normally generate
                    let rule = [
                    "{".terminal(token: GrammarToken._transient),
                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                    GrammarToken.statement._rule().repeated(min: 0, producing: GrammarToken._transient),
                    GrammarToken.ws._rule().repeated(min: 0, producing: GrammarToken._transient),
                    "}".terminal(token: GrammarToken._transient),
                    ].sequence(token: GrammarToken.block)
                    recursiveRule.surrogateRule = rule
                    return recursiveRule
                }
                return cachedRule
            // statement
            case .statement:
                guard let cachedRule = FullSwiftParser.leftHandRecursiveRules[self.rawValue] else {
                    // Create recursive shell
                    let recursiveRule = RecursiveRule()
                    FullSwiftParser.leftHandRecursiveRules[self.rawValue] = recursiveRule
                    // Create the rule we would normally generate
                    let rule = [
                    GrammarToken.import._rule(),
                    GrammarToken.ws._rule().repeated(min: 1, producing: GrammarToken._transient),
                    GrammarToken.class._rule(),
                    GrammarToken.enum._rule(),
                    GrammarToken.var._rule(),
                    GrammarToken.case._rule(),
                    GrammarToken.caseBlock._rule(),
                    GrammarToken.func._rule(),
                    GrammarToken.switch._rule(),
                    GrammarToken.return._rule(),
                    GrammarToken.alias._rule(),
                    GrammarToken.call._rule(),
                    GrammarToken.guard._rule(),
                    GrammarToken.assignment._rule(),
                    ].oneOf(token: GrammarToken.statement)
                    recursiveRule.surrogateRule = rule
                    return recursiveRule
                }
                return cachedRule
            // swift
            case .swift:
                return [
                                GrammarToken.ws._rule(),
                                GrammarToken.statement._rule(),
                                ].oneOf(token: GrammarToken._transient).repeated(min: 0, producing: GrammarToken.swift)
            }
        }

        // Color Definitions
        fileprivate var color : NSColor? {
            switch self {
            case .comment:    return #colorLiteral(red:0.11457, green:0.506016, blue:0.128891, alpha: 1)
            case .scope:    return #colorLiteral(red:0.207304, green:0.362127, blue:0.401488, alpha: 1)
            case .number:    return #colorLiteral(red:0.0, green:0.589801, blue:1.0, alpha: 1)
            case .string:    return #colorLiteral(red:0.815686, green:0.129412, blue:0.12549, alpha: 1)
            case .variable:    return #colorLiteral(red:0.309804, green:0.541176, blue:0.6, alpha: 1)
            default:    return nil
            }
        }

    }

    // Color Dictionary
    static var colors = ["comment" : GrammarToken.comment.color!, "scope" : GrammarToken.scope.color!, "number" : GrammarToken.number.color!, "string" : GrammarToken.string.color!, "variable" : GrammarToken.variable.color!]

    // Cache for left-hand recursive rules
    private static var leftHandRecursiveRules = [ Int : Rule ]()

    // Initialize the parser with the base rule set
    init(){
        super.init(grammar: [GrammarToken.swift._rule()])
    }
}
"""

    /// If I'm going to reparse this STLR with rules it has dynamically generated... I'm going to need to remove the grammar declaration
    /// STLR 0.0.7 didn't support it
    var stlrSource007 : String {
        return stlrSource.replacingOccurrences(of: "grammar STLR", with: "")
    }
    
    let stlrSource = """
        /************************************************************

                    Swift Tool for Language Recognition (STLR)

        STLR can be fully described itself, and this example is
        provided to both provide  a formal document capturing STLR
        and to illustrate a complex use of the format.

        Change log:
            v0.0.0    8  Aug 2016     Initial version
            v0.0.1    15 Aug 2016        Added annotations changed to
                                    remove semi-colons and use
                                    " not '
            v0.0.2    16 Aug 2016        Added look ahead
            v0.0.3    17 Aug 2016        Added errors to grammar
            v0.0.4    18 Aug 2016        Changed the format of annotations
                                    to be more Swift like
            v0.0.5    22 Aug 2016     Added support for nested multiline
                                    comments
            v0.0.6     24 Aug 2016        Changed position of negation
                                    operator to better match Swift and
                                    added more error information.
            v0.0.7  10 Sep 2017        Added module importing

        *************************************************************/

        grammar STLR

        //
        // Whitespace
        //
        singleLineComment        = "//" !.newline* .newline
        multilineComment        = "/*" (multilineComment | !"*/")* "*/"
        comment                    = singleLineComment | multilineComment
        @void
        whitespace                 = comment | .whitespaceOrNewline
        ows                        = whitespace*

        //
        // Constants
        //
        //definition            = "const"    ows identifier ows "=" ows literal .whitespace* whitespace

        //
        // Quantifiers, does this still work?
        //
        quantifier                = "*" | "+" | "?" | "-"
        negated                   = "!"
        transient                 = "-"

        //
        // Parsing Control
        //
        lookahead                = ">>"

        //
        // String
        //
        stringQuote                = "\\""
        escapedCharacters         = stringQuote | "r" | "n" | "t" | .backslash
        escapedCharacter         = .backslash escapedCharacters
        @void
        stringCharacter         = escapedCharacter | !(stringQuote | .newline)
        terminalBody            = stringCharacter+
        stringBody                = stringCharacter*
        string                    = stringQuote
                                    stringBody
                                  @error("Missing terminating quote")
                                  stringQuote
        terminalString            = stringQuote
                                      @error("Terminals must have at least one character")
                                    terminalBody
                                  @error("Missing terminating quote")
                                  stringQuote

        //
        // Character Sets and Ranges
        //
        characterSetName        = "letter" |
                                  "uppercaseLetter" |
                                  "lowercaseLetter" |
                                  "alphaNumeric" |
                                  "decimalDigit" |
                                  "whitespaceOrNewline" |
                                  "whitespace" |
                                  "newline"
        characterSet            = ("." @error("Unknown character set") characterSetName)

        rangeOperator            = "." @error("Expected ... in character range") ".."
        characterRange            = terminalString rangeOperator @error("Range must be terminated") terminalString

        //
        // Types
        //
        number                     = ("-" | "+")? .decimalDigit+
        boolean                 = "true" | "false"
        literal                    = string | number | boolean

        //
        // Annotations
        //
        annotation              = "@"
                                    @error("Expected an annotation label") label (
                                        "("
                                        @error("A value must be specified or the () omitted")
                                        literal
                                        @error("Missing ')'")
                                        ")"
                                    )?
        annotations             = (annotation ows)+

        customLabel              = @error("Labels must start with a letter or _") (.letter | "_") ( .letter | .decimalDigit | "_" )*
        definedLabel             = "token" | "error" | "void" | "transient"
        label                     = definedLabel | customLabel


        //
        // Element
        //
        terminal                 = characterSet | characterRange | terminalString
        group                    = "(" whitespace*
                                    expression whitespace*
                                    @error("Expected ')'")
                                   ")"
        identifier                 = (.letter | "_") ( .letter | .decimalDigit | "_" )*

        element                 = annotations? (lookahead | transient)? negated? ( group | terminal | identifier ) quantifier?

        //
        // Expressions
        //
        assignmentOperators        = "=" | "+=" | "|="
        @void
        or                         =  whitespace* "|" whitespace*
        @void
        then                     = (whitespace* "+" whitespace*) | whitespace+

        choice                    = element (or @error("Expected terminal, identifier, or group") element)+
        notNewRule                = !(annotations? identifier whitespace* assignmentOperators)
        sequence                = element (then >>notNewRule @error("Expected terminal, identifier, or group")element)+

        expression                 = choice | sequence | element

        //
        // Rule
        //
        @transient
        lhs                        = whitespace* annotations? transient? identifier whitespace* assignmentOperators
        rule                     = lhs whitespace* @error("Expected expression")expression whitespace*

        //
        // Importing
        //
        moduleName                = (.letter | "_") (.letter | "_" | .decimalDigit)*
        moduleImport            = whitespace* @token("import") "import" .whitespace+  moduleName .whitespace+
        //
        // Grammar
        //
     

        //NB: Mark is there to ensure there is no automatic reduction of rule into grammar if there is only one rule, this should perhaps become an annotation
        grammar                     = @token("mark") >>(!" "|" ") moduleImport* @error("Expected at least one rule") rule+
    """
//    */

    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPerformanceOfScanString() {
        let sourceLength = 100000
        
        var source = ""
        
        for _ in 0..<sourceLength {
            source += "Hello world"
        }
        
        var scanCount = 0
        
        // This is an example of a performance test case.
        self.measure {
            let lexer = Lexer(source: source)
            scanCount = 0
            do {
                while scanCount < sourceLength{
                    try lexer.scan(terminal: "Hello world")
                    scanCount += 1
                }
                
                
                XCTAssert(lexer.endOfInput, "Expected to be at end of input")
            } catch {
                XCTFail("Scan should not throw \(scanCount)")
            }
        }
    }
    
    
    func testPerformanceOfScanCharacterInSet() {
        let sourceLength = 500000
        let source = String(repeating: "a", count: sourceLength)
        
        let characterSet = CharacterSet(charactersIn: "a")
        var scanCount = 0
        
        // This is an example of a performance test case.
        self.measure {
            let lexer = Lexer(source: source)
            scanCount = 0
            do {
                while scanCount < sourceLength{
                    try lexer.scan(oneOf: characterSet)
                    scanCount += 1
                }
                
                
                XCTAssert(lexer.endOfInput, "Expected to be at end of input")
            } catch {
                XCTFail("Scan should not throw \(scanCount)")
            }
        }
    }

    func testPerformanceSTLR() {
        do {
            _ = try ProductionSTLR.build(stlrSource).grammar.dynamicRules
        } catch {
            XCTFail("Could not compile \(error)")
            return
        }
        
        // This is an example of a performance test case.
        self.measure {
            let stlr = try! ProductionSTLR.build(self.stlrSource)
            
            XCTAssertEqual(45, stlr.grammar.rules.count)
            
            for rule in stlr.grammar.rules {
                do {
                    try stlr.grammar.validate(rule: rule)
                } catch {
                    XCTFail("Could not validate \(rule.identifier): \(error)")
                }
            }
        }
    }
    
    fileprivate final class NullIR : IntermediateRepresentation{
        func evaluating(_ token: TokenType) {
        }
        
        func succeeded(token: TokenType, annotations: RuleAnnotations, range: Range<String.Index>) {
        }
        
        func failed() {
        }
        

        fileprivate func willBuildFrom(source: String, with: Grammar) {
            
        }
        
        fileprivate func didBuild() {
            
        }
        
        func resetState() {
            
        }
    }
    
    func testSwiftParserPerformance(){
        let parser = SwiftParser()
        let _ = try? AbstractSyntaxTreeConstructor().build(swiftSource, using: parser.grammar)
        
        self.measure {
            let _ = try? AbstractSyntaxTreeConstructor().build(swiftSource, using: parser.grammar)
        }
        
    }
    
    func testPerformanceSTLRParseOnly() {
        let parser : Grammar
        do {
            parser = try ProductionSTLR.build(stlrSource).grammar.dynamicRules
        } catch {
            XCTFail("Failed to compile: \(error)")
            return
        }
        
        // This is an example of a performance test case.
        self.measure {
            do {
                try parser.rules[0].match(with: Lexer(source:self.stlrSource007), for: NullIR())
            } catch (let error){
                XCTFail("Unexpected failure \(error)")
            }
        }
    }
}
