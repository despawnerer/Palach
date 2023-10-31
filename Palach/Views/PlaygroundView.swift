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

            switch languages[selectedLanguage]! {
            case .initial:
                ProgressView()
                    .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
                    .task {
                        languages[selectedLanguage] = try! await selectedLanguage.type().detect()
                    }
            case let .available(lang):
                SwiftUITerminal(terminalLink: terminalLink)
                    .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
                    .toolbar {
                        Button(action: start) { Image(systemName: "play.fill") }

                        Button(action: stop) { Image(systemName: "stop.fill") }

                        Spacer()

                        lang.optionsView()
                    }
            case .unavailable:
                Text("No valid toolchains available, sad story")
                    .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
            }
        }
    }

    init() {
        let initialLanguage = LanguageOption.allCases.first!
        languages = Dictionary(uniqueKeysWithValues: LanguageOption.allCases.map { ($0, .initial) })
        selectedLanguage = initialLanguage
        code = initialLanguage.type().snippet
    }

    func selectLanguage(_ value: LanguageOption) {
        code = value.type().snippet
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
