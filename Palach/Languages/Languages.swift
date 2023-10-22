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
    associatedtype OptionsType

    static var name: String { get }
    static var snippet: String { get }

    static func detect() async throws -> LanguageStatus

    func optionsView() -> AnyView
    func execute(code: String, terminal: TerminalLink) throws
}

enum LanguageStatus {
    case available(any Language)
    case unavailable
}

enum LanguageDetectionState {
    case initial
    case detected([LanguageOption: LanguageStatus])

    static func detect() async throws -> LanguageDetectionState {
        try await withThrowingTaskGroup(of: (LanguageOption, LanguageStatus).self) { group in
            for option in LanguageOption.allCases {
                group.addTask {
                    let status = try await option.type().detect()
                    return (option, status)
                }
            }

            var languages = [LanguageOption: LanguageStatus]()

            for try await(option, status) in group {
                languages[option] = status
            }

            /* TODO: Add a separate state for when nothing is available? */
            return .detected(languages)
        }
    }
}
