import SwiftUI

struct JavaOptionsView: View {
    let java: Java

    @ObservedObject var options: JavaOptions
    
    var body: some View {
        Picker("", selection: $options.jvm) {
            ForEach(java.jvms) { jvm in
                Text(jvm.JVMName).tag(jvm as JVM)
            }
        }
    }

    init(language: Java) {
        self.java = language
        self.options = language.options
    }
}
