import Foundation

class Java: Language {
    let name = "Java"
    let ext = "java"
//    let codeEditorLanguage = CodeLanguage.java
    let snippet = """
    class Playground {
        public static void main(String[] args) {
            System.out.println("Hello Java");
        }
    }
    """

    var status: JavaStatus = .uninitialized

    func detectJVMs(completionHandler: @escaping () -> Void) throws {
        let decoder = PropertyListDecoder()

        try launch(tool: "/usr/libexec/java_home", arguments: ["-X"]) { _, output in
            /* FIXME: what happens if the command fails? */
            /* FIXME: also, what happens if there aren't any javas around? */
            let jvms = try? decoder.decode([JVM].self, from: output)
                .filter(\.JVMEnabled)

            if jvms?.isEmpty ?? true {
                self.status = .unavailable
            } else {
                self.status = .available(jvms!)
            }

            completionHandler()
        }
    }

    private func detectClassName(source _: String) -> String {
        // FIXME:
        return ""
    }
}

enum JavaStatus {
    case uninitialized
    case unavailable
    case available([JVM])
}

struct JVM: Codable, Hashable, Identifiable {
    let JVMPlatformVersion: String
    let JVMEnabled: Bool
    let JVMHomePath: String
    let JVMName: String

    var id: String { JVMName }
}
