//
//  MacroTests.swift
//  SwiftLispTests
//
//  Created by Rod Schmidt on 5/16/19.
//  Copyright © 2019 infiniteNIL. All rights reserved.
//

import XCTest
@testable import SwiftLispKit

class MacroTests: XCTestCase {

    override func setUp() {
        super.setUp()
        try! SwiftLispKit.start()
    }

    func testTrivialMacros() {
        let tests = [
            ("(defmacro one [] 1)", "#<macro one>"),
            ("(one)", "1"),
            ("(defmacro two [] 2)", "#<macro two>"),
            ("(two)", "2"),
        ]
        runTests(tests)
    }

    func testUnlessMacros() {
        let tests = [
            ("(defmacro unless [pred a b] `(if ~pred ~b ~a)))", "#<macro unless>"),
            ("(unless false 7 8)", "7"),
            ("(unless true 7 8)", "8"),
            ("(defmacro unless2 [pred a b] `(if (not ~pred) ~a ~b)))", "#<macro unless2>"),
            ("(unless2 false 7 8)", "7"),
            ("(unless2 true 7 8)", "8"),

            // Test macroexpand
            ("(macroexpand (unless2 2 3 4))", "(if (not 2) 3 4)"),
        ]
        runTests(tests)
    }

    func testEvaluationOfMacroResult() {
        let tests = [
            ("(defmacro identity [x] x)", "#<macro identity>"),
            ("(let [a 123] (identity a))", "123"),
        ]
        runTests(tests)
    }

    func testNonMacroFunction() {
        let tests = [
            ("(not (= 1 1))", "false"),
            // This should fail if it is a macro
            ("(not (= 1 2))", "true"),

        ]
        runTests(tests)
    }

    func testNthFirstAndRest() {
        let tests = [
            ("(nth (list 1) 0)", "1"),
            ("(nth (list 1 2) 1)", "2"),
            ("(def x \"x\")", "\"x\""),
            ("(def x (nth (list 1 2) 2))", "Index out of range"),
            ("x", "\"x\""),

            ("(first (list))", "nil"),
            ("(first (list 6))", "6"),
            ("(first (list 7 8 9))", "7"),

            ("(rest (list))", "()"),
            ("(rest (list 6))", "()"),
            ("(rest (list 7 8 9))", "(8 9)"),
        ]
        runTests(tests)
    }

    func testOrMacro() {
        let tests = [
            ("(or)", "nil"),
            ("(or 1)", "1"),
            ("(or 1 2 3 4)", "1"),
            ("(or false 2)", "2"),
            ("(or false nil 3)", "3"),
            ("(or false nil false false nil 4)", "4"),
            ("(or false nil 3 false nil 4)", "3"),
            ("(or (or false 4))", "4"),
        ]
        runTests(tests)
    }

    func testCondMacro() {
        let tests = [
            ("(cond)", "nil"),
            ("(cond true 7)", "7"),
            ("(cond true 7 true 8)", "7"),
            ("(cond false 7 true 8)", "8"),
            ("(cond false 7 false 8 \"else\" 9)", "9"),
            ("(cond false 7 (= 2 2) 8 \"else\" 9)", "8"),
            ("(cond false 7 false 8 false 9)", "nil"),
        ]
        runTests(tests)
    }

    func testEvalInLet() {
        let tests = [
            ("(let [x (or nil \"yes\")] x)", "\"yes\""),
        ]
        runTests(tests)
    }

    func testNthFirstRestWithVectors() {
        let tests = [
            ("(nth [1] 0)", "1"),
            ("(nth [1 2] 1)", "2"),
            ("(def x \"x\")", "\"x\""),
            ("(def x (nth [1 2] 2))", "Index out of range"),
            ("x", "\"x\""),

            ("(first [])", "nil"),
            ("(first nil)", "nil"),
            ("(first [10])", "10"),
            ("(first [10 11 12])", "10"),
            ("(rest [])", "()"),
            ("(rest nil)", "()"),
            ("(rest [10])", "()"),
            ("(rest [10 11 12])", "(11 12)"),
        ]
        runTests(tests)
    }

    func testLoadingCore() {
        let testBundle = Bundle(for: type(of: self))
        guard let path = testBundle.path(forResource: "core", ofType: "swlisp") else {
            XCTFail("Can't find file core.swlisp")
            return
        }

        let tests = [
            ("(load-file \"\(path)\")", "nil"),
        ]
        runTests(tests)
    }

    func testMacro() {
        let tests = [
            ("(-> 7)", "7"),
            ("(-> (list 7 8 9) first)", "7"),
            ("(-> (list 7 8 9) (first))", "7"),
            ("(-> (list 7 8 9) first (+ 7))", "14"),
            ("(-> (list 7 8 9) rest (rest) first (+ 7))", "16"),

            ("(->> \"L\")", "\"L\""),
            ("(->> \"L\" (str \"A\") (str \"M\"))", "\"MAL\""),
            ("(->> [4] (concat [3]) (concat [2]) rest (concat [1]))", "(1 3 4)"),
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
