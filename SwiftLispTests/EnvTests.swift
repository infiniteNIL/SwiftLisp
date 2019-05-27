//
//  EnvTests.swift
//  SwiftLispTests
//
//  Created by Rod Schmidt on 5/15/19.
//  Copyright © 2019 infiniteNIL. All rights reserved.
//

import XCTest
@testable import SwiftLispKit

class EnvTests: XCTestCase {

    override func setUp() {
        super.setUp()
        try! SwiftLispKit.start()
    }

    func testReplEnv() {
        let tests = [
            ("(+ 1 2)", "3"),
            ("(/ (- (+ 5 (* 2 3)) 3) 4)", "2"),
        ]
        runTests(tests)
    }

    func testDefBang() {
        let tests = [
            ("(def x 3)", "3"),
            ("x", "3"),
            ("(def x 4)", "4"),
            ("x", "4"),
            ("(def y (+ 1 7))", "8"),
            ("y", "8"),
        ]
        runTests(tests)
    }

    func testSymbolsAreCaseSensitive() {
        let tests = [
            ("(def mynum 111)", "111"),
            ("(def MYNUM 222)", "222"),
            ("mynum", "111"),
            ("MYNUM", "222"),
        ]
        runTests(tests)
    }

    func testEnvLookupNonFatalError() {
        let tests = [
            ("(abc 1 2 3)", "'abc' not found"),
        ]
        runTests(tests)
    }

    func testErrorAbortsDefBang() {
        let tests = [
            ("(def w 123)", "123"),
            ("(def w (abc))", "'abc' not found"),
            ("w", "123"),
        ]
        runTests(tests)
    }

    func testLet() {
        let tests = [
            ("(let [z 9] z)", "9"),
            ("(let [x 9] x)", "9"),
            ("x", "4"),
            ("(let [z (+ 2 3)] (+ 1 z))", "6"),
            ("(let [p (+ 2 3) q (+ 2 p)] (+ p q))", "12"),
            ("(def y (let [z 7] z))", "7"),
            ("y", "7"),
        ]
        runTests(tests)
    }

    func testOuterEnvironment() {
        let tests = [
            ("(def a 4)", "4"),
            ("(let [q 9] q)", "9"),
            ("(let [q 9] a)", "4"),
            ("(let [z 2] (let [q 9] a))", "4"),
        ]
        runTests(tests)
    }

    func testLetWithVectorBindings() {
        let tests = [
            ("(let [z 9] z)", "9"),
            ("(let [p (+ 2 3) q (+ 2 p)] (+ p q))", "12"),
        ]
        runTests(tests)
    }

    func testVectorEvaluation() {
        let tests = [
            ("(let [a 5 b 6] [3 4 a [b 7] 8])", "[3 4 5 [6 7] 8]"),
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
