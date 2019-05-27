/**
    Environment stores all the bindings in the current scope and a reference
    to bindings in outer scopes
 */
class Environment {
    init() {
        outer = nil
    }

    init(outer: Environment) {
        self.outer = outer
    }

    init(binds: [Symbol], exprs: [DataType], outer: Environment? = nil) {
        self.outer = outer

        for index in 0..<binds.count {
            let symbol = binds[index]
            if symbol == "&" {
                let nextSymbol = binds[index + 1]
                data[nextSymbol] = List(exprs[index..<exprs.count])
                break
            }
            else {
                data[symbol] = exprs[index]
            }
        }
    }

    subscript(key: Symbol) -> DataType? {
        get {
            guard let env = find(key: key, env: self) else { return nil }
            return env.data[key]
        }

        set { data[key] = newValue }
    }

    private let outer: Environment?
    private var data: [Symbol: DataType] = [:]
}

private extension Environment {

    private func find(key: Symbol, env: Environment) -> Environment? {
        if env.data[key] != nil {
            return env
        }
        else if let outer = env.outer {
            return find(key: key, env: outer)
        }
        else {
            return nil
        }
    }

}

extension Environment: CustomStringConvertible {

    var description : String {
        return data.description
    }

}
