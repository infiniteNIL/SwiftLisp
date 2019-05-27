import Foundation

var builtins: [String: ([DataType]) throws -> DataType] = [
    "+": add,
    "/": divide,
    "*": multiply,
    "-": subtract,
    "prn": prn,
    "pr-str": prstr,
    "println": println,
    "str": str,
    "read-string": read_string,
    "slurp": slurp,
    "list": list,
    "list?": listp,
    "empty?": emptyp,
    "count": count,
    "=": equal,
    "<": lessThan,
    "<=": lessThanOrEqual,
    ">": greaterThan,
    ">=": greaterThanOrEqual,
    "not": not,
    "atom": atom,
    "atom?": atomp,
    "deref": deref,
    "reset!": reset,
    "swap!": swap,
    "cons": cons,
    "concat": concat,
    "nth": nth,
    "first": first,
    "rest": rest,
    "throw": throwException,
    "apply": apply,
    "map": map,
    "symbol?": symbolp,
    "nil?": nilp,
    "true?": truep,
    "false?": falsep,
    "symbol": make_symbol,
    "keyword": make_keyword,
    "keyword?": keywordp,
    "sequential?": sequentialp,
    "vector": make_vector,
    "vector?": vectorp,
    "map?": mapp,
    "hash-map": make_hash,
    "assoc": assoc,
    "dissoc": dissoc,
    "get": hash_get,
    "contains?": hash_contains,
    "keys": hash_keys,
    "vals": hash_values,
    "readline": readline,
    "meta": meta,
    "with-meta": withMeta,
    "string?": stringp,
    "number?": numberp,
    "fn?": isFunction,
    "macro?": isMacro,
    "time-ms": time_ms,
    "conj": conj,
    "seq": seq,
]

// ((NSUserDefaults sharedUserDefaults) valueForKey "hello")
// (cocoa ((NSUserDefaults sharedUserDefaults) valueForKey "hello"))
// ((NSUserDefaults sharedUserDefaults) valueForKey "hello")
// (NSString initWithString "hello")

private func add(_ args: [DataType]) throws -> DataType {
    return try args.reduce(Number(0)) { accum, arg in
        guard let number = arg as? Number else { throw SwiftLispError.invalidOperation }
        return Number(accum.value + number.value)
    }
}

private func divide(_ args: [DataType]) throws -> DataType {
    guard let first = args.first as? Number else { throw SwiftLispError.invalidOperation }
    return try args.dropFirst().reduce(first) { accum, arg in
        guard let number = arg as? Number else { throw SwiftLispError.invalidOperation }
        return Number(accum.value / number.value)
    }
}

private func multiply(_ args: [DataType]) throws -> DataType {
    return try args.reduce(Number(1)) { accum, arg in
        guard let number = arg as? Number else { throw SwiftLispError.invalidOperation }
        return Number(accum.value * number.value)
    }
}

private func subtract(_ args: [DataType]) throws -> DataType {
    guard let first = args.first as? Number else { throw SwiftLispError.invalidOperation }
    return try args.dropFirst().reduce(first) { accum, arg in
        guard let number = arg as? Number else { throw SwiftLispError.invalidOperation }
        return Number(accum.value - number.value)
    }
}

private func prn(_ args: [DataType]) throws -> DataType {
    print(args.map { Printer.print($0, printReadably: true) }
        .joined(separator: " "))
    return Nil
}

private func prstr(_ args: [DataType]) throws -> DataType {
    let s = args.map { Printer.print($0, printReadably: true) }
        .joined(separator: " ")
    return LispString(s)
}

private func println(_ args: [DataType]) throws -> DataType {
    let s = args.map { Printer.print($0, printReadably: false) }
        .joined(separator: " ")
    print(s)
    return Nil
}

private func str(_ args: [DataType]) throws -> DataType {
    let s = args.map { Printer.print($0, printReadably: false) }
        .joined()
    return LispString(s)
}

private func read_string(_ args: [DataType]) throws -> DataType {
    guard let s = args.first as? LispString else {
        throw SwiftLispError.invalidOperation
    }
    return try Reader.read(s.value)
}

private func slurp(_ args: [DataType]) throws -> DataType {
    guard let filename = args.first as? LispString else {
        throw SwiftLispError.invalidOperation
    }
    let fileContents = try String(contentsOfFile: filename.value)
    return LispString(fileContents)
}

private func list(_ args: [DataType]) throws -> DataType {
    return List(args)
}

private func listp(_ args: [DataType]) throws -> DataType {
    let list = args.first as? List
    return Boolean.eval(list != nil)
}

private func symbolp(_ args: [DataType]) throws -> DataType {
    let symbol = args.first as? Symbol
    return Boolean.eval(symbol != nil)
}

private func nilp(_ args: [DataType]) throws -> DataType {
    return Boolean.eval(args.first === Nil)
}

private func truep(_ args: [DataType]) throws -> DataType {
    let b = args.first as? Boolean
    return Boolean.eval(b === Boolean.True)
}

private func falsep(_ args: [DataType]) throws -> DataType {
    let b = args.first as? Boolean
    return Boolean.eval(b === Boolean.False)
}

private func emptyp(_ args: [DataType]) throws -> DataType {
    guard args.first is List || args.first is Vector else {
        throw SwiftLispError.invalidOperation
    }

    let elements: [DataType] = {
        if let list = args.first as? List {
            return list.elements
        }
        else if let vector = args.first as? Vector {
            return vector.elements
        }
        else {
            return []
        }
    }()

    return Boolean.eval(elements.isEmpty)
}

private func count(_ args: [DataType]) throws -> DataType {
    if let list = args.first as? List {
        return Number(list.elements.count)
    }
    else if let vector = args.first as? Vector {
        return Number(vector.elements.count)
    }
    else if args.first == Nil {
        return Number(0)
    }

    throw SwiftLispError.invalidOperation
}

private func equal(_ args: [DataType]) throws -> DataType {
    return Boolean.eval(args[0] == args[1])
}

private func lessThan(_ args: [DataType]) throws -> DataType {
    let lhs = args[0]
    let rhs = args[1]

    if let lhs = lhs as? Number, let rhs = rhs as? Number {
        return Boolean.eval(lhs.value < rhs.value)
    }
    else if let lhs = lhs as? LispString, let rhs = rhs as? LispString {
        return Boolean.eval(lhs.value < rhs.value)
    }
    else if lhs == Nil, rhs == Nil {
        return Boolean.False
    }
    else if let _ = lhs as? Boolean, let _ = rhs as? Boolean {
        throw SwiftLispError.invalidOperation
    }

    return Boolean.False
}

private func lessThanOrEqual(_ args: [DataType]) throws -> DataType {
    let lhs = args[0]
    let rhs = args[1]

    if let lhs = lhs as? Number, let rhs = rhs as? Number {
        return Boolean.eval(lhs.value <= rhs.value)
    }
    else if let lhs = lhs as? LispString, let rhs = rhs as? LispString {
        return Boolean.eval(lhs.value <= rhs.value)
    }
    else if lhs == Nil, rhs == Nil {
        return Boolean.False
    }
    else if let _ = lhs as? Boolean, let _ = rhs as? Boolean {
        throw SwiftLispError.invalidOperation
    }

    return Boolean.False
}

private func greaterThan(_ args: [DataType]) throws -> DataType {
    let lhs = args[0]
    let rhs = args[1]

    if let lhs = lhs as? Number, let rhs = rhs as? Number {
        return Boolean.eval(lhs.value > rhs.value)
    }
    else if let lhs = lhs as? LispString, let rhs = rhs as? LispString {
        return Boolean.eval(lhs.value > rhs.value)
    }

    return Boolean.False
}

private func greaterThanOrEqual(_ args: [DataType]) throws -> DataType {
    let lhs = args[0]
    let rhs = args[1]

    if let lhs = lhs as? Number, let rhs = rhs as? Number {
        return Boolean.eval(lhs.value >= rhs.value)
    }
    else if let lhs = lhs as? LispString, let rhs = rhs as? LispString {
        return Boolean.eval(lhs.value >= rhs.value)
    }

    return Boolean.False
}

private func not(_ args: [DataType]) throws -> DataType {
    return Boolean.not(args[0].isTruthy)
}

private func atom(_ args: [DataType]) throws -> DataType {
    guard args.count == 1 else { throw SwiftLispError.arityMismatch }
    return Atom(value: args[0])
}

private func atomp(_ args: [DataType]) throws -> DataType {
    return Boolean.eval(args[0] is Atom)
}

private func deref(_ args: [DataType]) throws -> DataType {
    guard let atom = args[0] as? Atom else {
        throw SwiftLispError.invalidOperation
    }
    return atom.value
}

private func reset(_ args: [DataType]) throws -> DataType {
    guard args.count == 2 else { throw SwiftLispError.arityMismatch }
    guard let atom = args[0] as? Atom else {
        throw SwiftLispError.invalidOperation
    }
    atom.value = args[1]
    return atom.value
}

private func swap(_ args: [DataType]) throws -> DataType {
    guard args.count >= 2 else { throw SwiftLispError.arityMismatch }
    guard let atom = args[0] as? Atom, let function = args[1] as? Function else {
        throw SwiftLispError.invalidOperation
    }
    let fnArgs = Array(args[2...])

    let result = try function.fn([atom.value] + fnArgs)
    atom.value = result
    return atom.value
}

private func cons(_ args: [DataType]) throws -> DataType {
    guard args.count == 2 else { throw SwiftLispError.arityMismatch }

    let elements: [DataType]

    switch args[1] {
    case is List:
        let list = args[1] as! List
        elements = list.elements

    case is Vector:
        let vector = args[1] as! Vector
        elements = vector.elements

    default:
        throw SwiftLispError.invalidOperation
    }

    let result = List()
    result.append(args[0])
    elements.forEach { result.append($0) }
    return result
}

private func concat(_ args: [DataType]) throws -> DataType {
    let result = List()

    for arg in args {
        let elements: [DataType]
        if let list = arg as? List {
            elements = list.elements
        }
        else if let vector = arg as? Vector {
            elements = vector.elements
        }
        else {
            throw SwiftLispError.invalidOperation
        }

        elements.forEach { result.append($0) }
    }

    return result
}

private func conj(_ args: [DataType]) throws -> DataType {
    guard args.count >= 2 else { throw SwiftLispError.arityMismatch }

    if let list = args[0] as? List {
        let result = List(list.elements)
        for arg in args.dropFirst() {
            result.elements.insert(arg, at: 0)
        }
        return result
    }
    else if let vector = args[0] as? Vector {
        let result = Vector(vector.elements)
        for arg in args.dropFirst() {
            result.append(arg)
        }
        return result
    }
    else {
        throw SwiftLispError.invalidOperation
    }
}

private func nth(_ args: [DataType]) throws -> DataType {
    guard args.count == 2 else { throw SwiftLispError.arityMismatch }

    let elements: [DataType]

    if let list = args[0] as? List {
        elements = list.elements
    }
    else if let vector = args[0] as? Vector {
        elements = vector.elements
    }
    else {
        throw SwiftLispError.invalidOperation
    }

    guard let n = args[1] as? Number else {
        throw SwiftLispError.invalidOperation
    }

    guard n.value >= 0 && n.value < elements.count else {
        throw SwiftLispError.indexOutOfRange
    }

    return elements[n.value]
}

private func first(_ args: [DataType]) throws -> DataType {
    guard args.count == 1 else { throw SwiftLispError.arityMismatch }

    guard args.first != Nil else { return Nil }

    let elements: [DataType]

    if let list = args[0] as? List {
        elements = list.elements
    }
    else if let vector = args[0] as? Vector {
        elements = vector.elements
    }
    else {
        throw SwiftLispError.invalidOperation
    }

    return elements.first ?? Nil
}

private func rest(_ args: [DataType]) throws -> DataType {
    guard args.count == 1 else { throw SwiftLispError.arityMismatch }

    guard args.first != Nil else { return List() }

    let elements: [DataType]

    if let list = args[0] as? List {
        elements = list.elements
    }
    else if let vector = args[0] as? Vector {
        elements = vector.elements
    }
    else {
        throw SwiftLispError.invalidOperation
    }

    let result = List()
    elements.dropFirst().forEach { result.append($0) }
    return result
}

private func throwException(_ args: [DataType]) throws -> DataType {
    guard args.count == 1 else { throw SwiftLispError.arityMismatch }
    throw SwiftLispException(value: args[0])
}

private func apply(_ args: [DataType]) throws -> DataType {
    guard args.count >= 2 else { throw SwiftLispError.arityMismatch }
    guard let fn = args[0] as? Function else { throw SwiftLispError.invalidOperation }

    let elements: [DataType]
    if let list = args.last as? List {
        elements = list.elements
    }
    else if let vector = args.last as? Vector {
        elements = vector.elements
    }
    else {
        throw SwiftLispError.invalidOperation
    }

    var fnArgs: [DataType] = []
    if args.count > 2 {
        fnArgs = Array(args.dropFirst().dropLast())
    }
    fnArgs += elements

    return try fn.fn(fnArgs)
}

private func map(_ args: [DataType]) throws -> DataType {
    guard args.count == 2 else { throw SwiftLispError.arityMismatch }
    guard let fn = args[0] as? Function else { throw SwiftLispError.invalidOperation }

    let elements: [DataType]
    if let list = args[1] as? List {
        elements = list.elements
    }
    else if let vector = args[1] as? Vector {
        elements = vector.elements
    }
    else {
        throw SwiftLispError.invalidOperation
    }

    let result = List()
    for element in elements {
        result.append(try fn.fn([element]))
    }
    return result
}

private func make_symbol(_ args: [DataType]) throws -> DataType {
    guard args.count == 1 else { throw SwiftLispError.arityMismatch }
    guard let name = args[0] as? LispString else { throw SwiftLispError.invalidOperation }
    return Symbol(name)
}

private func make_keyword(_ args: [DataType]) throws -> DataType {
    guard args.count == 1 else { throw SwiftLispError.arityMismatch }
    if let keyword = args[0] as? Keyword {
        return keyword
    }
    guard let name = args[0] as? LispString else { throw SwiftLispError.invalidOperation }
    return Keyword(name)
}

private func keywordp(_ args: [DataType]) throws -> DataType {
    guard args.count == 1 else { throw SwiftLispError.arityMismatch }
    let k = args[0] as? Keyword
    return Boolean.eval(k != nil)
}

private func sequentialp(_ args: [DataType]) throws -> DataType {
    guard args.count == 1 else { throw SwiftLispError.arityMismatch }
    return Boolean.eval(args[0] is List || args[0] is Vector)
}

private func make_vector(_ args: [DataType]) throws -> DataType {
    return Vector(args)
}

private func vectorp(_ args: [DataType]) throws -> DataType {
    guard args.count == 1 else { throw SwiftLispError.arityMismatch }
    return Boolean.eval(args[0] is Vector)
}

private func mapp(_ args: [DataType]) throws -> DataType {
    guard args.count == 1 else { throw SwiftLispError.arityMismatch }
    return Boolean.eval(args[0] is HashMap)
}

private func stringp(_ args: [DataType]) throws -> DataType {
    guard args.count == 1 else { throw SwiftLispError.arityMismatch }
    return Boolean.eval(args[0] is LispString)
}

private func numberp(_ args: [DataType]) throws -> DataType {
    guard args.count == 1 else { throw SwiftLispError.arityMismatch }
    return Boolean.eval(args[0] is Number)
}

private func isFunction(_ args: [DataType]) throws -> DataType {
    guard args.count == 1 else { throw SwiftLispError.arityMismatch }
    guard let function = args[0] as? Function else { return Boolean.False }
    return Boolean.eval(!function.isMacro)
}

private func isMacro(_ args: [DataType]) throws -> DataType {
    guard args.count == 1 else { throw SwiftLispError.arityMismatch }
    guard let function = args[0] as? Function else { return Boolean.False }
    return Boolean.eval(function.isMacro)
}

private func make_hash(_ args: [DataType]) throws -> DataType {
    guard args.count % 2 == 0 else { throw SwiftLispError.arityMismatch }
    let result = HashMap()
    args.forEach { result.append($0) }
    return result
}

private func assoc(_ args: [DataType]) throws -> DataType {
    guard args.count > 1 else { throw SwiftLispError.arityMismatch }
    guard let hash = args[0] as? HashMap else { throw SwiftLispError.invalidOperation }

    let result = HashMap()
    hash.elements.forEach { result.append($0) }

    var restArgs = args.dropFirst()
    while !restArgs.isEmpty {
        if let key = restArgs.popFirst(), let value = restArgs.popFirst() {
            result.remove(key)
            result.append(key)
            result.append(value)
        }
    }

    return result
}

private func dissoc(_ args: [DataType]) throws -> DataType {
    guard args.count >= 2 else { throw SwiftLispError.arityMismatch }
    guard let hash = args[0] as? HashMap else { throw SwiftLispError.invalidOperation }

    let keys = args.dropFirst()

    let result = HashMap()
    hash.elements.forEach { result.append($0) }

    for key in keys {
        if let b = try hash_contains([hash, key]) as? Boolean, b.isTrue {
            result.remove(key)
        }
    }

    return result
}

private func hash_get(_ args: [DataType]) throws -> DataType {
    guard args.count == 2 else { throw SwiftLispError.arityMismatch }
    guard let hash = args[0] as? HashMap else {
        return Nil
    }

    return hash.get(args[1]) ?? Nil
}

private func hash_contains(_ args: [DataType]) throws -> DataType {
    guard args.count == 2 else { throw SwiftLispError.arityMismatch }
    guard let hash = args[0] as? HashMap else {
        return Boolean.False
    }
    let key = args[1]

    for i in stride(from: 0, to: hash.elements.count, by: 2) {
        if key == hash.elements[i] {
            return Boolean.True
        }
    }

    return Boolean.False
}

private func hash_keys(_ args: [DataType]) throws -> DataType {
    guard args.count == 1 else { throw SwiftLispError.arityMismatch }
    guard let hash = args[0] as? HashMap else {
        return Nil
    }

    let result = List()

    for i in stride(from: 0, to: hash.elements.count, by: 2) {
        result.append(hash.elements[i])
    }

    return result
}

private func hash_values(_ args: [DataType]) throws -> DataType {
    guard args.count == 1 else { throw SwiftLispError.arityMismatch }
    guard let hash = args[0] as? HashMap else {
        return Nil
    }

    let result = List()

    for i in stride(from: 0, to: hash.elements.count, by: 2) {
        result.append(hash.elements[i + 1])
    }

    return result
}

private func readline(_ args: [DataType]) throws -> DataType {
    guard args.count == 1 else { throw SwiftLispError.arityMismatch }
    guard let prompt = args[0] as? LispString else {
        throw SwiftLispError.invalidOperation
    }
    Swift.print(prompt.value, terminator: "")

    guard let s = Swift.readLine() else { return Nil }
    return LispString(s)
}

private func meta(_ args: [DataType]) throws -> DataType {
    guard args.count == 1 else { throw SwiftLispError.arityMismatch }
    return args[0].metadata ?? Nil
}

private func withMeta(_ args: [DataType]) throws -> DataType {
    guard args.count == 2 else { throw SwiftLispError.arityMismatch }

    let copy = args[0].copy()
    copy.metadata = args[1]
    return copy
}

private func time_ms(_ args: [DataType]) throws -> DataType {
    guard args.count == 0 else { throw SwiftLispError.arityMismatch }
    return Number(Int(Date().timeIntervalSinceReferenceDate * 1000))
}

private func seq(_ args: [DataType]) throws -> DataType {
    guard args.count == 1 else { throw SwiftLispError.arityMismatch }

    if args.first === Nil { return Nil }

    guard let collection = args[0] as? Collection else { throw SwiftLispError.invalidOperation }

    if collection.isEmpty {
        return Nil
    }
    else {
        return collection.asList
    }
}

private func swiftEval(_ args: [DataType]) throws -> DataType {
//    if let klass = objc_getClass("NSArray") as? AnyClass {
//    }
//    OpaquePointer(objc_getClass)
//    let fp = objc_getClass
////    let fp = unsafeBitCast(objc_getClass, to: UnsafeRawPointer.self)
//    FFIFunctionInvocation(address: fp)
    return LispString("Not yet")
}
