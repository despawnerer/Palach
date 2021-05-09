import Foundation

func writeTemporaryFile(ext: String, data: Data) -> String {
    let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(),
                                        isDirectory: true)
    let temporaryFilename = UUID().uuidString + "." + ext
    let temporaryFileURL =
        temporaryDirectoryURL.appendingPathComponent(temporaryFilename)
    
    try! data.write(to: temporaryFileURL,
                   options: .atomic)
    
    return temporaryFileURL.path
}

func launch(tool: String, arguments: [String], completionHandler: @escaping (Int32, Data) -> Void) throws {
    let group = DispatchGroup()
    let pipe = Pipe()
    var standardOutData = Data()

    group.enter()
    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: tool)
    proc.arguments = arguments
    proc.standardOutput = pipe.fileHandleForWriting
    proc.standardError = pipe.fileHandleForWriting
    proc.terminationHandler = { _ in
        proc.terminationHandler = nil
        group.leave()
    }

    group.enter()
    DispatchQueue.global().async {
        // Doing long-running synchronous I/O on a global concurrent queue block
        // is less than ideal, but I’ve convinced myself that it’s acceptable
        // given the target ‘market’ for this code.

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        pipe.fileHandleForReading.closeFile()
        DispatchQueue.main.async {
            standardOutData = data
            group.leave()
        }
    }

    group.notify(queue: .main) {
        completionHandler(proc.terminationStatus, standardOutData)
    }

    try proc.run()

    // We have to close our reference to the write side of the pipe so that the
    // termination of the child process triggers EOF on the read side.

    pipe.fileHandleForWriting.closeFile()
}
