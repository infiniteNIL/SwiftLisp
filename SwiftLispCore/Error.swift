//
//  Error.swift
//  SwiftLisp
//
//  Created by Rod Schmidt on 5/18/19.
//  Copyright © 2019 infiniteNIL. All rights reserved.
//

import Foundation

public enum SwiftLispError: Error {
    case emptyData
    case unexpectedEndOfInput
    case unbalancedParens
    case unterminatedString
    case arityMismatch
    case invalidOperation
    case symbolNotFound(String)
    case symbolExpected
    case expectedListOfBindings
    case indexOutOfRange

    public var message: String {
        switch self {
        case .emptyData:                return "Empty Data"
        case .unexpectedEndOfInput:     return "Unexpected end of input"
        case .unbalancedParens:         return "Unbalanced parenthesis"
        case .unterminatedString:       return "Unterminated String"
        case .arityMismatch:            return "Wrong number of arguments"
        case .invalidOperation:         return "Can't apply function to arguments"

        case let .symbolNotFound(name):
            return "'\(name)' not found"

        case .symbolExpected:           return "Symbol expected"
        case .expectedListOfBindings:   return "Expected list of bindings"
        case .indexOutOfRange:          return "Index out of range"
        }
    }
}

extension SwiftLispError: CustomStringConvertible {
    public var description: String {
        return self.message
    }
}

struct SwiftLispException: Error {
    let value: DataType

    init(value: DataType) {
        self.value = value
    }
}
