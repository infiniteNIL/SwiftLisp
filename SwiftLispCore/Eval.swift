//
//  Eval.swift
//  SwiftLisp
//
//  Created by Rod Schmidt on 5/19/19.
//  Copyright © 2019 infiniteNIL. All rights reserved.
//

import Foundation

func eval(_ expr: DataType, env: Environment) throws -> DataType {
    var env = env
    var expr = expr

    while true {
        expr = try macroExpand(expr, env)

        guard let list = expr as? List else {
            return try evalAST(expr, env: env)
        }

        if list.elements.isEmpty { return expr }

        if let first = list.elements.first as? Symbol {
            switch first.name {
            case "do":
                for list in list.elements.dropFirst().dropLast() {
                    _ = try eval(list, env: env)
                }
                expr = list.elements.last ?? Nil
                continue

            case "def":
                guard let key = list.elements[1] as? Symbol else { throw SwiftLispError.symbolExpected }
                let value = try eval(list.elements[2], env: env)
                env[key] = value
                return value

            case "defmacro", "defn":
                guard let key = list.elements[1] as? Symbol else { throw SwiftLispError.symbolExpected }
                guard let params = list.elements[2] as? Vector else { throw SwiftLispError.expectedListOfBindings }
                guard let binds = params.elements as? [Symbol] else {
                    throw SwiftLispError.expectedListOfBindings
                }

                let body = { (params: [DataType]) -> DataType in
                    let newEnv = Environment(binds: binds, exprs: params, outer: env)
                    return try eval(list.elements[3], env: newEnv)
                }
                let function = Function(name: key.name, ast: list.elements[3], params: binds, env: env, fn: body)
                function.isMacro = first.name == "defmacro"
                env[key] = function
                return function

            case "fn":
                guard let params = list.elements[1] as? Vector else { throw SwiftLispError.expectedListOfBindings }
                guard let binds = params.elements as? [Symbol] else {
                    throw SwiftLispError.expectedListOfBindings
                }

                let fn = { (params: [DataType]) -> DataType in
                    let newEnv = Environment(binds: binds, exprs: params, outer: env)
                    return try eval(list.elements[2], env: newEnv)
                }
                return Function(ast: list.elements[2], params: binds, env: env, fn: fn)

            case "if":
                let condition = try eval(list.elements[1], env: env)
                if condition.isTruthy {
                    expr = list.elements[2]
                }
                else if list.elements.count >= 4 {
                    expr = list.elements[3]
                }
                else {
                    expr = Nil
                }
                continue

            case "let":
                let newEnv = Environment(outer: env)
                guard list.elements[1] is List || list.elements[1] is Vector else {
                    throw SwiftLispError.expectedListOfBindings
                }

                let bindings: [DataType]
                if let list = list.elements[1] as? List {
                    bindings = list.elements
                }
                else {
                    let v = list.elements[1] as! Vector
                    bindings = v.elements
                }

                for index in stride(from: 0, to: bindings.count, by: 2) {
                    guard let bindingSymbol = bindings[index] as? Symbol else {
                        throw SwiftLispError.symbolExpected
                    }
                    let bindingExpr = bindings[index + 1]
                    newEnv[bindingSymbol] = try eval(bindingExpr, env: newEnv)
                }
                env = newEnv
                expr = list.elements[2]
                continue

            case "quote":
                return list.elements[1]

            case "quasiquote":
                expr = quasiquote(list.elements[1])
                continue

            case "objc":
                guard list.elements.count >= 3 else { throw SwiftLispError.arityMismatch }
                expr = try evalObjCMessageSend(list.elements, env)
                continue

            case "macroexpand":
                return try macroExpand(list.elements[1], env)

            case "try":
                // (try A (catch B C))
                // catch part is optional
                let a = list.elements[1]
                var b: Symbol?
                var c: DataType?

                if list.elements.count > 2, let catchPhrase = list.elements[2] as? List {
                    b = catchPhrase.elements[1] as? Symbol
                    if b == nil {
                        throw SwiftLispError.invalidOperation
                    }
                    c = catchPhrase.elements[2]
                    if c == nil {
                        throw SwiftLispError.invalidOperation
                    }
                }

                do {
                    expr = try eval(a, env: env)
                }
                catch let error as SwiftLispException {
                    if let b = b, let c = c {
                        let newEnv = Environment(binds: [b], exprs: [error.value], outer: env)
                        expr = try eval(c, env: newEnv)
                    }
                    else {
                        expr = error.value
                    }
                }
                catch let error as SwiftLispError {
                    if let b = b, let c = c {
                        let newEnv = Environment(binds: [b], exprs: [LispString(error.message)], outer: env)
                        expr = try eval(c, env: newEnv)
                    }
                    else {
                        expr = LispString(error.message)
                    }
                }
                continue

            default:
                break
            }
        }

        let evaluatedList = try evalAST(expr, env: env) as! List
        if let f = evaluatedList.elements.first as? Function {
            if let fnAst = f.ast {
                expr = fnAst
                env = Environment(binds: f.params!, exprs: Array(evaluatedList.elements.dropFirst()), outer: f.env!)
            }
            else {
                return try f.fn(Array(evaluatedList.elements.dropFirst()))
            }
        }
        else {
            return Nil
        }
    }
}

private func evalAST(_ ast: DataType, env: Environment) throws -> DataType {
    switch ast {
    case let symbol as Symbol:
        guard let lambda = env[symbol] else { throw SwiftLispError.symbolNotFound(symbol.name) }
        return lambda

    case let list as List:
        let evaluated = try list.elements.map { try eval($0, env: env) }
        return List(evaluated)

    case let v as Vector:
        let evaluated = try v.elements.map { try eval($0, env: env) }
        return Vector(evaluated)

    case let hash as HashMap:
        let result = HashMap()
        for index in stride(from: 0, to: hash.elements.count, by: 2) {
            let key = hash.elements[index]
            let value = try eval(hash.elements[index + 1], env: env)
            result.append(key)
            result.append(value)
        }
        return result

    default:
        return ast
    }
}

private func quasiquote(_ ast: DataType) -> DataType {
    guard ast.isPair else {
        let result = List()
        result.append(Symbol("quote"))
        result.append(ast)
        return result
    }

    let elements: [DataType]
    if let list = ast as? List {
        elements = list.elements
    }
    else if let vector = ast as? Vector {
        elements = vector.elements
    }
    else {
        fatalError("This can't happen because isPair would be false")
    }

    if let symbol = elements[0] as? Symbol, symbol.name == "unquote" {
        return elements[1]
    }

    if elements[0].isPair, let list = elements[0] as? List,
        let symbol = list.elements[0] as? Symbol, symbol.name == "splice-unquote"
    {
        let result = List([Symbol("concat"), list.elements[1]])
        let rest = List(elements.dropFirst())
        result.append(quasiquote(rest))
        return result
    }

    let result = List([Symbol("cons"), quasiquote(elements[0])])
    let rest = List(elements.dropFirst())
    result.append(quasiquote(rest))
    return result
}

private let ObjC = ObjCRuntime()

private func evalObjCMessageSend(_ ast: [DataType], _ env: Environment) throws -> DataType {
    // (objc message target arg1 key2 arg2....)
    // message could be a symbol or an expression that evals to a symbol
    // target could be a symbol (class name) or an expression that evaluates to a instance)
    // args are expressions that need to be evaluated
    // keys should be keywords

    // See if we can evaluate the message expr. If not then treat it as a message name
    var messageExpr = ast[1]
    do {
        messageExpr = try eval(messageExpr, env: env)
    }
    catch {
        // Not found, just treat as a symbol (use orignal expr)
    }

    guard let messageSymbol = messageExpr as? Symbol else {
        throw SwiftLispError.symbolExpected
    }

    // See if we can evaluate the target expr. If not then treat it as a class name
    var targetExpr = ast[2]
    do {
        targetExpr = try eval(targetExpr, env: env)
    }
    catch {
        // Not found, just treat as a symbol (class name)
        guard let _ = targetExpr as? Symbol else {
            throw SwiftLispError.symbolExpected
        }
    }

    let argsList = try evalAST(List(ast.dropFirst(3)), env: env) as! List
    var rest = argsList.elements[...]

    var args: [(key: String, value: Any?)] = []
    if !rest.isEmpty {
        // Add first argument which doesn't have a key
        let value = try toObjectiveC(rest.first!)
        args.append((key: "", value: value))
        rest = rest.dropFirst()

        // Rest of arguments key1 value1 key2 value2 ....
        for i in stride(from: 0, to: rest.count, by: 2) {
            guard let key = rest[i] as? Keyword else {
                throw SwiftLispError.invalidOperation
            }
            args.append((key: key.name, value: rest[i + 1]))
        }
    }

    // If targetExpr is a symbol then it should be a class
    // Otherwise it's an instance and we need to convert the instance
    // to an Objective-C type
    if let classSymbol = targetExpr as? Symbol {
        guard let klass = ObjC.lookupClass(classSymbol.name) else {
            throw SwiftLispError.invalidOperation
        }
        // Send message to class
        if let result = try ObjC.callMethod(messageSymbol.name, target: klass, with: args) {
            return try objCInstanceToDataType(result)
        }
        else {
            return Nil
        }
    }
    else {
        // Not a class, convert instance to Objective-C type
        let target = try toObjectiveC(targetExpr)
        if let result = try ObjC.callMethod(messageSymbol.name, target: target, with: args) {
            return try objCInstanceToDataType(result)
        }
        else {
            return Nil
        }
    }
}

private func isMacroCall(_ ast: DataType, _ env: Environment) throws -> Bool {
    guard let list = ast as? List else { return false }
    guard !list.elements.isEmpty else { return false }
    guard let symbol = list.elements[0] as? Symbol else { return false }
    guard let fn = env[symbol] as? Function else { return false }
    return fn.isMacro
}

private func macroExpand(_ ast: DataType, _ env: Environment) throws -> DataType {
    var ast = ast
    while try isMacroCall(ast, env) {
        let list = ast as! List
        let symbol = list.elements[0] as! Symbol
        let f = env[symbol] as! Function
        ast = try f.fn(Array(list.elements.dropFirst()))
    }
    return ast
}
