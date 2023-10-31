import SwiftUI

struct RustOptionsView: View {
    @ObservedObject var rust: Rust

    var body: some View {
        Picker("", selection: $rust.toolchain) {
            ForEach(rust.toolchains) { toolchain in
                Text(toolchain.name).tag(toolchain)
            }
        }

        Picker("", selection: $rust.edition) {
            ForEach(RustEdition.allCases) { edition in
                Text(edition.rawValue).tag(edition)
            }
        }

        Picker("", selection: $rust.mode) {
            ForEach(RustMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
    }

    init(language: Rust) {
        rust = language
    }
}

#Preview {
    Text("Preview")
        .frame(width: 700, height: 50)
        .toolbar {
            RustOptionsView(language: Rust([RustToolchain(name: "stable-x86_64-apple-darwin")]))
        }
}
