
enum Printer {

    static func print(_ expr: DataType?, printReadably: Bool = false) -> String {
        if let convertible = expr as? CustomStringConvertible {
            return "\(convertible)"
        }

        switch expr {
        case let hash as HashMap:
            return SwiftLispKit.print(hash.elements,
                                      openBracket: "{", closeBracket: "}",
                                      printReadably: printReadably)

        case let list as List:
            return SwiftLispKit.print(list.elements,
                                      openBracket: "(", closeBracket: ")",
                                      printReadably: printReadably)

        case let s as LispString:
            return printString(s, printReadably: printReadably)

        case let vector as Vector:
            return SwiftLispKit.print(vector.elements,
                                      openBracket: "[", closeBracket: "]",
                                      printReadably: printReadably)

        default:
            fatalError("Unknown type: \(String(describing: expr))")
        }
    }

}

private func print(_ elements: [DataType], openBracket: String, closeBracket: String, printReadably: Bool) -> String {
    let stringOfElements = elements.map {
        Printer.print($0, printReadably: printReadably)
    }.joined(separator: " ")
    return openBracket + stringOfElements + closeBracket
}

private func printString(_ string: LispString, printReadably: Bool) -> String {
    guard printReadably else { return string.value }

    let doubleQuote = "\""
    let slash = "\\"
    return doubleQuote + string.value.replacingOccurrences(of: slash, with: "\(slash)\(slash)")
        .replacingOccurrences(of: doubleQuote, with: "\(slash)\(doubleQuote)")
        .replacingOccurrences(of: "\n", with: "\(slash)n")
        + doubleQuote
}

extension Atom: CustomStringConvertible {
    var description: String { return "(atom \(Printer.print(value)))" }
}

extension Function: CustomStringConvertible {
    var description: String {
        var result = "#<"
        if isMacro {
            result += "macro"
        }
        else {
            result += "function"
        }

        if let name = name {
            result += " \(name)"
        }
        return result + ">"
    }
}

extension Keyword: CustomStringConvertible {
    var description: String { return ":" + name }
}

extension Number: CustomStringConvertible {
    var description: String { return String(value) }
}

extension Symbol: CustomStringConvertible {
    var description: String { return name }
}
