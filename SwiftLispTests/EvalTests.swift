//
//  EvalTests.swift
//  SwiftLispTests
//
//  Created by Rod Schmidt on 5/15/19.
//  Copyright © 2019 infiniteNIL. All rights reserved.
//

import XCTest
@testable import SwiftLispKit

class EvalTests: XCTestCase {

    override func setUp() {
        super.setUp()
        try! SwiftLispKit.start()
    }

    func testEvaluationOfArithmeticOperations() {
        let tests = [
            ("(+ 1 2)", "3"),
            ("(+ 5 (* 2 3))", "11"),
            ("(- (+ 5 (* 2 3)) 3)", "8"),
            ("(/ (- (+ 5 (* 2 3)) 3) 4)", "2"),
            ("(/ (- (+ 515 (* 87 311)) 302) 27)", "1010"),
            ("(* -3 6)", "-18"),
            ("(/ (- (+ 515 (* -87 311)) 296) 27)", "-994"),
        ]
        runTests(tests)
    }

    func testShouldThrowAnErrorWithNoReturnValue() {
        let tests = [
            ("(abc 1 2 3)", "'abc' not found"),
        ]
        runTests(tests)
    }

    func testEmptyList() {
        let tests = [
            ("()", "()"),
        ]
        runTests(tests)
    }

    func testEvaluationWithinCollectionLiterals() {
        let tests = [
            ("[1 2 (+ 1 2)]", "[1 2 3]"),
            ("{\"a\" (+ 7 8)}", "{\"a\" 15}"),
            ("{:a (+ 7 8)}", "{:a 15}"),
        ]
        runTests(tests)
    }

    func runTests(_ tests: [(String, String)]) {
        for (input, expected) in tests {
            do {
                let result = try readEvalAndPrint(input)
                XCTAssertEqual(result, expected)
            }
            catch let error as SwiftLispError {
                XCTAssertEqual(error.message, expected)
            }
            catch {
                XCTFail("\(input) != \(expected): \(error)")
            }
        }
    }

}
