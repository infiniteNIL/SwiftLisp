//
//  BridgingTests.swift
//  SwiftLispTests
//
//  Created by Rod Schmidt on 5/25/19.
//  Copyright © 2019 infiniteNIL. All rights reserved.
//

import XCTest
@testable import SwiftLispKit

class BridgingTests: XCTestCase {

    override func setUp() {
        super.setUp()
        try! SwiftLispKit.start()
    }

    func testSimpleSend() {
        let tests = [
            ("(.stringWithString NSString \"hey\")", "\"hey\""),
            ("(.uppercaseString \"hey\")", "\"HEY\""),
        ]
        runTests(tests)
    }

    func testSendWithMessageExpr() {
        let tests = [
            ("(defn f [] 'stringWithString)", "#<function f>"),
            ("(objc (f) NSString \"hey\")", "\"hey\""),
        ]
        runTests(tests)
    }

    func testSendWithTargetClassExpr() {
        let tests = [
            ("(defn target [] 'NSString)", "#<function target>"),
            ("(.stringWithString (target) \"hey\")", "\"hey\""),
        ]
        runTests(tests)
    }

    func testSendWithTargetInstance() {
        let tests = [
            ("(defn target [] \"hey\")", "#<function target>"),
            ("(.uppercaseString \"hey\")", "\"HEY\""),
            ("(.uppercaseString (target))", "\"HEY\""),
        ]
        runTests(tests)
    }

    func testBooleanReturnValue() {
        let tests = [
            ("(.hasPrefix \"hey\" \"h\")", "true"),
            ("(.hasPrefix \"hey\" \"j\")", "false"),
        ]
        runTests(tests)
    }

    func testIntegerReturnValue() {
        let tests = [
            ("(.length \"hey\")", "3"),
        ]
        runTests(tests)
    }

    func testIntegerArgument() {
        let tests = [
            ("(.characterAtIndex \"hey\" 0)", "\"h\""),
        ]
        runTests(tests)
    }

    func runTests(_ tests: [(String, String)]) {
        for (input, expected) in tests {
            do {
                guard expected != "" else { return } // ignore blank result
                let result = try readEvalAndPrint(input)
                XCTAssertEqual(result, expected)
            }
            catch let error as SwiftLispError {
                XCTAssertEqual(error.message, expected)
            }
            catch let error as SwiftLispException {
                XCTAssertEqual(Printer.print(error.value), expected)
            }
            catch {
                XCTFail("\(input) != \(expected): \(error)")
            }
        }
    }

}
