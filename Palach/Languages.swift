import Foundation
import CodeMirror_SwiftUI

struct LanguagesRegistry {
    static let languages: [Language] = [
        Java(),
//        Rust(),
    ]
}

protocol Executor {
    var name: String { get }
    var binary: String { get }

    func argumentsToRun(filename: String) -> [String]
}

protocol Language {
    var name: String { get }
    var snippet: String { get }
    var ext: String { get }
    var codeMode: CodeMode { get }

    var executors: [Executor]? { get }
    func detectExecutors(completionHandler: @escaping ([Executor]) -> Void) throws
}

extension Language {
    func getExecutor(binary: String) -> Executor? {
        return self.executors?.first(where: { $0.binary == binary })
    }
}
