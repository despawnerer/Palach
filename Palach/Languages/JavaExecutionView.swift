import SwiftUI

struct JavaExecutionView: View {
    private let java: Java
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
    
    init(java: Java) {
        self.java = java
    }
}

struct JavaExecutionView_Previews: PreviewProvider {
    static var previews: some View {
        JavaExecutionView(java: Java())
    }
}
