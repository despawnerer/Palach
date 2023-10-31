import Foundation
import SwiftUI

enum LanguageOption: String, CaseIterable, Identifiable {
    case java = "Java"
    case rust = "Rust"

    var id: String { rawValue }

    func type() -> any Language.Type {
        switch self {
        case .java:
            return Java.self
        case .rust:
            return Rust.self
        }
    }
}

protocol Language {
    static var name: String { get }
    static var snippet: String { get }

    static func detect() async throws -> LanguageStatus

    func optionsView() -> AnyView
    func execute(code: String, terminal: TerminalLink) throws
}

enum LanguageStatus {
    case initial
    case available(any Language)
    case unavailable
}
