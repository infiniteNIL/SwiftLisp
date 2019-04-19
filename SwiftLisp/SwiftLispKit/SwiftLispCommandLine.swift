import Foundation

public final class SwiftLispCommandLine {
    private let arguments: [String]

    public init(arguments: [String] = CommandLine.arguments) {
        self.arguments = arguments
    }

    public func run() throws {
        let repl = REPL()
        repl.run()
    }
}
