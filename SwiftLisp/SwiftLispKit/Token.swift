//
//  Tokens.swift
//  SwiftLisp
//
//  Created by Rod Schmidt on 4/18/19.
//  Copyright © 2019 infiniteNIL. All rights reserved.
//

import Foundation

enum Token {
    case openParen
    case textBlock(String)
    case closeParen
}
