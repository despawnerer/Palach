import SwiftUI

struct ContentView: View {
    @State private var selectedLanguage: LanguageOption = .java
    @State private var code: AttributedString = ""

    var body: some View {
        HSplitView {
            CodeEditorView(text: $code)
                .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
                .toolbar {
                    Picker("", selection: $selectedLanguage) {
                        ForEach(LanguageOption.allCases) { lang in
                            Text(lang.rawValue).tag(lang)
                        }
                    }
                }

            if selectedLanguage == .rust {
                RustExecutionView(rust: selectedLanguage.instance() as! Rust, code: $code)
                    .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
            } else if selectedLanguage == .java {
                JavaExecutionView(java: selectedLanguage.instance() as! Java, code: $code)
                    .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
            }
        }
        .onAppear {
            selectLanguage(language: self.selectedLanguage)
        }
    }

    private func selectLanguage(language: LanguageOption) {
        selectedLanguage = language
        code = AttributedString(language.instance().snippet)
    }
}

// struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
// }
