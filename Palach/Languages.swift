import Foundation
import CodeEditor
import SwiftUI

struct LanguagesRegistry {
    static let languages: [Language] = [
        Java(),
        Rust(),
    ]
}

protocol Language {
    var name: String { get }
    var snippet: String { get }
    var ext: String { get }
    var codeEditorLanguage: CodeEditor.Language { get }
}
