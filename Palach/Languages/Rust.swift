import Foundation

class Rust: Language {
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

    let toolchains: [RustToolchain]

    init(_ toolchains: [RustToolchain]) {
        self.toolchains = toolchains
    }

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
