import SwiftUI

struct ContentView: View {
    @State var detectionState: LanguageDetectionState = .initial

    var body: some View {
        switch detectionState {
        case .initial:
            ProgressView().task {
                detectionState = try! await LanguageDetectionState.detect()
            }
        case let .detected(languages):
            PlaygroundView(languages)
        }
    }
}

// struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
// }
