import CodeEditor
import SwiftUI

struct ContentView: View {
    @State private var selectedLanguage = LanguagesRegistry.languages.first!
    @State private var code = ""

    var body: some View {
        HSplitView {
            CodeEditor(
                source: $code,
                language: .swift,
                theme: .atelierSavannaDark,
                flags: [.selectable, .editable, .smartIndent],
                indentStyle: .softTab(width: 4)
            )
            .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
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
                    .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
            } else if let java = selectedLanguage as? Java {
                JavaExecutionView(java: java)
                    .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            selectLanguage(language: self.selectedLanguage)
        }
    }

    private func selectLanguage(language: Language) {
        selectedLanguage = language
        code = language.snippet
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
