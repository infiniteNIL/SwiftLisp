//
//  ReaderTests.swift
//  SwiftLisp
//
//  Created by Rod Schmidt on 5/14/19.
//  Copyright © 2019 infiniteNIL. All rights reserved.
//

import XCTest
@testable import SwiftLispKit

class ReaderTests: XCTestCase {

    func testReadOfNumbers() {
        let tests = [
            ("1", "1"),
            ("7", "7"),
            ("-123", "-123"),
        ]
        runTests(tests)
    }

    func testReadOfSymbols() {
        let tests = [
            ("+", "+"),
            ("abc", "abc"),
            ("abc5", "abc5"),
            ("abc-def", "abc-def"),
        ]
        runTests(tests)
    }

    func testReadOfLists() {
        let tests = [
            ("(+ 1 2)", "(+ 1 2)"),
            ("()", "()"),
            ("(nil)", "(nil)"),
            ("((3 4))", "((3 4))"),
            ("(+ 1 (+ 2 3))", "(+ 1 (+ 2 3))"),
            ("( +   1   (+   2 3   )   )", "(+ 1 (+ 2 3))"),
            ("(* 1 2)", "(* 1 2)"),
            ("(** 1 2)", "(** 1 2)"),
            ("(* -3 6)", "(* -3 6)"),
        ]
        runTests(tests)
    }

    func testCommasAsWhitespace() {
        let tests = [
            ("(1 2, 3,,,,),,", "(1 2 3)"),
        ]
        runTests(tests)
    }

    func testReadOfNilTrueFalse() {
        let tests = [
            ("nil", "nil"),
            ("true", "true"),
            ("false", "false"),
        ]
        runTests(tests)
    }

    func testReadOfStrings() {
        let tests = [
            ("\"abc\"", "\"abc\""),
            ("\"abc (with parens)\"", "\"abc (with parens)\""),
            ("\"abc\\\"def\"", "\"abc\\\"def\""),
            ("\"abc\\ndef\"", "\"abc\\ndef\""),
            ("\"\"", "\"\""),
        ]
        runTests(tests)
    }

    func testReaderErrors() {
        let tests = [
            ("(1 2", "Unexpected end of input"),
            ("[1 2", "Unexpected end of input"),

            // These should throw some error with no return value
            ("\"abc", "Unexpected end of input"),
            ("(1 \"abc", "Unexpected end of input"),
        ]
        runTests(tests)
    }

    func testReadOfQuoting() {
        let tests = [
            ("'1", "(quote 1)"),
            ("'(1 2 3)", "(quote (1 2 3))"),
            ("`1", "(quasiquote 1)"),
            ("`(1 2 3)", "(quasiquote (1 2 3))"),
            ("~1", "(unquote 1)"),
            ("~(1 2 3)", "(unquote (1 2 3))"),
            ("`(1 ~a 3)", "(quasiquote (1 (unquote a) 3))"),
            ("~@(1 2 3)", "(splice-unquote (1 2 3))"),
        ]
        runTests(tests)
    }

    func testKeywords() {
        let tests = [
            (":kw", ":kw"),
            ("(:kw1 :kw2 :kw3)", "(:kw1 :kw2 :kw3)"),
        ]
        runTests(tests)
    }

    func testReadOfVectors() {
        let tests = [
            ("[+ 1 2]", "[+ 1 2]"),
            ("[]", "[]"),
            ("[[3 4]]", "[[3 4]]"),
            ("[+ 1 [+ 2 3]]", "[+ 1 [+ 2 3]]"),
            ("[ +   1   [+   2 3   ]   ]", "[+ 1 [+ 2 3]]"),
        ]
        runTests(tests)
    }

    func testReadOfHashMaps() {
        let tests = [
            ("{\"abc\" 1}", "{\"abc\" 1}"),
            ("{\"a\" {\"b\" 2}}", "{\"a\" {\"b\" 2}}"),
            ("{\"a\" {\"b\" {\"c\" 3}}}", "{\"a\" {\"b\" {\"c\" 3}}}"),
            ("{  \"a\"  {\"b\"   {  \"cde\"     3   }  }}", "{\"a\" {\"b\" {\"cde\" 3}}}"),
            ("{  :a  {:b   {  :cde     3   }  }}", "{:a {:b {:cde 3}}}"),
        ]
        runTests(tests)
    }

    func testReadOfComments() {
        let tests = [
            (";; whole line comment (not an exception)", "Empty Data"),
            ("1 ; comment after expression", "1"),
            ("1; comment after expression", "1"),
        ]
        runTests(tests)
    }

    func testReadOfMetadata() {
        let tests = [
            ("^{\"a\" 1} [1 2 3]", "(with-meta [1 2 3] {\"a\" 1})"),
        ]
        runTests(tests)
    }

    func testReadOfDeref() {
        let tests = [
            ("@a", "(deref a)"),
        ]
        runTests(tests)
    }

    func testReadOfObjc() {
        let tests = [
            ("(.stringWithString NSString)", "(objc stringWithString NSString)"),
            ("(.uppercaseString (.stringWithString NSString))", "(objc uppercaseString (objc stringWithString NSString))"),
        ]
        runTests(tests)
    }

    func runTests(_ tests: [(String, String)]) {
        for (input, expected) in tests {
            do {
                let result = try Reader.read(input)
                XCTAssertEqual(Printer.print(result, printReadably: true), expected)
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
