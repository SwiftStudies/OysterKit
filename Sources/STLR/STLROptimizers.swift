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

/// A protocol that must be implemented by all optimizers (there are multiple different types)
/// - SeeAlso: `STLRExpressionOptimizer`
public protocol STLROptimizer : CustomStringConvertible{
    
}

/// A protocol that must be implemented by optimizers for expressions
public protocol STLRExpressionOptimizer : STLROptimizer{
    
    /**
     Should optimize the supplied expression, returning the optimized expression if optimization was possible
     
     - Parameter expression: The expression to optimize
     - Returns: An optimized expression or `nil` if the expression could not be optimized
    */
    func optimize(expression:STLRIntermediateRepresentation.Expression)->STLRIntermediateRepresentation.Expression?
}

private var optmizers = [STLROptimizer]()

/// Adds methods to register optimizers
public extension STLRIntermediateRepresentation{
    /**
     Registers a new optimizer. Optimizers are applied in the order they are registered
     
     - Parameter optimizer: The optimizer
    */
    public static func register(optimizer:STLROptimizer){
        optmizers.append(optimizer)
    }
    
    /// Removes all registered optimizers
    public static func removeAllOptimizations(){
        optmizers.removeAll()
    }
}

/// Adds a property to all `Expressions` that will returned the optimized form of the expression
extension STLRIntermediateRepresentation.Expression{
    
    /// The optimized form of the expression
    var optimize : STLRIntermediateRepresentation.Expression?{
        var optimizedForm : STLRIntermediateRepresentation.Expression?

        optmizers.flatMap({$0 as? STLRExpressionOptimizer}).forEach(){
            if let appliedOptimization = $0.optimize(expression: optimizedForm ?? self) {
                optimizedForm = appliedOptimization
            }
        }
        
        return optimizedForm
    }
    
}
