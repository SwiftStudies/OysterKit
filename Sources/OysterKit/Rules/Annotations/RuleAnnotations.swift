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

/// A dictionary of annotations and their values
public typealias RuleAnnotations = [RuleAnnotation : RuleAnnotationValue]

/// Compares two ``RuleAnnotations``
public func areEqual(lhs: RuleAnnotations, rhs: RuleAnnotations)->Bool{
    func areEqual(lhs:RuleAnnotationValue, rhs:RuleAnnotationValue)->Bool{
        return lhs.description == rhs.description
    }
    if lhs.count != rhs.count {
        return false
    }
    
    for tuple in lhs {
        guard let rhsValue = rhs[tuple.key] else {
            return false
        }
        if !areEqual(lhs: rhsValue, rhs: tuple.value) {
            return false
        }
    }
    
    return true
}

/// An extension for dictionaries of `RuleAnnotations`
public extension Collection where Iterator.Element == (key:RuleAnnotation,value:RuleAnnotationValue){
    
    /// Creates a new collection of RuleAnnotations where the merged annotations override those in
    /// this object
    /// - Parameter with: The annotations which will add to or override those already in the dictionary
    public func merge(with incoming:RuleAnnotations)->RuleAnnotations{
        var merged = self as! RuleAnnotations
        for annotation in incoming {
            merged[annotation.key] = annotation.value
        }
        
        return merged
    }
    
    /// A description in STLR format of the `RuleAnnotations`
    public var stlrDescription : String {
        var result = ""
        for tuple in self {
            result += "@\(tuple.0)"
            let value = tuple.1.description
            if !value.isEmpty {
                result+="(\(value))"
            }
        }
        
        return result
    }
}

//Adds the ability to quickly access standard annotations
public extension Dictionary where Key == RuleAnnotation, Value == RuleAnnotationValue {
    
    /// Any annotated error message, or nil if not set
    public var error : String? {
        if let error = self[.error] {
            if case let .string(message) = error {
                return message
            }
        }
        return nil
    }
    
    /// Any annotated error message, or nil if not set
    public var token : String? {
        if let token = self[.token] {
            if case let .string(label) = token {
                return label
            }
        }
        return nil
    }
    
    /// True if the annotations included the pinned annotation
    public var pinned : Bool {
        if let value = self[.pinned] {
            if case .set = value {
                return true
            }
        }
        return false
    }
    
    /// True if the annotations include the void annotation
    public var void : Bool {
        if let value = self[.void] {
            if case .set = value {
                return true
            }
        }
        return false
    }
    
    /// True if the annotations include the transient annotation
    public var transient : Bool {
        if let value = self[.transient] {
            if case .set = value {
                return true
            }
        }
        return false
    }
}
