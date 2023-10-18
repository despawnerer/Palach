import Foundation
import SwiftUI

enum LanguageOption: String, CaseIterable, Identifiable {
    case java = "Java"
    case rust = "Rust"

    static let JAVA = Java()
    static let RUST = Rust()

    var id: String { rawValue }

    func instance() -> Language {
        switch self {
        case .java:
            return LanguageOption.JAVA
        case .rust:
            return LanguageOption.RUST
        }
    }
}

protocol Language {
    var name: String { get }
    var snippet: String { get }
    var ext: String { get }
//    var codeEditorLanguage: CodeLanguage { get }
}
