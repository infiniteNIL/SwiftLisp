//
//  IfFnDoTests.swift
//  SwiftLispTests
//
//  Created by Rod Schmidt on 5/15/19.
//  Copyright © 2019 infiniteNIL. All rights reserved.
//

import XCTest
@testable import SwiftLispKit

class IfFnDoTests: XCTestCase {

    override func setUp() {
        super.setUp()
        try! SwiftLispKit.start()
    }

    func testListFunctions() {
        let tests = [
            ("(list)", "()"),
            ("(list? (list))", "true"),
            ("(empty? (list))", "true"),
            ("(empty? (list 1))", "false"),
            ("(list 1 2 3)", "(1 2 3)"),
            ("(count (list 1 2 3))", "3"),
            ("(count (list))", "0"),
            ("(count nil)", "0"),
            ("(if (> (count (list 1 2 3)) 3) 89 78)", "78"),
            ("(if (>= (count (list 1 2 3)) 3) 89 78)", "89"),
        ]
        runTests(tests)
    }

    func testIfForm() {
        let tests = [
            ("(if true 7 8)", "7"),
            ("(if false 7 8)", "8"),
            ("(if false 7 false)", "false"),
            ("(if true (+ 1 7) (+ 1 8))", "8"),
            ("(if false (+ 1 7) (+ 1 8))", "9"),
            ("(if nil 7 8)", "8"),
            ("(if 0 7 8)", "7"),
            ("(if (list) 7 8)", "7"),
            ("(if (list 1 2 3) 7 8)", "7"),
            ("(= (list) nil)", "false"),

            // Testing 1-way if form
            ("(if false (+ 1 7))", "nil"),
            ("(if nil 8 7)", "7"),
            ("(if true (+ 1 7))", "8"),
        ]
        runTests(tests)
    }

    func testConditionals() {
        let tests = [
            ("(= 2 1)", "false"),
            ("(= 1 1)", "true"),
            ("(= 1 2)", "false"),
            ("(= 1 (+ 1 1))", "false"),
            ("(= 2 (+ 1 1))", "true"),
            ("(= nil 1)", "false"),
            ("(= nil nil)", "true"),

            ("(> 2 1)", "true"),
            ("(> 1 1)", "false"),
            ("(> 1 2)", "false"),

            ("(>= 2 1)", "true"),
            ("(>= 1 1)", "true"),
            ("(>= 1 2)", "false"),

            ("(< 2 1)", "false"),
            ("(< 1 1)", "false"),
            ("(< 1 2)", "true"),

            ("(<= 2 1)", "false"),
            ("(<= 1 1)", "true"),
            ("(<= 1 2)", "true"),
        ]
        runTests(tests)
    }

    func testEquality() {
        let tests = [
            ("(= 1 1)", "true"),
            ("(= 0 0)", "true"),
            ("(= 1 0)", "false"),
            ("(= true true)", "true"),
            ("(= false false)", "true"),
            ("(= nil nil)", "true"),

            ("(= (list) (list))", "true"),
            ("(= (list 1 2) (list 1 2))", "true"),
            ("(= (list 1) (list))", "false"),
            ("(= (list) (list 1))", "false"),
            ("(= 0 (list))", "false"),
            ("(= (list) 0)", "false"),
        ]
        runTests(tests)
    }

    func testBuiltinsAndFunctions() {
        let tests = [
            ("(+ 1 2)", "3"),
            ("( (fn [a b] (+ b a)) 3 4)", "7"),
            ("( (fn [] 4) )", "4"),
            ("( (fn [f x] (f x)) (fn [a] (+ 1 a)) 7)", "8"),
        ]
        runTests(tests)
    }

    func testClosures() {
        let tests = [
            ("( ( (fn [a] (fn [b] (+ a b))) 5) 7)", "12"),

            ("(defn gen-plus5 [] (fn [b] (+ 5 b)))", "#<function gen-plus5>"),
            ("(def plus5 (gen-plus5))", "#<function>"),
            ("(plus5 7)", "12"),

            ("(defn gen-plusX [x] (fn [b] (+ x b)))", "#<function gen-plusX>"),
            ("(def plus7 (gen-plusX 7))", "#<function>"),
            ("(plus7 8)", "15"),
        ]
        runTests(tests)
    }

    func testDo() {
        let tests = [
            ("(do (prn 101))", "nil"), // TODO: test printed 101
            ("(do (prn 102) 7)", "7"), // TODO: test printed 102
            ("(do (prn 101) (prn 102) (+ 1 2))", "3"), // TODO: Test printed /101 /102
            ("(do (def a 6) 7 (+ a 8))", "14"),
            ("a", "6"),
        ]
        runTests(tests)
    }

    func testSpecialFormCaseSensitivity() {
        let tests = [
            ("(def DO (fn [a] 7))", "#<function>"),
            ("(DO 3)", "7"),
        ]
        runTests(tests)
    }

    func testRecursiveSundown() {
        let tests = [
            ("(defn sumdown [N] (if (> N 0) (+ N (sumdown  (- N 1))) 0))", "#<function sumdown>"),
            ("(sumdown 1)", "1"),
            ("(sumdown 2)", "3"),
            ("(sumdown 6)", "21"),
        ]
        runTests(tests)
    }

    func testRecursiveFibonacci() {
        let tests = [
            ("(defn fib [N] (if (= N 0) 1 (if (= N 1) 1 (+ (fib (- N 1)) (fib (- N 2))))))", "#<function fib>"),
            ("(fib 1)", "1"),
            ("(fib 2)", "2"),
            ("(fib 4)", "5"),
            ("(fib 10)", "89"),
        ]
        runTests(tests)
    }

    func testIfOnStrings() {
        let tests = [
            ("(if \"\" 7 8)", "7"),
        ]
        runTests(tests)
    }

    func testStringEquality() {
        let tests = [
            ("(= \"\" \"\")", "true"),
            ("(= \"abc\" \"abc\")", "true"),
            ("(= \"abc\" \"\")", "false"),
            ("(= \"\" \"abc\")", "false"),
            ("(= \"abc\" \"def\")", "false"),
            ("(= \"abc\" \"ABC\")", "false"),
            ("(= (list) \"\")", "false"),
            ("(= \"\" (list))", "false"),
        ]
        runTests(tests)
    }

    func testVariableLengthArguments() {
        let tests = [
            ("( (fn [& more] (count more)) 1 2 3)", "3"),
            ("( (fn [& more] (list? more)) 1 2 3)", "true"),
            ("( (fn [& more] (count more)) 1)", "1"),
            ("( (fn [& more] (count more)) )", "0"),
            ("( (fn [& more] (list? more)) )", "true"),
            ("( (fn [a & more] (count more)) 1 2 3)", "2"),
            ("( (fn [a & more] (count more)) 1)", "0"),
            ("( (fn [a & more] (list? more)) 1)", "true"),
        ]
        runTests(tests)
    }

    func testNot() {
        let tests = [
            ("(not false)", "true"),
            ("(not nil)", "true"),
            ("(not true)", "false"),
            ("(not \"a\")", "false"),
            ("(not 0)", "false"),
        ]
        runTests(tests)
    }

    func testStringQuoting() {
        let tests = [
            ("\"\"", "\"\""),
            ("\"abc\"", "\"abc\""),
            ("\"abc  def\"", "\"abc  def\""),
            ("\"\\\"\"", "\"\\\"\""),
            ("\"abc\\ndef\\nghi\"", "\"abc\\ndef\\nghi\""),
            ("\"abc\\\\def\\\\ghi\"", "\"abc\\\\def\\\\ghi\""),
            ("\"\\\\n\"", "\"\\\\n\""),
        ]
        runTests(tests)
    }

    func testPrStr() {
        let tests = [
            ("(pr-str)", "\"\""),
            ("(pr-str \"\")", "\"\\\"\\\"\""),
            ("(pr-str \"abc\")", "\"\\\"abc\\\"\""),
            ("(pr-str \"abc  def\" \"ghi jkl\")", "\"\\\"abc  def\\\" \\\"ghi jkl\\\"\""),
            ("(pr-str \"\\\"\")", "\"\\\"\\\\\\\"\\\"\""),

            ("(pr-str (list 1 2 \"abc\" \"\\\"\") \"def\")",
             "\"(1 2 \\\"abc\\\" \\\"\\\\\\\"\\\") \\\"def\\\"\""),

            ("(pr-str \"abc\\ndef\\nghi\")",
             "\"\\\"abc\\\\ndef\\\\nghi\\\"\""),

            ("(pr-str \"abc\\\\def\\\\ghi\")",
             "\"\\\"abc\\\\\\\\def\\\\\\\\ghi\\\"\""),

            ("(pr-str (list))", "\"()\""),
        ]
        runTests(tests)
    }

    func testStr() {
        let tests = [
            ("(str)", "\"\""),
            ("(str \"\")", "\"\""),
            ("(str \"abc\")", "\"abc\""),
            ("(str \"\\\"\")", "\"\\\"\""),
            ("(str 1 \"abc\" 3)", "\"1abc3\""),
            ("(str \"abc  def\" \"ghi jkl\")", "\"abc  defghi jkl\""),
            ("(str \"abc\\ndef\\nghi\")", "\"abc\\ndef\\nghi\""),
            ("(str \"abc\\\\def\\\\ghi\")", "\"abc\\\\def\\\\ghi\""),
            ("(str (list 1 2 \"abc\" \"\\\"\") \"def\")", "\"(1 2 abc \\\")def\""),
            ("(str (list))", "\"()\""),
        ]
        runTests(tests)
    }

    func testPrn() {
        let tests = [
            ("(prn)", "nil"),
            ("(prn \"\")", "nil"),
            ("(prn \"abc\")", "nil"),
            ("(prn \"abc  def\" \"ghi jkl\")", "nil"),  // ;/"abc  def" "ghi jkl"
            ("(prn \"\\\"\")", "nil"),  // ;/"\\""
            ("(prn \"abc\\ndef\\nghi\")", "nil"),   // ;/"abc\\ndef\\nghi"
            ("(prn \"abc\\\\def\\\\ghi\")", "nil"), // ;/"abc\\\\def\\\\ghi"
            ("(prn (list 1 2 \"abc\" \"\\\"\") \"def\")", "nil"),   // ;/\(1 2 "abc" "\\""\) "def"
        ]
        runTests(tests)
    }

    func testPrintln() {
        let tests = [
            ("(println)", "nil"),   // ;/
            ("(println \"\")", "nil"),  // ;/
            ("(println \"abc\")", "nil"),   // ;/abc
            ("(println \"abc  def\" \"ghi jkl\")", "nil"),  // ;/abc  def ghi jkl
            ("(println \"\\\"\")", "nil"),  // ;/"
            ("(println \"abc\\ndef\\nghi\")", "nil"),   // ;/abc \n ;/def \n ;/ghi
            ("(println \"abc\\\\def\\\\ghi\")", "nil"), // ;/abc\\def\\ghi
            ("(println (list 1 2 \"abc\" \"\\\"\") \"def\")", "nil"),   // ;/\(1 2 abc "\) def
        ]
        runTests(tests)
    }

    func testKeywords() {
        let tests = [
            ("(= :abc :abc)", "true"),
            ("(= :abc :def)", "false"),
            ("(= :abc \":abc\")", "false"),
        ]
        runTests(tests)
    }

    func testVectorTruthiness() {
        let tests = [
            ("(if [] 7 8)", "7"),
        ]
        runTests(tests)
    }

    func testVectorPrinting() {
        let tests = [
            ("(pr-str [1 2 \"abc\" \"\\\"\"] \"def\")", "\"[1 2 \\\"abc\\\" \\\"\\\\\\\"\\\"] \\\"def\\\"\""),
            ("(pr-str [])", "\"[]\""),
            ("(str [1 2 \"abc\" \"\\\"\"] \"def\")", "\"[1 2 abc \\\"]def\""),
            ("(str [])", "\"[]\""),
        ]
        runTests(tests)
    }

    func testVectorFunctions() {
        let tests = [
            ("(count [1 2 3])", "3"),
            ("(empty? [1 2 3])", "false"),
            ("(empty? [])", "true"),
            ("(list? [4 5 6])", "false"),
        ]
        runTests(tests)
    }

    func testVectorEquality() {
        let tests = [
            ("(= [] (list))", "true"),
            ("(= [7 8] [7 8])", "true"),
            ("(= (list 1 2) [1 2])", "true"),
            ("(= (list 1) [])", "false"),
            ("(= [] [1])", "false"),
            ("(= 0 [])", "false"),
            ("(= [] 0)", "false"),
            ("(= [] \"\")", "false"),
            ("(= \"\" [])", "false"),
        ]
        runTests(tests)
    }

    func testVectorParameterLists() {
        let tests = [
            ("( (fn [] 4) )", "4"),
            ("( (fn [f x] (f x)) (fn [a] (+ 1 a)) 7)", "8"),
        ]
        runTests(tests)
    }

    func testNestedVectorListEquality() {
        let tests = [
            ("(= [(list)] (list []))", "true"),
            ("(= [1 2 (list 3 4 [5 6])] (list 1 2 [3 4 (list 5 6)]))", "true"),
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
