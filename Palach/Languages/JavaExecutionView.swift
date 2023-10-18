import SwiftUI

struct JavaExecutionView: View {
    private let java: Java
    private let code: Binding<AttributedString>

    @State private var status: JavaStatus = .uninitialized
    @State private var jvm: JVM?

    @ObservedObject private var terminalLink = TerminalLink()

    var body: some View {
        switch status {
        case .uninitialized:
            ProgressView().onAppear {
                /* FIXME: Error handling la la la la */
                try! java.detectJVMs {
                    self.status = java.status

                    if case let .available(jvms) = self.status {
                        self.jvm = jvms.first
                    }
                }
            }
        case .unavailable:
            Text("No Java toolchains were detected")
        case let .available(jvms):
            SwiftUITerminal(terminalLink: terminalLink)
                .toolbar {
                    ToolbarItemGroup {
                        Button(action: start) { Image(systemName: "play.fill") }

                        Button(action: stop) { Image(systemName: "stop.fill") }

                        Spacer()

                        Picker("", selection: $jvm) {
                            ForEach(jvms) { jvm in
                                Text(jvm.JVMName).tag(jvm as JVM?)
                            }
                        }
                    }
                }
        }
    }

    init(java: Java, code: Binding<AttributedString>) {
        self.java = java
        self.code = code
    }

    private func start() {
        terminalLink.reset()
        terminalLink.feed(text: "Compiling...\n\r")

        let filename = writeTemporaryFile(
            ext: "java",
            data: String(code.wrappedValue.characters[...]).data(using: .utf8)!
        )

        terminalLink.startProcess(
            executable: jvm!.JVMHomePath + "/bin/java",
            args: [filename]
        )
    }

    private func stop() {
        terminalLink.terminate()
    }
}

// struct JavaExecutionView_Previews: PreviewProvider {
//    static var previews: some View {
//        JavaExecutionView(java: Java())
//    }
// }
