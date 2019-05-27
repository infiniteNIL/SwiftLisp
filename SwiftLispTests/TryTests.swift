//
//  TryTests.swift
//  SwiftLispTests
//
//  Created by Rod Schmidt on 5/16/19.
//  Copyright © 2019 infiniteNIL. All rights reserved.
//

import XCTest
@testable import SwiftLispKit

class TryTests: XCTestCase {

    override func setUp() {
        super.setUp()
        try! SwiftLispKit.start()
    }

    func testThrow() {
        let tests = [
            ("(throw \"err1\")", "err1"),
            //;/.*([Ee][Rr][Rr][Oo][Rr]|[Ee]xception).*err1.*
            ("(throw {:msg \"err2\"})", "{:msg err2}"),
            //;/.*([Ee][Rr][Rr][Oo][Rr]|[Ee]xception).*msg.*err2.*
        ]
        runTests(tests)
    }

    func testTryCatch() {
        let tests = [
            ("(try 123 (catch e 456))", "123"),

            ("(try (abc 1 2) (catch exc (prn \"exc is:\" exc)))", "nil"),
            // ;/"exc is:" "'abc' not found"

            ("(try (nth [] 1) (catch exc (prn \"exc is:\" exc)))", "nil"),
            // ;/"exc is:".*(length|range|[Bb]ounds|beyond).*

            ("(try (throw \"my exception\") (catch exc (do (prn \"exc:\" exc) 7)))", "7"),
            // ;/"exc:" "my exception"
        ]
        runTests(tests)
    }

    func testThrowIsAFunction() {
        let tests = [
            ("(try (map throw (list \"my err\")) (catch exc exc))", "\"my err\""),
        ]
        runTests(tests)
    }

    func testBuiltinFunctions() {
        let tests = [
            ("(symbol? 'abc)", "true"),
            ("(symbol? \"abc\")", "false"),

            ("(nil? nil)", "true"),
            ("(nil? true)", "false"),

            ("(true? true)", "true"),
            ("(true? false)", "false"),
            ("(true? true?)", "false"),

            ("(false? false)", "true"),
            ("(false? true)", "false"),
        ]
        runTests(tests)
    }

    func testApplyFunctionWithCoreFunctions() {
        let tests = [
            ("(apply + (list 2 3))", "5"),
            ("(apply + 4 (list 5))", "9"),
            ("(apply prn (list 1 2 \"3\" (list)))", "nil"), // ;/1 2 "3" \(\)
            ("(apply prn 1 2 (list \"3\" (list)))", "nil"), // ;/1 2 "3" \(\)
            ("(apply list (list))", "()"),
            ("(apply symbol? (list (quote two)))", "true"),
        ]
        runTests(tests)
    }

    func testApplyFunctionWithUserFunctions() {
        let tests = [
            ("(apply (fn [a b] (+ a b)) (list 2 3))", "5"),
            ("(apply (fn [a b] (+ a b)) 4 (list 5))", "9"),
        ]
        runTests(tests)
    }

    func testMapFunction() {
        let tests = [
            ("(def nums (list 1 2 3))", "(1 2 3)"),
            ("(defn double [a] (* 2 a))", "#<function double>"),
            ("(double 3)", "6"),
            ("(map double nums)", "(2 4 6)"),
            ("(map (fn [x] (symbol? x)) (list 1 (quote two) \"three\"))", "(false true false)"),
        ]
        runTests(tests)
    }

    func testSymbolAndKeywordFunctions() {
        let tests = [
            ("(symbol? :abc)", "false"),
            ("(symbol? 'abc)", "true"),
            ("(symbol? \"abc\")", "false"),
            ("(symbol? (symbol \"abc\"))", "true"),
            ("(keyword? :abc)", "true"),
            ("(keyword? 'abc)", "false"),
            ("(keyword? \"abc\")", "false"),
            ("(keyword? \"\")", "false"),
            ("(keyword? (keyword \"abc\"))", "true"),
            ("(symbol \"abc\")", "abc"),
            ("(keyword :abc)", ":abc"),
            ("(keyword \"abc\")", ":abc"),
        ]
        runTests(tests)
    }

    func testSequentialFunction() {
        let tests = [
            ("(sequential? (list 1 2 3))", "true"),
            ("(sequential? [15])", "true"),
            ("(sequential? sequential?)", "false"),
            ("(sequential? nil)", "false"),
            ("(sequential? \"abc\")", "false"),
        ]
        runTests(tests)
    }

    func testApplyFunctionWithCoreFunctionsAndArgumentsInVector() {
        let tests = [
            ("(apply + 4 [5])", "9"),
            ("(apply prn 1 2 [\"3\" 4])", "nil"), // ;/1 2 "3" 4
            ("(apply list [])", "()"),
            ("(apply (fn [a b] (+ a b)) [2 3])", "5"),
            ("(apply (fn [a b] (+ a b)) 4 [5])", "9"),
        ]
        runTests(tests)
    }

    func testMapFunctionWithVectors() {
        let tests = [
            ("(map (fn [a] (* 2 a)) [1 2 3])", "(2 4 6)"),
            ("(map (fn [& args] (list? args)) [1 2])", "(true true)"),
        ]
        runTests(tests)
    }

    func testVectorFunction() {
        let tests = [
            ("(vector? [10 11])", "true"),
            ("(vector? '(12 13))", "false"),
            ("(vector 3 4 5)", "[3 4 5]"),
            ("(map? {})", "true"),
            ("(map? '())", "false"),
            ("(map? [])", "false"),
            ("(map? 'abc)", "false"),
            ("(map? :abc)", "false"),
        ]
        runTests(tests)
    }

    func testHashMaps() {
        let tests = [
            ("(hash-map \"a\" 1)", "{\"a\" 1}"),
            ("{\"a\" 1}", "{\"a\" 1}"),
            ("(assoc {} \"a\" 1)", "{\"a\" 1}"),
            ("(get (assoc (assoc {\"a\" 1 } \"b\" 2) \"c\" 3) \"a\")", "1"),

            ("(def hm1 (hash-map))", "{}"),
            ("(map? hm1)", "true"),
            ("(map? 1)", "false"),
            ("(map? \"abc\")", "false"),

            ("(get nil \"a\")", "nil"),
            ("(get hm1 \"a\")", "nil"),

            ("(contains? hm1 \"a\")", "false"),
            ("(def hm2 (assoc hm1 \"a\" 1))", "{\"a\" 1}"),
            ("(get hm1 \"a\")", "nil"),
            ("(contains? hm1 \"a\")", "false"),
            ("(get hm2 \"a\")", "1"),
            ("(contains? hm2 \"a\")", "true"),


            // TODO: fix. Clojure returns nil but this breaks mal impl
            ("(keys hm1)", "()"),

            ("(keys hm2)", "(\"a\")"),

            // TODO: fix. Clojure returns nil but this breaks mal impl
            ("(vals hm1)", "()"),

            ("(vals hm2)", "(1)"),

            ("(count (keys (assoc hm2 \"b\" 2 \"c\" 3)))", "3"),
        ]
        runTests(tests)
    }

    func testKeywordsAsHashMapKeys() {
        let tests = [
            ("(get {:abc 123} :abc)", "123"),
            ("(contains? {:abc 123} :abc)", "true"),
            ("(contains? {:abcd 123} :abc)", "false"),
            ("(assoc {} :bcd 234)", "{:bcd 234}"),
            ("(keyword? (nth (keys {:abc 123 :def 456}) 0))", "true"),
            ("(keyword? (nth (keys {\":abc\" 123 \":def\" 456}) 0))", "false"),
            ("(keyword? (nth (vals {\"a\" :abc \"b\" :def}) 0))", "true"),
        ]
        runTests(tests)
    }

    func testAssocUpdatesProperly() {
        let tests = [
            ("(def hm4 (assoc {:a 1 :b 2} :a 3 :c 1))", "{:b 2 :a 3 :c 1}"),
            ("(get hm4 :a)", "3"),
            ("(get hm4 :b)", "2"),
            ("(get hm4 :c)", "1"),
        ]
        runTests(tests)
    }

    func testNilAsHashMapValue() {
        let tests = [
            ("(contains? {:abc nil} :abc)", "true"),
            ("(assoc {} :bcd nil)", "{:bcd nil}"),
        ]
        runTests(tests)
    }

    func testStrAndPrStrMore() {
        let tests = [
            ("(str \"A\" {:abc \"val\"} \"Z\")", "\"A{:abc val}Z\""),

            ("(str true \".\" false \".\" nil \".\" :keyw \".\" 'symb)",
             "\"true.false.nil.:keyw.symb\""),

            ("(pr-str \"A\" {:abc \"val\"} \"Z\")",
             "\"\\\"A\\\" {:abc \\\"val\\\"} \\\"Z\\\"\""),

            ("(pr-str true \".\" false \".\" nil \".\" :keyw \".\" 'symb)",
             "\"true \\\".\\\" false \\\".\\\" nil \\\".\\\" :keyw \\\".\\\" symb\""),

            ("(def s (str {:abc \"val1\" :def \"val2\"}))", "\"{:abc val1 :def val2}\""),
            ("(or (= s \"{:abc val1 :def val2}\") (= s \"{:def val2 :abc val1}\"))", "true"),

            ("(def p (pr-str {:abc \"val1\" :def \"val2\"}))", "\"{:abc \\\"val1\\\" :def \\\"val2\\\"}\""),
            ("(or (= p \"{:abc \\\"val1\\\" :def \\\"val2\\\"}\") (= p \"{:def \\\"val2\\\" :abc \\\"val1\\\"}\"))", "true"),
        ]
        runTests(tests)
    }

    func testExtraFunctionArgumentsAsList() {
        let tests = [
            ("(apply (fn [& more] (list? more)) [1 2 3])", "true"),
            ("(apply (fn [& more] (list? more)) [])", "true"),
            ("(apply (fn [a & more] (list? more)) [1])", "true"),
        ]
        runTests(tests)
    }

    func testMoreThrow() {
        let tests = [
            //;;;TODO: fix so long lines don't trigger ANSI escape codes ;;;(try
            //;;;(try (throw ["data" "foo"]) (catch exc (do (prn "exc is:" exc) 7))) ;;;;
            //;;;; "exc is:" ["data" "foo"] ;;;;=>7
            //;;;;=>7
            ("(try (throw [\"data\" \"foo\"]) (catch exc (do (prn \"exc is:\" exc) 7)))", "7"), // "exc is:" ["data" "foo"]

            // Testing try without catch
            ("(try xyz)", "\"'xyz' not found\""),

            // Testing throwing non-strings
            ("(try (throw (list 1 2 3)) (catch exc (do (prn \"err:\" exc) 7)))", "7") // /"err:" \(1 2 3\)
        ]
        runTests(tests)
    }

    func testDissoc() {
        let tests = [
            ("(def hm1 (hash-map))", "{}"),
            ("(def hm2 (assoc hm1 \"a\" 1))", "{\"a\" 1}"),
            ("(def hm3 (assoc hm2 \"b\" 2))", "{\"a\" 1 \"b\" 2}"),
            ("(count (keys hm3))", "2"),
            ("(count (vals hm3))", "2"),
            ("(dissoc hm3 \"a\")", "{\"b\" 2}"),
            ("(dissoc hm3 \"a\" \"b\")", "{}"),
            ("(dissoc hm3 \"a\" \"b\" \"c\")", "{}"),
            ("(count (keys hm3))", "2"),

            ("(dissoc {:cde 345 :fgh 456} :cde)", "{:fgh 456}"),
            ("(dissoc {:cde nil :fgh 456} :cde)", "{:fgh 456}"),
        ]
        runTests(tests)
    }

    func testHashMapEquality() {
        let tests = [
            ("(= {} {})", "true"),
            ("(= {:a 11 :b 22} (hash-map :b 22 :a 11))", "true"),
            ("(= {:a 11 :b [22 33]} (hash-map :b [22 33] :a 11))", "true"),
            ("(= {:a 11 :b {:c 33}} (hash-map :b {:c 33} :a 11))", "true"),
            ("(= {:a 11 :b 22} (hash-map :b 23 :a 11))", "false"),
            ("(= {:a 11 :b 22} (hash-map :a 11))", "false"),
            ("(= {:a [11 22]} {:a (list 11 22)})", "true"),
            ("(= {:a 11 :b 22} (list :a 11 :b 22))", "false"),
            ("(= {} [])", "false"),
            ("(= [] {})", "false"),
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
            catch let error as SwiftLispException {
                XCTAssertEqual(Printer.print(error.value), expected)
            }
            catch {
                XCTFail("\(input) != \(expected): \(error)")
            }
        }
    }

}
