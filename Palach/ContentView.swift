import SwiftUI

struct ContentView: View {
    @State private var selectedLanguage = LanguagesRegistry.languages.first!
    @State private var code: AttributedString = ""

    var body: some View {
        HSplitView {
            CodeEditorView(text: $code)
                .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
                .toolbar {
                    Menu {
                        ForEach(LanguagesRegistry.languages, id: \.self.name) { language in
                            Button(action: {
                                selectLanguage(language: language)
                            }) {
                                Text(language.name)
                            }
                        }
                    } label: {
                        Text(selectedLanguage.name)
                    }
                }

            if let rust = selectedLanguage as? Rust {
                RustExecutionView(rust: rust, code: $code)
                    .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
            } else if let java = selectedLanguage as? Java {
                JavaExecutionView(java: java, code: $code)
                    .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
            }
        }
        .onAppear {
            selectLanguage(language: self.selectedLanguage)
        }
    }

    private func selectLanguage(language: Language) {
        selectedLanguage = language
        code = AttributedString(language.snippet)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
