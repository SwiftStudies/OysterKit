/**
 * Copyright Vadim Eisenberg 2017
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Foundation

enum ReaderError: Error {
    case resourceNotFound
    case readFailed(Error)
    case convertToStringFailed
}

class Reader {
    init() {}
    
    func read(resource: String, ofType type: String) throws -> String {
        #if os(Linux)
            // copied from https://github.com/IBM-Swift/Bridging/blob/master/Sources/Bridging/FoundationAdapterLinux.swift
            //
            // Bundle(for:) is not yet implemented on Linux
            //TODO remove this ifdef once Bundle(for:) is implemented
            // issue https://bugs.swift.org/browse/SR-953
            // meanwhile return a Bundle whose resource path points to /Resources directory
            //     inside the resourcePath of Bundle.main (e.g. .build/debug/Resources)
            let bundle = Bundle(path: (Bundle.main.resourcePath ?? ".") + "/Resources") ?? Bundle.main
        #else
            let bundle = Bundle(for: Swift.type(of: self))
        #endif
        // uncomment the following lines to print the directory
        // the resource files are expected to be located
        //print(bundle.resourcePath ?? "no resource path provided")
        
        guard let resourcePath = bundle.path(forResource: resource, ofType: type) else {
            throw ReaderError.resourceNotFound
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: resourcePath))
            guard let string = String(data: data, encoding: String.Encoding.utf8) else {
                throw ReaderError.convertToStringFailed
            }
            
            return string
        } catch {
            throw ReaderError.readFailed(error)
        }
    }
}
