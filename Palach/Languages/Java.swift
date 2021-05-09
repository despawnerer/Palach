import Foundation
import CodeMirror_SwiftUI

class Java: Language {
    let name = "Java"
    let ext = "java"
    let codeMode = CodeMode.java
    let snippet = """
    class Playground {
        public static void main(String[ ] args) {
            System.out.println("Hello Java");
        }
    }
    """

    var defaultExecutor: Executor?
    var executors: [Executor]?
    
    func detectExecutors(completionHandler: @escaping ([Executor]) -> Void) throws {
        let decoder = PropertyListDecoder();
        try launch(tool: "/usr/libexec/java_home", arguments: ["-X"]) { (status, stdout) in
            /* FIXME: what happens if the command fails? */
            /* FIXME: also, what happens if there aren't any javas around? */
            let executors = try? decoder.decode([JVM].self, from: stdout)
                .filter(\.JVMEnabled)
                .map { JavaExecutor(jvm: $0) }
            self.defaultExecutor = executors?.last
            self.executors = executors
            completionHandler(self.executors!) /* FIXME: Lol, probably a bad idea to just unwrap like that */
        }
    }
}

class JavaExecutor: Executor {
    let name: String
    let binary: String

    init(jvm: JVM) {
        self.name = jvm.JVMName
        self.binary = jvm.JVMHomePath + "/bin/java" /* FIXME: Concatenating strings to do paths is bad and I should feel bad */
    }
    
    func argumentsToRun(filename: String) -> [String] {
        return [filename]
    }
}

struct JVM: Codable {
    let JVMPlatformVersion: String
    let JVMEnabled: Bool
    let JVMHomePath: String
    let JVMName: String
}
