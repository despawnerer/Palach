import SwiftUI
import SwiftTerm
import CodeMirror_SwiftUI

struct ContentView: View {
    @State private var selectedLanguage = LanguagesRegistry.languages.first!;
    @State private var isLoadingExecutors = false;
    @State private var selectedExecutor: Executor?;
    @State private var sourceCode = "";
    @State private var output = "Program output will be here, stdin and stderr";
    
    var body: some View {
        HSplitView {
            CodeView(
                code: $sourceCode,
                mode: $selectedLanguage.wrappedValue.codeMode.mode(),
                showInvisibleCharacters: false
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
                    Text($selectedLanguage.wrappedValue.name)
                }
                
                if self.selectedLanguageHasExecutors() {
                    Menu {
                        ForEach(self.selectedLanguage.executors!, id: \.self.name) { executor in
                            Button(action: {
                                selectExecutor(executor: executor)
                            }) {
                                Text(executor.name)
                            }
                        }
                    } label: {
                        Text($selectedExecutor.wrappedValue!.name)
                    }
                } else if self.isLoadingExecutors {
                    ProgressView().scaleEffect(0.5)
                } else {
                    Text("Not installed")
                }
                
                Button(action: {
                    run()
                }, label: {
                    Image(systemName: "play.fill")
                }).disabled(!selectedLanguageHasExecutors())
            }
            
            TextEditor(text: $output)
                .font(.system(.body, design: .monospaced))
                .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            selectLanguage(language: self.selectedLanguage)
        }
    }
    
    private func run() {
        let executor = self.selectedExecutor!
        let filename = writeTemporaryFile(
            ext: self.selectedLanguage.ext,
            data: self.sourceCode.data(using: .utf8)!
        )

        try! launch(
            tool: executor.binary,
            arguments: executor.argumentsToRun(filename: filename)
        ) { (status, data) in
            print(status)
            print(data)
            self.output = String(decoding: data, as: UTF8.self) + "\n" + "Terminated with status " + String(status)
        }
    }
    
    private func selectedLanguageHasExecutors() -> Bool {
        return self.selectedLanguage.executors?.count ?? 0 > 0
    }
    
    private func selectLanguage(language: Language) {
        print("selecting " + language.name)
        let previousLanguage = self.selectedLanguage

        self.selectedLanguage = language
        self.sourceCode = language.snippet
        
        if language.executors == nil {
            self.isLoadingExecutors = true
            try! language.detectExecutors { _ in
                print("detected executors for " + language.name)
                if language.name == self.selectedLanguage.name {
                    afterLanguageChanged(previous: previousLanguage)
                }
            }
        } else {
            afterLanguageChanged(previous: previousLanguage)
        }
    }
    
    private func afterLanguageChanged(previous: Language) {
        self.isLoadingExecutors = false
        selectExecutor(executor: selectedLanguage.defaultExecutor)
    }
    
    private func selectExecutor(executor: Executor?) {
        self.selectedExecutor = executor
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
