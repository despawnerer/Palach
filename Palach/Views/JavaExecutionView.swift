import SwiftUI

struct JavaExecutionView: View {
    let java: Java
    let code: Binding<AttributedString>

    @State var jvm: JVM

    @ObservedObject var terminalLink = TerminalLink()

    var body: some View {
        SwiftUITerminal(terminalLink: terminalLink)
            .toolbar {
                ToolbarItemGroup {
                    Button(action: start) { Image(systemName: "play.fill") }

                    Button(action: stop) { Image(systemName: "stop.fill") }

                    Spacer()

                    Picker("", selection: $jvm) {
                        ForEach(java.jvms) { jvm in
                            Text(jvm.JVMName).tag(jvm as JVM)
                        }
                    }
                }
            }
    }

    init(java: Java, code: Binding<AttributedString>) {
        self.java = java
        self.code = code
        _jvm = State(initialValue: java.jvms.first!)
    }

    func start() {
        terminalLink.reset()
        terminalLink.feed(text: "Compiling...\n\r")

        let filename = writeTemporaryFile(
            ext: "java",
            data: String(code.wrappedValue.characters[...]).data(using: .utf8)!
        )

        terminalLink.startProcess(
            executable: jvm.JVMHomePath + "/bin/java",
            args: [filename]
        )
    }

    func stop() {
        terminalLink.terminate()
    }
}

// struct JavaExecutionView_Previews: PreviewProvider {
//    static var previews: some View {
//        JavaExecutionView(java: Java())
//    }
// }
