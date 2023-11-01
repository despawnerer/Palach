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

class TerminalState: ObservableObject {
    @Published var action: TerminalAction?
    @Published var isRunning: Bool = false

    func reset() {
        action = .reset
    }

    func startProcess(executable: String, args: [String] = [], environment: [String]? = nil, execName: String? = nil) {
        action = .startProcess(executable: executable, args: args, environment: environment, execName: execName)
    }

    func terminateProcess() {
        action = .terminate
    }

    func feed(text: String) {
        action = .feed(text: text)
    }
}

class SwiftUITerminalViewController: NSViewController {
    var terminalView: CustomLocalProcessTerminalView?
    var delegate: CustomLocalProcessTerminalViewDelegate?

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
        terminalView?.terminateRunningProcess()
        terminalView?.removeFromSuperview()
        terminalView?.processDelegate = nil

        terminalView = CustomLocalProcessTerminalView(frame: view.frame)
        terminalView!.configureNativeColors()
        terminalView!.processDelegate = delegate
        view.addSubview(terminalView!)
    }
}

struct SwiftUITerminal: NSViewControllerRepresentable {
    typealias NSViewControllerType = SwiftUITerminalViewController

    var terminalState: TerminalState

    class Coordinator: CustomLocalProcessTerminalViewDelegate {
        var terminalState: TerminalState? {
            didSet {
                cancelable = terminalState?.$action.sink(receiveValue: { action in
                    guard let action = action else {
                        return
                    }
                    self.viewController?.action(action)

                    if case .startProcess = action {
                        self.terminalState?.isRunning = true
                    }
                })
            }
        }

        var viewController: SwiftUITerminalViewController?

        private var cancelable: AnyCancellable?

        func sizeChanged(source _: CustomLocalProcessTerminalView, newCols _: Int, newRows _: Int) {
            /* Don't care */
        }

        func setTerminalTitle(source _: CustomLocalProcessTerminalView, title _: String) {
            /* Don't care */
        }

        func hostCurrentDirectoryUpdate(source _: SwiftTerm.TerminalView, directory _: String?) {
            /* Don't care */
        }

        func processTerminated(source: SwiftTerm.TerminalView, exitCode: Int32?) {
            source.feed(text: "\r\n(Terminated with status \(exitCode ?? -1))\r\n")
            terminalState?.isRunning = false
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    func makeNSViewController(context: Context) -> SwiftUITerminalViewController {
        let controller = SwiftUITerminalViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateNSViewController(_ nsViewController: SwiftUITerminalViewController, context: Context) {
        context.coordinator.viewController = nsViewController
        context.coordinator.terminalState = terminalState
    }
}
