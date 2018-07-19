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

public enum Check {
    case ifFileExists(path:String)
    case ifEnvEquals(name:String,requiredValue:String)
    
    func isMet(in context:OperationContext)->Bool{
        switch self {
        case .ifFileExists(let path):
            return FileManager.default.fileExists(atPath: context.workingDirectory.appendingPathComponent(path).path)
        case .ifEnvEquals(let name, let requiredValue):
            return context.environment[name] ?? "" == requiredValue
            
        }
    }
    
    func then(_ metOperations:Operation, else unmetOperations:Operation? = nil)->Condition{
        return Condition(self, ifMet: metOperations, otherwise: unmetOperations ?? [])
    }
}



public struct Condition : Operation {
    let check : Check
    let metOperations : Operation
    let unmetOperations : Operation
    
    init(_ check:Check, ifMet metOperations:Operation, otherwise unmetOperations:Operation){
        self.check = check
        self.unmetOperations = unmetOperations
        self.metOperations = metOperations
    }
    
    func evaluate(in context:OperationContext)->Operation{
        return check.isMet(in: context) ? metOperations : unmetOperations
    }
    
    public func perform(in context: OperationContext) throws {
        try evaluate(in: context).perform(in: context)
    }

}
