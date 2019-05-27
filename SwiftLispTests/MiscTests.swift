//
//  MiscTests.swift
//  MiscTests
//
//  Created by Rod Schmidt on 5/18/19.
//  Copyright © 2019 infiniteNIL. All rights reserved.
//

import XCTest
@testable import SwiftLispKit

class MiscTests: XCTestCase {

    override func setUp() {
        super.setUp()
        try! SwiftLispKit.start()
    }

    func testReadline() {
        let tests: [(String, String)] = [
            // TODO: Fake stdin
            //("(readline \"mal-user> \")", "\"hello\""), // "hello"
        ]
        runTests(tests)
    }

    func testHostLanguage() {
        let tests: [(String, String)] = [
            // each impl is different, but this should return false
            // rather than throwing an exception
            ("(= \"something bogus\" *host-language*)", "false"),
        ]
        runTests(tests)
    }

    func testMetadataOnFunctions() {
        let tests: [(String, String)] = [
            // Testing metadata on functions
            ("(meta (fn [a] a))", "nil"),
            ("(meta (with-meta (fn [a] a) {\"b\" 1}))", "{\"b\" 1}"),
            ("(meta (with-meta (fn [a] a) \"abc\"))", "\"abc\""),

            ("(def l-wm (with-meta (fn [a] a) {\"b\" 2}))", "#<function>"),
            ("(meta l-wm)", "{\"b\" 2}"),

            ("(meta (with-meta l-wm {\"new_meta\" 123}))", "{\"new_meta\" 123}"),
            ("(meta l-wm)", "{\"b\" 2}"),

            ("(def f-wm (with-meta (fn [a] (+ 1 a)) {\"abc\" 1}))", "#<function>"),
            ("(meta f-wm)", "{\"abc\" 1}"),

            ("(meta (with-meta f-wm {\"new_meta\" 123}))", "{\"new_meta\" 123}"),
            ("(meta f-wm)", "{\"abc\" 1}"),

            ("(def f-wm2 ^{\"abc\" 1} (fn [a] (+ 1 a)))", "#<function>"),
            ("(meta f-wm2)", "{\"abc\" 1}"),

            // Meta of native functions should return nil (not fail)
            ("(meta +)", "nil"),

            // Make sure closures and metadata co-exist
            ("(defn gen-plusX [x] (with-meta (fn [b] (+ x b)) {\"meta\" 1}))", "#<function gen-plusX>"),
            ("(def plus7 (gen-plusX 7))", "#<function>"),
            ("(def plus8 (gen-plusX 8))", "#<function>"),
            ("(plus7 8)", "15"),
            ("(meta plus7)", "{\"meta\" 1}"),
            ("(meta plus8)", "{\"meta\" 1}"),
            ("(meta (with-meta plus7 {\"meta\" 2}))", "{\"meta\" 2}"),
            ("(meta plus8)", "{\"meta\" 1}"),
        ]
        runTests(tests)
    }

    func testHashMapEvaluationAndAtoms() {
        let tests: [(String, String)] = [
            ("(def e (atom {\"+\" +}))", "(atom {+ #<function +>})"),
            ("(swap! e assoc \"-\" -)", "{\"+\" #<function +> \"-\" #<function ->}"),
            ("( (get @e \"+\") 7 8)", "15"),
            ("( (get @e \"-\") 11 8)", "3"),
            ("(swap! e assoc \"foo\" (list))", "{\"+\" #<function +> \"-\" #<function -> \"foo\" ()}"),
            ("(get @e \"foo\")", "()"),
            ("(swap! e assoc \"bar\" '(1 2 3))", "{\"+\" #<function +> \"-\" #<function -> \"foo\" () \"bar\" (1 2 3)}"),
            ("(get @e \"bar\")", "(1 2 3)"),
        ]
        runTests(tests)
    }

    func testStringp() {
        let tests: [(String, String)] = [
            ("(string? \"\")", "true"),
            ("(string? 'abc)", "false"),
            ("(string? \"abc\")", "true"),
            ("(string? :abc)", "false"),
            ("(string? (keyword \"abc\"))", "false"),
            ("(string? 234)", "false"),
            ("(string? nil)", "false"),
        ]
        runTests(tests)
    }

    func testNumberp() {
        let tests: [(String, String)] = [
            ("(number? 123)", "true"),
            ("(number? -1)", "true"),
            ("(number? nil)", "false"),
            ("(number? false)", "false"),
            ("(number? \"123\")", "false"),
        ]
        runTests(tests)
    }

    func testFunctionp() {
        let tests: [(String, String)] = [
            ("(defn add1 [x] (+ x 1))", "#<function add1>"),
            ("(fn? +)", "true"),
            ("(fn? add1)", "true"),
            ("(fn? cond)", "false"),
            ("(fn? \"+\")", "false"),
            ("(fn? :+)", "false"),
        ]
        runTests(tests)
    }

    func testMacrop() {
            let tests: [(String, String)] = [
            ("(macro? cond)", "true"),
            ("(macro? +)", "false"),
            ("(macro? add1)", "false"),
            ("(macro? \"+\")", "false"),
            ("(macro? :+)", "false"),
        ]
        runTests(tests)
    }

    func testConj() {
        let tests: [(String, String)] = [
            ("(conj (list) 1)", "(1)"),
            ("(conj (list 1) 2)", "(2 1)"),
            ("(conj (list 2 3) 4)", "(4 2 3)"),
            ("(conj (list 2 3) 4 5 6)", "(6 5 4 2 3)"),
            ("(conj (list 1) (list 2 3))", "((2 3) 1)"),

            ("(conj [] 1)", "[1]"),
            ("(conj [1] 2)", "[1 2]"),
            ("(conj [2 3] 4)", "[2 3 4]"),
            ("(conj [2 3] 4 5 6)", "[2 3 4 5 6]"),
            ("(conj [1] [2 3])", "[1 [2 3]]"),
        ]
        runTests(tests)
    }

    func testSeq() {
        let tests: [(String, String)] = [
            ("(seq \"abc\")", "(\"a\" \"b\" \"c\")"),
            ("(apply str (seq \"this is a test\"))", "\"this is a test\""),
            ("(seq '(2 3 4))", "(2 3 4)"),
            ("(seq [2 3 4])", "(2 3 4)"),

            ("(seq \"\")", "nil"),
            ("(seq '())", "nil"),
            ("(seq [])", "nil"),
            ("(seq nil)", "nil"),
        ]
        runTests(tests)
    }

    func testMetadataOnCollections() {
        let tests: [(String, String)] = [
            ("(meta [1 2 3])", "nil"),
            ("(with-meta [1 2 3] {\"a\" 1})", "[1 2 3]"),
            ("(meta (with-meta [1 2 3] {\"a\" 1}))", "{\"a\" 1}"),
            ("(vector? (with-meta [1 2 3] {\"a\" 1}))", "true"),
            ("(meta (with-meta [1 2 3] \"abc\"))", "\"abc\""),
            ("(meta (with-meta (list 1 2 3) {\"a\" 1}))", "{\"a\" 1}"),
            ("(list? (with-meta (list 1 2 3) {\"a\" 1}))", "true"),
            ("(meta (with-meta {\"abc\" 123} {\"a\" 1}))", "{\"a\" 1}"),
            ("(map? (with-meta {\"abc\" 123} {\"a\" 1}))", "true"),

            // Not actually supported by Clojure
            ("(meta (with-meta (atom 7) {\"a\" 1}))", "{\"a\" 1}"),

            ("(def l-wm (with-meta [4 5 6] {\"b\" 2}))", "[4 5 6]"),
            ("(meta l-wm)", "{\"b\" 2}"),

            ("(meta (with-meta l-wm {\"new_meta\" 123}))", "{\"new_meta\" 123}"),
            ("(meta l-wm)", "{\"b\" 2}"),
        ]
        runTests(tests)
    }

    func testMetadataOnBuiltins() {
        let tests: [(String, String)] = [
            ("(meta +)", "nil"),
            ("(def f-wm3 ^{\"def\" 2} +)", "#<function +>"),
            ("(meta f-wm3)", "{\"def\" 2}"),
            ("(meta +)", "nil"),
        ]
        runTests(tests)
    }

    func testGensymAndCleanOrMacro() {
        let tests: [(String, String)] = [
            ("(= (gensym) (gensym))", "false"),
            ("(let [or_FIXME 23] (or false (+ or_FIXME 100)))", "123"),
        ]
        runTests(tests)
    }

    func testTimeMS() {
        let tests: [(String, String)] = [
            ("(def start-time (time-ms))", ""),
            ("(= start-time 0)", "false"),
            ("(let [sumdown (fn (N) (if (> N 0) (+ N (sumdown (- N 1))) 0))] (sumdown 10)) ; Waste some time", "55"),
            ("(> (time-ms) start-time)", "true"),
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
