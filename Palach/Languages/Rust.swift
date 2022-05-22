import CodeEditor
import Foundation

class Rust: Language {
    /*
     FIXME:
     I don't fucking know how to get to rustup properly, without executing bash as an interactive shell.
     There has to be _some_ way?
     */
    static let RUSTUP = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".cargo")
        .appendingPathComponent("bin")
        .appendingPathComponent("rustup")
        .path

    static let defaultEdition: RustEdition = .e2018
    static let defaultMode: RustMode = .release

    let name = "Rust"
    let ext = "rs"
    let codeEditorLanguage = CodeEditor.Language.rust
    let snippet = """
    fn main() {
        println!("Hello, Rust!");
    }
    """

    var status: RustStatus = .uninitialized

    func maybeInitialize(completionHandler: @escaping () -> Void) throws {
        guard case .uninitialized = status else {
            completionHandler()
            return
        }

        try! detectToolchains(completionHandler: completionHandler)
    }

    func detectToolchains(completionHandler: @escaping () -> Void) throws {
        try launch(tool: Rust.RUSTUP, arguments: ["toolchain", "list"]) { _, output in
            let toolchains = String(decoding: output, as: UTF8.self)
                .components(separatedBy: "\n")
                .filter { $0.count > 0 }
                .map { $0.components(separatedBy: " ")[0] }
                .map { RustToolchain(name: $0) }

            if toolchains.isEmpty {
                self.status = .unavailable
            } else {
                self.status = .available(toolchains)
            }

            completionHandler()
        }
    }
}

enum RustStatus {
    case uninitialized
    case unavailable
    case available([RustToolchain])
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

    var id: String { rawValue }
}

struct RustToolchain: Hashable, Identifiable {
    let name: String

    var id: String { name }
}
