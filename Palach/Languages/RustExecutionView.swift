import SwiftUI

struct RustExecutionView: View {
    private let rust: Rust
    private let code: Binding<AttributedString>

    @State private var status: RustStatus = .uninitialized
    @State private var toolchain: RustToolchain?
    @State private var edition: RustEdition = Rust.defaultEdition
    @State private var mode: RustMode = Rust.defaultMode

    @ObservedObject private var terminalLink = TerminalLink()

    var body: some View {
        switch status {
        case .uninitialized:
            ProgressView().onAppear {
                /* FIXME: Error handling la la la la */
                try! rust.maybeInitialize {
                    self.status = rust.status

                    if case let .available(toolchains) = self.status {
                        self.toolchain = toolchains.first
                    }
                }
            }
        case .unavailable:
            Text("Rust is unavailable")
        case let .available(toolchains):
            SwiftUITerminal(terminalLink: terminalLink)
                .toolbar {
                    ToolbarItemGroup {
                        Button(action: start) { Image(systemName: "play.fill") }

                        Button(action: stop) { Image(systemName: "stop.fill") }

                        Spacer()

                        Picker("", selection: $toolchain) {
                            ForEach(toolchains) { toolchain in
                                Text(toolchain.name).tag(toolchain as RustToolchain?)
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
    }

    init(rust: Rust, code: Binding<AttributedString>) {
        self.rust = rust
        self.code = code
        status = rust.status
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
            "cd \(FileManager.default.temporaryDirectory.path) && \(Rust.RUSTUP) run \(toolchain!.name) rustc --edition \(edition.rawValue) \(modeArgs) \(filename) && \(filename.dropLast(3))",
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
