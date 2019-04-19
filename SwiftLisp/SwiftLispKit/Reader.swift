//
//  Reader.swift
//  SwiftLisp
//
//  Created by Rod Schmidt on 4/18/19.
//  Copyright © 2019 infiniteNIL. All rights reserved.
//

import Foundation

extension SExpr {

    static func read(_ string: String) -> SExpr {
        let (_, sexpr) = parse(tokens: tokenize(string))
        return sexpr ?? .list([])
    }

    private static func tokenize(_ string: String) -> [Token] {
        var result: [Token] = []
        var tmpText = ""

        func collectText() {
            if tmpText != "" {
                result.append(.textBlock(tmpText))
                tmpText = ""
            }
        }

        for ch in string {
            switch ch {
            case "(":
                collectText()
                result.append(.openParen)

            case ")":
                collectText()
                result.append(.closeParen)

            case " ":
                collectText()

            default:
                tmpText.append(ch)
            }
        }

        return result
    }

    private static func parse(tokens: [Token], node: SExpr? = nil) -> (remaining: [Token], subexpr: SExpr?) {
        var tokens = tokens
        var node = node

        var i = 0
        repeat {
            let t = tokens[i]
            switch t {
            case .openParen:
                let (remaining, n) = parse(tokens: Array(tokens[(i + 1)...]), node: .list([]))
                assert(n != nil)

                (tokens, i) = (remaining, 0)
                node = appendTo(list: node, node: n!)

                if tokens.count != 0 {
                    continue
                }
                else {
                    break
                }

            case .closeParen:
                return (Array(tokens[(i + 1)...]), node)

            case let .textBlock(value):
                node = appendTo(list: node, node: .atom(value))
            }

            i += 1
        } while tokens.count > 0

        return ([], node)
    }

    private static func appendTo(list: SExpr?, node: SExpr) -> SExpr {
        guard let list = list else { return node }

        if case var .list(elements) = list {
            elements.append(node)
            return .list(elements)
        }
        else {
            return node
        }
    }

}
