import Combine
import Foundation
import SwiftTerm
import SwiftUI

enum TerminalAction {
    case startProcess(executable: String, args: [String], environment: [String]?, execName: String?)
    case reset
    case terminate
    case feed(text: String)
}

class TerminalLink: ObservableObject {
    @Published var action: TerminalAction?

    func reset() {
        action = .reset
    }

    func startProcess(executable: String, args: [String] = [], environment: [String]? = nil, execName: String? = nil) {
        action = .startProcess(executable: executable, args: args, environment: environment, execName: execName)
    }

    func terminate() {
        action = .terminate
    }

    func feed(text: String) {
        action = .feed(text: text)
    }
}

class SwiftUITerminalViewController: NSViewController {
    var terminalView: CustomLocalProcessTerminalView?

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        resetTerminalView()
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        terminalView!.frame = view.frame
    }

    func action(_ action: TerminalAction) {
        switch action {
        case let .startProcess(executable, args, environment, execName):
            terminalView!.startProcess(executable: executable, args: args, environment: environment, execName: execName)
        case .terminate:
            terminalView!.terminateRunningProcess()
        case .reset:
            resetTerminalView()
        case let .feed(text):
            terminalView!.feed(text: text)
        }
    }

    func resetTerminalView() {
        terminalView?.removeFromSuperview()
        terminalView = CustomLocalProcessTerminalView(frame: view.frame)
        terminalView!.configureNativeColors()
        view.addSubview(terminalView!)
    }
}

struct SwiftUITerminal: NSViewControllerRepresentable {
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
