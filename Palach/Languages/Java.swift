import Foundation
import SwiftSlash

class Java: Language {
    static let name = "Java"
    static let snippet = """
    class Playground {
        public static void main(String[] args) {
            System.out.println("Hello Java");
        }
    }
    """

    let jvms: [JVM]

    init(_ jvms: [JVM]) {
        self.jvms = jvms
    }

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

    private func detectClassName(source _: String) -> String {
        // FIXME:
        return ""
    }
}

struct JVM: Codable, Hashable, Identifiable {
    let JVMPlatformVersion: String
    let JVMEnabled: Bool
    let JVMHomePath: String
    let JVMName: String

    var id: String { JVMName }
}
