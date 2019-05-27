//
//  TailCallOptimizationTests.swift
//  SwiftLispTests
//
//  Created by Rod Schmidt on 5/15/19.
//  Copyright © 2019 infiniteNIL. All rights reserved.
//

import XCTest
@testable import SwiftLispKit

class TailCallOptimizationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        try! SwiftLispKit.start()
    }

    func testRecursiveTailCallFunction() {
        let tests = [
            ("(defn sum2 [n acc] (if (= n 0) acc (sum2 (- n 1) (+ n acc))))", "#<function sum2>"),
            // TODO: test let*, and do for TCO
            ("(sum2 10 0)", "55"),

            ("(def res2 nil)", "nil"),
            ("(def res2 (sum2 10000 0))", "50005000"),
            ("res2", "50005000"),
        ]
        runTests(tests)
    }

    func testMutuallyRecursiveTailCallFunctions() {
        let tests = [
            ("(defn foo [n] (if (= n 0) 0 (bar (- n 1))))", "#<function foo>"),
            ("(defn bar [n] (if (= n 0) 0 (foo (- n 1))))", "#<function bar>"),
            ("(foo 10000)", "0"),
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
