import Combine
import Foundation
import SwiftTerm
import SwiftUI

enum TerminalAction {
    case startProcess(executable: String, args: [String], environment: [String]?, execName: String?)
    case terminate(signal: Int32)
}

class TerminalLink: ObservableObject {
    @Published var action: TerminalAction?

    func startProcess(executable: String, args: [String] = [], environment: [String]? = nil, execName: String? = nil) {
        action = .startProcess(executable: executable, args: args, environment: environment, execName: execName)
    }

    func terminate(signal: Int32) {
        action = .terminate(signal: signal)
    }
}

class SwiftUITerminalViewController: NSViewController {
    var terminalView: CustomLocalProcessTerminalView?

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        terminalView = CustomLocalProcessTerminalView(frame: view.frame)
        terminalView!.configureNativeColors()
        view.addSubview(terminalView!)
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        terminalView!.frame = view.frame
    }

    func action(_ action: TerminalAction) {
        print("\(action)")
    }
}

struct SwiftUITerminalView: NSViewControllerRepresentable {
    typealias NSViewControllerType = SwiftUITerminalViewController

    var terminalLink: TerminalLink

    class Coordinator {
        var terminalLink: TerminalLink? {
            didSet {
                cancelable = terminalLink?.$action.sink(receiveValue: { action in
                    guard let action = action else {
                        return
                    }
                    self.viewController?.action(action)
                })
            }
        }

        var viewController: SwiftUITerminalViewController?

        private var cancelable: AnyCancellable?
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    func makeNSViewController(context _: Context) -> SwiftUITerminalViewController {
        return SwiftUITerminalViewController()
    }

    func updateNSViewController(_ nsViewController: SwiftUITerminalViewController, context: Context) {
        context.coordinator.viewController = nsViewController
        context.coordinator.terminalLink = terminalLink
    }
}
