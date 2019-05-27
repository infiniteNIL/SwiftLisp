//
//  Lexer.swift
//  SwiftLisp
//
//  Created by Rod Schmidt on 5/19/19.
//  Copyright © 2019 infiniteNIL. All rights reserved.
//

import Foundation

enum Lexer {

    static func tokenize(string: String) -> [String] {
        var tokens: [String] = []

        let pattern = "[\\s,]*(~@|[\\[\\]{}()'`~^@]|\"(?:\\\\.|[^\\\\\"])*\"?|;.*|[^\\s\\[\\]{}('\"`,;)]*)"
        let regex = try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .useUnixLineSeparators])

        let matches = regex.matches(in: string, options: [], range: NSMakeRange(0, string.count))
        for match in matches {
            var token = String(string[Range(match.range(at: 1), in: string)!])
            token = token.trimmingCharacters(in: .whitespacesAndNewlines)
            if !token.hasPrefix(";") && !token.isEmpty {
                tokens.append(token)
            }
        }

        return tokens
    }

}
