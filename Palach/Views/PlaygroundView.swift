import SwiftUI

struct PlaygroundView: View {
    @State var languages: [LanguageOption: LanguageStatus]
    @State var code: String
    @State var selectedLanguage: LanguageOption

    var body: some View {
        HSplitView {
            CodeEditorView(text: $code)
                .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
                .toolbar {
                    Picker("", selection: $selectedLanguage.onChange(selectLanguage)) {
                        ForEach(Array(languages.keys)) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }

            if selectedLanguage == .rust, case let .available(lang) = languages[.rust] {
                RustExecutionView(rust: lang as! Rust, code: $code)
                    .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
            } else if selectedLanguage == .java, case let .available(lang) = languages[.java] {
                JavaExecutionView(java: lang as! Java, code: $code)
                    .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
            }
        }
    }

    init(_ languages: [LanguageOption: LanguageStatus]) {
        let initialLanguage = languages.keys.first!
        self.languages = languages
        selectedLanguage = initialLanguage
        code = initialLanguage.type().snippet
    }

    func selectLanguage(_ language: LanguageOption) {
        code = language.type().snippet
    }
}
