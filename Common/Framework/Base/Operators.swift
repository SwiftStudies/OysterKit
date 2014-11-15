/*
Copyright (c) 2014, RED When Excited
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/



import Foundation

//
// Creates a sequence from the first state to the last state, returning the first
// state
//
public func sequence(states:TokenizationState...)->TokenizationState{
    
    for i in 1..<states.count {
        states[i-1].branch(states[i])
    }
    
    return states[0]
}

//
// Token equality
//
// Tokens are considered equal if they have the same name and characters
//
public func == (left: Token, right: Token) -> Bool {
    return (left.name == right.name) && (left.characters == right.characters)
}
public func != (left: Token, right: Token) -> Bool {
    return !(left == right)
}
public func == (left: Array<Token>, right: Array<Token>) -> Bool {
    if left.count != right.count {
        return false
    }
    
    for i in 0..<left.count{
        if left[i] != right[i]{
            return false
        }
    }

    return true
}
public func != (left: Array<Token>, right: Array<Token>) -> Bool {
    return !(left == right)
}

