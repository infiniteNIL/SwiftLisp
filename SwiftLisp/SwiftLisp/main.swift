do {
    let cmdline = SwiftLispCommandLine()
    try cmdline.run()
}
catch {
    print("Whoops! An error occurred: \(error)")
}
