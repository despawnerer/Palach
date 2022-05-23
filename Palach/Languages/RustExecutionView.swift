import SwiftUI

struct RustExecutionView: View {
    private let rust: Rust
    private let code: Binding<String>

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
            SwiftUITerminalView(terminalLink: terminalLink)
                .toolbar {
                    Button(action: {
                        let filename = writeTemporaryFile(
                            ext: "rs",
                            data: self.code.wrappedValue.data(using: .utf8)!
                        )

                        let args = [
                            "-c",
                            "cd \(FileManager.default.temporaryDirectory.path) && \(Rust.RUSTUP) run \(toolchain!.name) rustc \(filename) && \(filename.dropLast(3))",
                        ]

                        var l: [String] = []
                        l.append("LANG=en_US.UTF-8")
                        let env = ProcessInfo.processInfo.environment
                        for x in ["LOGNAME", "USER", "DISPLAY", "LC_TYPE", "USER", "HOME", "PATH"] {
                            if env.keys.contains(x) {
                                l.append("\(x)=\(env[x]!)")
                            }
                        }

                        terminalLink.startProcess(
                            executable: "/bin/sh",
                            args: args,
                            environment: l
                        )
                    }, label: { Image(systemName: "play.fill") })

                    Button(action: {
                        terminalLink.terminate(signal: Darwin.SIGKILL)
                    }, label: { Image(systemName: "stop.fill") })

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

    init(rust: Rust, code: Binding<String>) {
        self.rust = rust
        self.code = code
        status = rust.status
    }
}

//
// struct RustExecutionView_Previews: PreviewProvider {
//    static var previews: some View {
//        RustExecutionView(rust: Rust(), code: "asdf")
//    }
// }
