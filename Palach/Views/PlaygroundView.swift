import SwiftUI

class PlaygroundViewModel: ObservableObject {
    @Published var languages: [LanguageOption: LanguageStatus]
    @Published var code: AttributedString
    @Published var selectedLanguage: LanguageOption {
        didSet {
            code = AttributedString(selectedLanguage.type().snippet)
        }
    }

    init(_ languages: [LanguageOption: LanguageStatus]) {
        let initialLanguage = languages.keys.first!
        self.languages = languages
        selectedLanguage = initialLanguage
        code = AttributedString(initialLanguage.type().snippet)
    }
}

struct PlaygroundView: View {
    @ObservedObject var viewModel: PlaygroundViewModel

    var body: some View {
        HSplitView {
            CodeEditorView(text: $viewModel.code)
                .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
                .toolbar {
                    Picker("", selection: $viewModel.selectedLanguage) {
                        ForEach(Array(viewModel.languages.keys)) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }

            if viewModel.selectedLanguage == .rust, case let .available(lang) = viewModel.languages[.rust] {
                RustExecutionView(rust: lang as! Rust, code: $viewModel.code)
                    .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
            } else if viewModel.selectedLanguage == .java, case let .available(lang) = viewModel.languages[.java] {
                JavaExecutionView(java: lang as! Java, code: $viewModel.code)
                    .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
            }
        }
    }

    init(_ options: [LanguageOption: LanguageStatus]) {
        viewModel = PlaygroundViewModel(options)
    }
}
