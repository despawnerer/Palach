import Foundation
import SwiftSlash
import SwiftUI

class JavaOptions: ObservableObject {
    @Published var jvm: JVM

    init(jvm: JVM) {
        self.jvm = jvm
    }
}

class Java: Language {
    typealias OptionsType = JavaOptions

    static let name = "Java"
    static let snippet = """
    class Playground {
        public static void main(String[] args) {
            System.out.println("Hello Java");
        }
    }
    """

    static func detect() async throws -> LanguageStatus {
        let decoder = PropertyListDecoder()

        let result = try await executeCommand(
            "/usr/libexec/java_home",
            arguments: ["-X"]
        )

        /* FIXME: what happens if the command fails? */
        /* FIXME: also, what happens if there aren't any javas around? */
        let jvms = try? decoder.decode([JVM].self, from: result.stdout)
            .filter(\.JVMEnabled)

        if jvms?.isEmpty ?? true {
            return .unavailable
        } else {
            return .available(Java(jvms!))
        }
    }

    let jvms: [JVM]
    let options: JavaOptions

    init(_ jvms: [JVM]) {
        self.jvms = jvms
        options = JavaOptions(jvm: jvms.first!)
    }

    func execute(code: String, terminal: TerminalLink) throws {
        let filename = writeTemporaryFile(
            ext: "java",
            data: code.data(using: .utf8)!
        )

        terminal.startProcess(
            executable: options.jvm.JVMHomePath + "/bin/java",
            args: [filename]
        )
    }

    func optionsView() -> AnyView {
        AnyView(JavaOptionsView(language: self))
    }
}

struct JVM: Codable, Hashable, Identifiable {
    let JVMPlatformVersion: String
    let JVMEnabled: Bool
    let JVMHomePath: String
    let JVMName: String

    var id: String { JVMName }
}
