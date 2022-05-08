import Foundation
import SwiftUI
import SwiftTerm

class SwiftUITerminalViewController: NSViewController {
    var terminalView: LocalProcessTerminalView?
    
    override func loadView() {
        self.view = NSView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        terminalView = LocalProcessTerminalView(frame: view.frame)
        terminalView!.configureNativeColors()
        terminalView!.startProcess()
        view.addSubview(terminalView!)
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        terminalView!.frame = view.frame
    }
}

final class SwiftUITerminalView: NSViewControllerRepresentable {
    typealias NSViewControllerType = SwiftUITerminalViewController
    
    func makeNSViewController(context: Context) -> SwiftUITerminalViewController {
        return SwiftUITerminalViewController()
    }
    
    func updateNSViewController(_ nsViewController: SwiftUITerminalViewController, context: Context) {
        // TODO
    }
}
