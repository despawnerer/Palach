import SwiftUI

struct RustExecutionView: View {
    let rust: Rust
    let code: Binding<AttributedString>

    @State var toolchain: RustToolchain
    @State var edition: RustEdition = Rust.defaultEdition
    @State var mode: RustMode = Rust.defaultMode

    @ObservedObject var terminalLink = TerminalLink()

    var body: some View {
        SwiftUITerminal(terminalLink: terminalLink)
            .toolbar {
                ToolbarItemGroup {
                    Button(action: start) { Image(systemName: "play.fill") }

                    Button(action: stop) { Image(systemName: "stop.fill") }

                    Spacer()

                    Picker("", selection: $toolchain) {
                        ForEach(rust.toolchains) { toolchain in
                            Text(toolchain.name).tag(toolchain)
                        }
                    }

                    Picker("", selection: $edition) {
                        ForEach(RustEdition.allCases) { edition in
                            Text(edition.rawValue).tag(edition)
                        }
                    }

                    Picker("", selection: $mode) {
                        ForEach(RustMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                }
            }
    }

    init(rust: Rust, code: Binding<AttributedString>) {
        self.rust = rust
        self.code = code
        _toolchain = State(initialValue: rust.toolchains.first!)
    }

    private func start() {
        terminalLink.reset()
        terminalLink.feed(text: "Compiling...\n\r")

        let filename = writeTemporaryFile(
            ext: "rs",
            data: String(code.wrappedValue.characters[...]).data(using: .utf8)!
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

        terminalLink.startProcess(
            executable: "/bin/sh",
            args: args,
            environment: environment
        )
    }

    private func stop() {
        terminalLink.terminate()
    }
}

//
// struct RustExecutionView_Previews: PreviewProvider {
//    static var previews: some View {
//        RustExecutionView(rust: Rust(), code: "asdf")
//    }
// }
