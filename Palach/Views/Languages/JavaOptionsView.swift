import SwiftUI

struct JavaOptionsView: View {
    @ObservedObject var java: Java


    var body: some View {
        Picker("", selection: $java.jvm) {
            ForEach(java.jvms) { jvm in
                Text(jvm.JVMName).tag(jvm as JVM)
            }
        }
    }

    init(language: Java) {
        java = language
    }
}

#Preview {
    Text("Preview")
        .frame(width: 400, height: 50)
        .toolbar {
            JavaOptionsView(language: Java([JVM(JVMPlatformVersion: "abc", JVMEnabled: true, JVMHomePath: "abc", JVMName: "Zulu 11.66.19")]))
        }
}
