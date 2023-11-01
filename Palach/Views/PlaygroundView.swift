import SwiftUI

struct PlaygroundView: View {
    @State var selectedLanguage = LanguageOption.allCases.first!
    @State var languageStatus: LanguageStatus = .initial
    @State var code = LanguageOption.allCases.first!.type().snippet
    @State var selection: NSRange?

    @ObservedObject var terminalState = TerminalState()

    var body: some View {
        HSplitView {
            CodeEditorView(text: $code, selection: $selection)
                .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
                .toolbar {
                    Picker("", selection: $selectedLanguage) {
                        ForEach(LanguageOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }

            switch languageStatus {
            case .initial:
                ProgressView()
                    .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
            case let .available(lang):
                SwiftUITerminal(terminalState: terminalState)
                    .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
                    .toolbar {
                        if terminalState.isRunning {
                            Button(action: stop) { Image(systemName: "stop.fill") }
                        } else {
                            Button(action: start) { Image(systemName: "play.fill") }
                        }

                        Spacer()

                        lang.optionsView()
                    }
            case .unavailable:
                Text("No valid toolchains available, sad story")
                    .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
            }
        }
        .onAppear(perform: updateLanguagueState)
        .onChange(of: selectedLanguage, perform: onSelectedLanguageChange)
    }

    func selectLanguage(_ value: LanguageOption) {
        code = value.type().snippet
    }

    func start() {
        if case let .available(lang) = languageStatus {
            terminalState.reset()
            terminalState.feed(text: "Running...\n\r")
            /* TODO: Handle errors */
            try! lang.execute(code: code, terminal: terminalState)
        }
    }

    func stop() {
        terminalState.terminateProcess()
    }

    func updateLanguagueState() {
        Task {
            languageStatus = try! await selectedLanguage.type().detect()
        }
    }

    func onSelectedLanguageChange(_ newValue: LanguageOption) {
        terminalState.reset()
        updateLanguagueState()
        code = newValue.type().snippet
    }
}
