//
//  SExpr.swift
//  SwiftLisp
//
//  Created by Rod Schmidt on 4/18/19.
//  Copyright © 2019 infiniteNIL. All rights reserved.
//

import Foundation

enum SExpr: Equatable {
    case atom(String)
    case list([SExpr])
}

extension SExpr: CustomStringConvertible {

    var description: String {
        switch self {
        case let .atom(value):
            return value

        case let .list(subexprs):
            return "("
                + subexprs.map({ $0.description }).joined(separator: " ")
                + ")"
        }
    }

}

extension SExpr: ExpressibleByStringLiteral,
                 ExpressibleByUnicodeScalarLiteral,
                 ExpressibleByExtendedGraphemeClusterLiteral {

    public init(stringLiteral value: String) {
        self = SExpr.read(value)
    }

    public init(extendedGraphemeClusterLiteral value: String) {
        self.init(stringLiteral: value)
    }

    public init(unicodeScalarLiteral value: String) {
        self.init(stringLiteral: value)
    }
    
}
