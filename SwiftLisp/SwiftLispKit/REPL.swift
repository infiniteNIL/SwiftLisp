//
//  REPL.swift
//  SwiftLispKit
//
//  Created by Rod Schmidt on 4/18/19.
//

import Foundation

class REPL {

    func run() {
        print("SwiftLisp v0.1 by Rod Schmidt")
        print("Press Ctrl+c to exit\n")

        while true {
            if let input = readLine(prompt: "swiftlisp> ") {
                let sexpr = SExpr.read(input)
                print(sexpr)
            }
            print()
        }
    }

    private func readLine(prompt: String) -> String? {
        guard let cString = readline(prompt) else { return nil }
        defer { free(cString) }
        add_history(cString)
        return String(cString: cString)
    }

}
