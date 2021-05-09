import Foundation
import CodeMirror_SwiftUI

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
    
    let name = "Rust"
    let ext = "rs"
    let codeMode = CodeMode.rust
    let snippet = """
    fn main() {
        println!("Hello, world!");
    }
    """

    var executors: [Executor]?

    func detectExecutors(completionHandler: @escaping ([Executor]) -> Void) throws {
        try launch(tool: Rust.RUSTUP, arguments: ["toolchain", "list"]) { (status, stdout) in
            print(String(decoding: stdout, as: UTF8.self))
            let executors = String(decoding: stdout, as: UTF8.self)
                .components(separatedBy: "\n")
                .filter { $0.count > 0 }
                .map { $0.components(separatedBy: " ")[0] }
                .map { RustExecutor(toolchain: $0) }
            
            self.executors = executors
            completionHandler(executors)
        }
    }
}

class RustExecutor: Executor {
    let name: String
    let binary: String

    init(toolchain: String) {
        self.name = toolchain
        self.binary = Rust.RUSTUP
    }
    
    func argumentsToRun(filename: String) -> [String] {
        /* FIXME:
         This doesn't actually work:
         - We also need to run the resulting binary
         - Rustc actually doesn't have rights to write into the temp directory for some reason
         */
        return ["run", self.name, "rustc", filename]
    }
}
