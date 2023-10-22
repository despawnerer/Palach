import SwiftUI

struct PlaygroundView: View {
    @State var languages: [LanguageOption: LanguageStatus]
    @State var selectedLanguage: LanguageOption

    @State var code: String
    @State var selection: NSRange?

    @ObservedObject var terminalLink = TerminalLink()

    var body: some View {
        HSplitView {
            CodeEditorView(text: $code, selection: $selection)
                .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
                .toolbar {
                    Picker("", selection: $selectedLanguage.onChange(selectLanguage)) {
                        ForEach(Array(languages.keys)) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }

            SwiftUITerminal(terminalLink: terminalLink)
                .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
                .toolbar {
                    ToolbarItemGroup {
                        Button(action: start) { Image(systemName: "play.fill") }

                        Button(action: stop) { Image(systemName: "stop.fill") }

                        Spacer()

                        switch languages[selectedLanguage]! {
                        case let .available(lang):
                            lang.optionsView()
                        case .unavailable:
                            Text("No valid toolchains available, sad story")
                        }
                    }
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

    func start() {
        if case let .available(lang) = languages[selectedLanguage] {
            terminalLink.reset()
            terminalLink.feed(text: "Running...\n\r")
            /* TODO: Handle errors */
            try! lang.execute(code: code, terminal: terminalLink)
        }
    }

    func stop() {
        terminalLink.terminate()
    }
}
