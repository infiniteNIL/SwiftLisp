import Foundation

private let rootEnv = Environment()

public func start() throws {
    defineBuiltinFunctionsAndVariables()
    try definePredefinedFunctions()
}

private func defineBuiltinFunctionsAndVariables() {
    for (key, function) in builtins {
        rootEnv[Symbol(key)] = Function(name: key, fn: function)
    }

    rootEnv[Symbol("eval")] = Function(name: "eval", fn: { try eval($0[0], env: rootEnv) })
    rootEnv[Symbol("*ARGV*")] = List()
    rootEnv[Symbol("*host-language*")] = LispString("SwiftLisp v0.1")
}

private func definePredefinedFunctions() throws {
    let codes: [String] = [
        """
        (defn load-file [f]
            (eval (read-string (str "(do " (slurp f) ")"))))
        """,

        """
        (defmacro cond [& xs]
            (if (> (count xs) 0)
                (list 'if (first xs) (if (> (count xs) 1) (nth xs 1) (throw "odd number of forms to cond"))
                (cons 'cond (rest (rest xs)))))))
        """,

        """
        (def *gensym-counter* (atom 0))
        """,

        """
        (defn gensym []
            (symbol (str "G__" (swap! *gensym-counter* (fn [x] (+ 1 x))))))
        """,

        """
        (defmacro or [& xs]
            (if (empty? xs)
                nil
                (if (= 1 (count xs))
                    (first xs)
                    (let [condvar (gensym)]
                        `(let [~condvar ~(first xs)] (if ~condvar ~condvar (or ~@(rest xs))))))))
        """,
    ]

    try codes.forEach { _ = try readEvalAndPrint($0) }
}

public func load(filename: String) throws {
    let args = List()
    CommandLine.arguments.dropFirst(2).forEach { args.append(LispString($0)) }
    rootEnv[Symbol("*ARGV*")] = args
    _ = try readEvalAndPrint("(load-file \"\(filename)\")")
}

public func readEvalAndPrint(_ s: String) throws -> String {
    return Printer.print(try eval(try Reader.read(s), env: rootEnv), printReadably: true)
}
