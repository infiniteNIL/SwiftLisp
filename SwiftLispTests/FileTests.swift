//
//  FileTests.swift
//  SwiftLispTests
//
//  Created by Rod Schmidt on 5/15/19.
//  Copyright © 2019 infiniteNIL. All rights reserved.
//

import XCTest
@testable import SwiftLispKit

class FileTests: XCTestCase {

    override func setUp() {
        super.setUp()
        try! SwiftLispKit.start()
    }

    func testDoDoNotBrokenByTCO() {
        let tests = [
            ("(do (do 1 2))", "2"),
        ]
        runTests(tests)
    }

    func testReadString() {
        let tests = [
            ("(read-string \"(1 2 (3 4) nil)\")", "(1 2 (3 4) nil)"),
            ("(read-string \"(+ 2 3)\")", "(+ 2 3)"),
            ("(read-string \"7 ;; comment\")", "7"),

            // Differing output, but make sure no fatal error
            ("(read-string \";; comment\")", "Empty Data")
        ]
        runTests(tests)
    }

    func testEvalReadString() {
        let tests = [
            ("(eval (read-string \"(+ 2 3)\"))", "5"),
        ]
        runTests(tests)
    }

    func testSlurp() {
        let testBundle = Bundle(for: type(of: self))
        guard let path = testBundle.path(forResource: "test", ofType: "txt") else {
            XCTFail("Can't find file test.txt")
            return
        }

        let tests = [
            ("(slurp \"\(path)\")", "\"A line of text\\n\""),
        ]
        runTests(tests)
    }

    func testLoadFile() {
        let testBundle = Bundle(for: type(of: self))
        guard let path = testBundle.path(forResource: "inc", ofType: "swlisp") else {
            XCTFail("Can't find file inc.swlisp")
            return
        }

        let tests = [
            ("(load-file \"\(path)\")", "#<function inc3>"),
            ("(inc1 7)", "8"),
            ("(inc2 7)", "9"),
            ("(inc3 9)", "12"),
        ]
        runTests(tests)
    }

    func testAtoms() {
        let tests = [
            ("(defn inc3 [a] (+ 3 a))", "#<function inc3>"),
            ("(def a (atom 2))", "(atom 2)"),
            ("(atom? a)", "true"),
            ("(atom? 1)", "false"),
            ("(deref a)", "2"),
            ("(reset! a 3)", "3"),
            ("(deref a)", "3"),
            ("(swap! a inc3)", "6"),
            ("(deref a)", "6"),
            ("(swap! a (fn [a] a))", "6"),
            ("(swap! a (fn [a] (* 2 a)))", "12"),
            ("(swap! a (fn [a b] (* a b)) 10)", "120"),
            ("(swap! a + 3)", "123"),
        ]
        runTests(tests)
    }

    func testSwapClosureInteraction() {
        let tests = [
            ("(defn inc-it [a] (+ 1 a))", "#<function inc-it>"),
            ("(def atm (atom 7))", "(atom 7)"),
            ("(defn f [] (swap! atm inc-it))", "#<function f>"),
            ("(f)", "8"),
            ("(f)", "9"),
        ]
        runTests(tests)
    }

    func testCommentsInFile() {
        let testBundle = Bundle(for: type(of: self))
        guard let path = testBundle.path(forResource: "incB", ofType: "swlisp") else {
            XCTFail("Can't find file incB.swlisp")
            return
        }

        let tests = [
            ("(load-file \"\(path)\")", "\"incB.mal return string\""), // ;/"incB.mal finished"
            ("(inc4 7)", "11"),
            ("(inc5 7)", "12"),
        ]
        runTests(tests)
    }

    func testMapLiteralAcrossMultipleLinesInAFile() {
        let testBundle = Bundle(for: type(of: self))
        guard let path = testBundle.path(forResource: "incC", ofType: "swlisp") else {
            XCTFail("Can't find file incC.swlisp")
            return
        }

        let tests = [
            ("(load-file \"\(path)\")", "\"incC.mal return string\""),
            ("mymap", "{\"a\" 1}"),
        ]
        runTests(tests)
    }

    func testDerefReaderMacro() {
        let tests = [
            ("(def atm (atom 9))", "(atom 9)"),
            ("@atm", "9"),
        ]
        runTests(tests)
    }

    func testVectorParamsNotBrokenByTCO() {
        let tests = [
            ("(defn g [] 78)", "#<function g>"),
            ("(g)", "78"),
            ("(defn g [a] (+ a 78))", "#<function g>"),
            ("(g 3)", "81"),
        ]
        runTests(tests)
    }

    func testEvalDoesNotUseLocalEnvironments() {
        let tests = [
            ("(def a 1)", "1"),
            ("(let [a 2] (eval (read-string \"a\")))", "1"),
        ]
        runTests(tests)
    }

    func testARGVExistsAndIsEmpty() {
        let tests = [
            ("(list? *ARGV*)", "true"),
            ("*ARGV*", "()"),
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
