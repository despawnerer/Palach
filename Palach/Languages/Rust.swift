import Foundation
import SwiftUI

class Rust: Language, ObservableObject {
    static let RUSTUP = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".cargo")
        .appendingPathComponent("bin")
        .appendingPathComponent("rustup")
        .path

    static let defaultEdition: RustEdition = .e2021
    static let defaultMode: RustMode = .release

    static let name = "Rust"
    static let snippet = """
    fn main() {
        println!("Hello, Rust!");
    }
    """

    static func detect() async throws -> LanguageStatus {
        let result = try await executeCommand(
            Rust.RUSTUP,
            arguments: ["toolchain", "list"]
        )

        /* TODO: Handle errors? */
        let toolchains: [RustToolchain] = String(decoding: result.stdout, as: UTF8.self)
            .components(separatedBy: "\n")
            .filter { $0.count > 0 }
            .map { $0.components(separatedBy: " ")[0] }
            .map { RustToolchain(name: $0) }

        if toolchains.isEmpty {
            return .unavailable
        } else {
            return .available(Rust(toolchains))
        }
    }

    @Published var toolchains: [RustToolchain]
    @Published var toolchain: RustToolchain
    @Published var mode: RustMode
    @Published var edition: RustEdition

    init(_ toolchains: [RustToolchain]) {
        self.toolchains = toolchains
        toolchain = toolchains.first!
        mode = Rust.defaultMode
        edition = Rust.defaultEdition
    }

    func execute(code: String, terminal: TerminalLink) throws {
        let filename = writeTemporaryFile(
            ext: "rs",
            data: code.data(using: .utf8)!
        )

        let modeArgs = mode == .debug ? "-C debuginfo=2 -C opt-level=0" : "-C debuginfo=0 -C opt-level=3"

        let args = [
            "-c",
            "cd \(FileManager.default.temporaryDirectory.path) && \(Rust.RUSTUP) run \(toolchain.name) rustc --edition \(edition.rawValue) \(modeArgs) \(filename) && \(filename.dropLast(3))",
        ]

        var environment: [String] = []
        environment.append("LANG=en_US.UTF-8")
        let currentEnv = ProcessInfo.processInfo.environment
        for variable in ["LOGNAME", "USER", "DISPLAY", "LC_TYPE", "USER", "HOME", "PATH"] {
            if currentEnv.keys.contains(variable) {
                environment.append("\(variable)=\(currentEnv[variable]!)")
            }
        }

        terminal.startProcess(
            executable: "/bin/sh",
            args: args,
            environment: environment
        )
    }

    func optionsView() -> AnyView {
        AnyView(RustOptionsView(language: self))
    }
}

enum RustMode: String, CaseIterable, Identifiable {
    case release = "Release"
    case debug = "Debug"

    var id: String { rawValue }
}

enum RustEdition: String, CaseIterable, Identifiable {
    case e2015 = "2015"
    case e2018 = "2018"
    case e2021 = "2021"
    case e2024 = "2024"

    var id: String { rawValue }
}

struct RustToolchain: Hashable, Identifiable {
    let name: String

    var id: String { name }
}
