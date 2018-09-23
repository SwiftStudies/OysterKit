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

import XCTest
@testable import OysterKit

class RuleAnnotationDescriptionTests: XCTestCase {

    var ruleDict: [RuleAnnotation: RuleAnnotationValue]?

    // MARK: - should sort standard entries

    func testStandardEntrySort() {
        ruleDict = [
            .token: .string("fooBar"),
            .error: .string("some error"),
            .void: .string("looks at you"),
            .transient: .set,
            .pinned: .int(56),
            .type: .bool(true)
        ]
        let desc = "@void(\"looks at you\") @transient @token(\"fooBar\") " +
                   "@pin(56) @type(true) @error(\"some error\")"
        XCTAssertEqual(desc, ruleDict?.description)
    }

    func testCustomEntryPushToBackSort() {
        ruleDict = [
            .custom(label: "foo"): .int(42),
            .token: .string("fooBar"),
            .error: .string("some error"),
            .void: .string("looks at you"),
            .transient: .set,
            .pinned: .int(33),
            .type: .bool(true)
        ]
        let desc = "@void(\"looks at you\") @transient @token(\"fooBar\") " +
        "@pin(33) @type(true) @error(\"some error\") @foo(42)"
        XCTAssertEqual(desc, ruleDict?.description)
    }

    func testAlphabeticalCustomEntrySort() {
        ruleDict = [
            .custom(label: "citrus"): .set,
            .custom(label: "animal"): .string("lion"),
            .custom(label: "bee"): .bool(true)
        ]
        let desc = "@animal(\"lion\") @bee(true) @citrus"
        XCTAssertEqual(desc, ruleDict?.description)
    }

    func testFewStandardAndMultipleCustomEntrySort() {
        ruleDict = [
            .custom(label: "pie"): .string("apple"),
            .custom(label: "eye"): .set,
            .custom(label: "like"): .bool(true),
            .token: .string("fooBar"),
            .void: .string("looks at you"),
            .pinned: .int(33)
        ]
        let desc = "@void(\"looks at you\") @token(\"fooBar\") @pin(33) " +
                   "@eye @like(true) @pie(\"apple\")"
        XCTAssertEqual(desc, ruleDict?.description)
    }

    // MARK: - @token tests
    
    func testTokenString() {
        ruleDict = [.token: .string("fooBar")]
        XCTAssertEqual("@token(\"fooBar\")", ruleDict?.description)
    }

    func testTokenInt() {
        ruleDict = [.token: .int(42)]
        XCTAssertEqual("@token(42)", ruleDict?.description)
    }

    func testTokenBool() {
        ruleDict = [.token: .bool(false)]
        XCTAssertEqual("@token(false)", ruleDict?.description)
    }

    func testTokenSet() {
        ruleDict = [.token: .set]
        XCTAssertEqual("@token", ruleDict?.description)
    }

    // MARK: - @error tests

    func testErrorString() {
        ruleDict = [.error: .string("fooBar")]
        XCTAssertEqual("@error(\"fooBar\")", ruleDict?.description)
    }

    func testErrorInt() {
        ruleDict = [.error: .int(42)]
        XCTAssertEqual("@error(42)", ruleDict?.description)
    }

    func testErrorBool() {
        ruleDict = [.error: .bool(false)]
        XCTAssertEqual("@error(false)", ruleDict?.description)
    }

    func testErrorSet() {
        ruleDict = [.error: .set]
        XCTAssertEqual("@error", ruleDict?.description)
    }

    // MARK: - @void tests

    func testVoidString() {
        ruleDict = [.void: .string("fooBar")]
        XCTAssertEqual("@void(\"fooBar\")", ruleDict?.description)
    }

    func testVoidInt() {
        ruleDict = [.void: .int(42)]
        XCTAssertEqual("@void(42)", ruleDict?.description)
    }

    func testVoidBool() {
        ruleDict = [.void: .bool(false)]
        XCTAssertEqual("@void(false)", ruleDict?.description)
    }

    func testVoidSet() {
        ruleDict = [.void: .set]
        XCTAssertEqual("@void", ruleDict?.description)
    }

    // MARK: - @transient tests

    func testTransientString() {
        ruleDict = [.transient: .string("fooBar")]
        XCTAssertEqual("@transient(\"fooBar\")", ruleDict?.description)
    }

    func testTransientInt() {
        ruleDict = [.transient: .int(42)]
        XCTAssertEqual("@transient(42)", ruleDict?.description)
    }

    func testTransientBool() {
        ruleDict = [.transient: .bool(false)]
        XCTAssertEqual("@transient(false)", ruleDict?.description)
    }

    func testTransientSet() {
        ruleDict = [.transient: .set]
        XCTAssertEqual("@transient", ruleDict?.description)
    }

    // MARK: - @pin tests

    func testPinnedString() {
        ruleDict = [.pinned: .string("fooBar")]
        XCTAssertEqual("@pin(\"fooBar\")", ruleDict?.description)
    }

    func testPinnedInt() {
        ruleDict = [.pinned: .int(42)]
        XCTAssertEqual("@pin(42)", ruleDict?.description)
    }

    func testPinnedBool() {
        ruleDict = [.pinned: .bool(false)]
        XCTAssertEqual("@pin(false)", ruleDict?.description)
    }

    func testPinnedSet() {
        ruleDict = [.pinned: .set]
        XCTAssertEqual("@pin", ruleDict?.description)
    }

    // MARK: - @type tests

    func testTypeString() {
        ruleDict = [.type: .string("fooBar")]
        XCTAssertEqual("@type(\"fooBar\")", ruleDict?.description)
    }

    func testTypeInt() {
        ruleDict = [.type: .int(42)]
        XCTAssertEqual("@type(42)", ruleDict?.description)
    }

    func testTypeBool() {
        ruleDict = [.type: .bool(false)]
        XCTAssertEqual("@type(false)", ruleDict?.description)
    }

    func testTypeSet() {
        ruleDict = [.type: .set]
        XCTAssertEqual("@type", ruleDict?.description)
    }

    // MARK: - Custom annotation tests

    func testCustomString() {
        ruleDict = [.custom(label: "🍤"): .string("fooBar")]
        XCTAssertEqual("@🍤(\"fooBar\")", ruleDict?.description)
    }

    func testCustomInt() {
        ruleDict = [.custom(label: "🍤"): .int(42)]
        XCTAssertEqual("@🍤(42)", ruleDict?.description)
    }

    func testCustomBool() {
        ruleDict = [.custom(label: "🍤"): .bool(false)]
        XCTAssertEqual("@🍤(false)", ruleDict?.description)
    }

    func testCustomSet() {
        ruleDict = [.custom(label: "🍤"): .set]
        XCTAssertEqual("@🍤", ruleDict?.description)
    }
}
