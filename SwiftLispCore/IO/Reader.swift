import Foundation

class Reader {

    static func read(_ s: String) throws -> DataType {
        let tokens = Lexer.tokenize(string: s)
        if tokens.isEmpty { throw SwiftLispError.emptyData }
        let reader = Reader(tokens: tokens)
        return try reader.readForm()
    }

    private init(tokens: [String]) {
        self.tokens = tokens
        position = 0
    }

    private let tokens: [String]
    private var position: Int = 0
}

extension Reader {

    @discardableResult
    private func next() -> String? {
        guard position < tokens.count else { return nil }
        let token = tokens[position]
        position += 1
        return token
    }

    private func peek() -> String? {
        guard position < tokens.count else { return nil }
        return tokens[position]
    }

    private func peekNext() -> String? {
        guard position + 1 < tokens.count else { return nil }
        return tokens[position + 1]
    }

    func readForm() throws -> DataType {
        let token = peek()
        switch token?.first {
        case "(":
            if let next = peekNext(), next != ".", next.starts(with: ".")  {
                return try readDotForm()
            }
            else {
                return try readList()
            }

        case "[":
            return try readVector()

        case "{":
            return try readHash()

        case "'":
            return try readQuote()

        case "`":
            return try readQuasiquote()

        case "~":
            if token == "~@" {
                return try readSpliceUnquote()
            }
            else {
                return try readUnquote()
            }

        case "@":
            return try readDeref()

        case "^":
            return try readWithMeta()

        default:
            return try readAtom()
        }
    }

    private func readList() throws -> List {
        next() // consume open paren

        let list = List()
        while peek() != ")" {
            let form = try readForm()
            list.append(form)
        }

        next() // consume close paren
        return list
    }

    private func readVector() throws -> Vector {
        next() // consume open [

        let vector = Vector()
        while peek() != "]" {
            let form = try readForm()
            vector.append(form)
        }

        next() // consume close ]
        return vector
    }

    private func readHash() throws -> HashMap {
        next() // consume open {

        let hash = HashMap()
        while peek() != "}" {
            let form = try readForm()
            hash.append(form)
        }

        next() // consume close }
        return hash
    }

    private func readQuote() throws -> List {
        next() // consume '
        let form = try readForm()
        let list = List()
        list.append(Symbol("quote"))
        list.append(form)
        return list
    }

    private func readQuasiquote() throws -> List {
        next() // consume `
        let form = try readForm()
        let list = List()
        list.append(Symbol("quasiquote"))
        list.append(form)
        return list
    }

    private func readUnquote() throws -> List {
        next() // consume ~
        let form = try readForm()
        let list = List()
        list.append(Symbol("unquote"))
        list.append(form)
        return list
    }

    private func readSpliceUnquote() throws -> List {
        next() // consume ~@
        let form = try readForm()
        let list = List()
        list.append(Symbol("splice-unquote"))
        list.append(form)
        return list
    }

    private func readDotForm() throws -> List {
        next() // consume open paren

        let list = List()

        guard let dotMessage = try readForm() as? Symbol else { throw SwiftLispError.invalidOperation }
        list.append(Symbol("objc"))
        let message = String(dotMessage.name.dropFirst())
        let messageSymbol = Symbol(message)
        list.append(messageSymbol)

        while peek() != ")" {
            let form = try readForm()
            list.append(form)
        }

        next() // consume close paren
        return list
    }

    private func readDeref() throws -> List {
        next() // consume @
        let form = try readForm()
        let list = List()
        list.append(Symbol("deref"))
        list.append(form)
        return list
    }

    private func readWithMeta() throws -> List {
        next() // consume ^
        let meta = try readForm()
        let form = try readForm()
        let list = List()
        list.append(Symbol("with-meta"))
        list.append(form)
        list.append(meta)
        return list
    }

    private func readAtom() throws -> DataType {
        guard let token = next() else {
            throw SwiftLispError.unexpectedEndOfInput
        }

        if token.starts(with: "\"") {
            guard token.last == "\"" else { throw SwiftLispError.unexpectedEndOfInput }
            let stripped = token.dropFirst().dropLast()
            let result = stripped.replacingOccurrences(of: "\\\\", with: "\u{029E}")
                .replacingOccurrences(of: "\\\"", with: "\"")
                .replacingOccurrences(of: "\\n", with: "\n")
                .replacingOccurrences(of: "\u{029E}", with: "\\")
            return LispString(result)
        }

        if token == "nil" {
            return Nil
        }
        else if token == "true" || token == "false" {
            return Boolean.eval(token == "true")
        }
        else if let i = Int(token) {
            return Number(i)
        }
        else if token.starts(with: ":") {
            return Keyword(String(token.dropFirst()))
        }
        else {
            return Symbol(token)
        }
    }

}
