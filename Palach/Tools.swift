import Foundation
import SwiftSlash
import SwiftUI

func writeTemporaryFile(ext: String, data: Data) -> String {
    let temporaryDirectoryURL = FileManager.default.temporaryDirectory
    let temporaryFilename = UUID().uuidString + "." + ext
    let temporaryFileURL =
        temporaryDirectoryURL.appendingPathComponent(temporaryFilename)

    try! data.write(to: temporaryFileURL,
                    options: .atomic)

    return temporaryFileURL.path
}

struct ExecutionResult {
    /// A convenience boolean that is set to `true` when `exitCode` is `0`
    public let succeeded: Bool
    /// The exit code of the process
    public let exitCode: Int32
    /// The data that was written to `STDOUT` by the process.
    public let stdout: Data
    /// The data that was written to `STDERR` by the process.
    public let stderr: Data

    init(exitCode: Int32, stdout: Data, stderr: Data) {
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
        if exitCode == 0 {
            succeeded = true
        } else {
            succeeded = false
        }
    }
}

func executeCommand(_ execute: String,
                    arguments: [String] = [String](),
                    environment: [String: String] = CurrentProcessState.getCurrentEnvironmentVariables(),
                    workingDirectory: URL = CurrentProcessState.getCurrentWorkingDirectory()) async throws -> ExecutionResult
{
    let command = try Command(execute, arguments: arguments, environment: environment, workingDirectory: workingDirectory)
    let procInterface = ProcessInterface(command: command, stdout: .active(.unparsedRaw), stderr: .active(.unparsedRaw))
    try await procInterface.launch()
    // add the stdout task
    var stdoutBlob = Data()
    for await stdoutChunk in await procInterface.stdout {
        stdoutBlob += stdoutChunk
    }

    // add the stderr task
    var stderrBlob = Data()
    for await stderrChunk in await procInterface.stderr {
        stderrBlob += stderrChunk
    }
    let exitCode = try await procInterface.exitCode()
    return ExecutionResult(exitCode: exitCode, stdout: stdoutBlob, stderr: stderrBlob)
}
