import Foundation
import SwiftTerm

public protocol CustomLocalProcessTerminalViewDelegate {
    func sizeChanged(source: CustomLocalProcessTerminalView, newCols: Int, newRows: Int)
    func setTerminalTitle(source: CustomLocalProcessTerminalView, title: String)
    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?)
    func processTerminated(source: TerminalView, exitCode: Int32?)
}

public class CustomLocalProcessTerminalView: TerminalView, TerminalViewDelegate, CustomLocalProcessDelegate {
    var process: CustomLocalProcess!

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init? (coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func setup() {
        terminalDelegate = self
        process = CustomLocalProcess(delegate: self)
    }

    /**
     * The `processDelegate` is used to deliver messages and information relevant t
     */
    public var processDelegate: CustomLocalProcessTerminalViewDelegate?

    /**
     * This method is invoked to notify the client of the new columsn and rows that have been set by the UI
     */
    public func sizeChanged(source _: TerminalView, newCols: Int, newRows: Int) {
        guard process.running else {
            return
        }
        var size = getWindowSize()
        _ = PseudoTerminalHelpers.setWinSize(masterPtyDescriptor: process.childfd, windowSize: &size)

        processDelegate?.sizeChanged(source: self, newCols: newCols, newRows: newRows)
    }

    /**
     * Invoke this method to notify the processDelegate of the new title for the terminal window
     */
    public func setTerminalTitle(source _: TerminalView, title: String) {
        processDelegate?.setTerminalTitle(source: self, title: title)
    }

    public func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        processDelegate?.hostCurrentDirectoryUpdate(source: source, directory: directory)
    }

    /**
     * This method is invoked when input from the user needs to be sent to the client
     */
    public func send(source _: TerminalView, data: ArraySlice<UInt8>) {
        process.send(data: data)
    }

    /**
     * Use this method to toggle the logging of data coming from the host, or pass nil to stop
     */
    public func setHostLogging(directory: String?) {
        process.setHostLogging(directory: directory)
    }

    public func scrolled(source _: TerminalView, position _: Double) {
        // noting
    }

    /**
     * Launches a child process inside a pseudo-terminal.
     * - Parameter executable: The executable to launch inside the pseudo terminal, defaults to /bin/bash
     * - Parameter args: an array of strings that is passed as the arguments to the underlying process
     * - Parameter environment: an array of environment variables to pass to the child process, if this is null, this picks a good set of defaults from `Terminal.getEnvironmentVariables`.
     * - Parameter execName: If provided, this is used as the Unix argv[0] parameter, otherwise, the executable is used as the args [0], this is used when the intent is to set a different process name than the file that backs it.
     */
    public func startProcess(executable: String = "/bin/bash", args: [String] = [], environment: [String]? = nil, execName: String? = nil)
    {
        process.startProcess(executable: executable, args: args, environment: environment, execName: execName)
    }

    public func terminateProcess(signal: Int32) {
        process.kill(signal: signal)
    }

    /**
     * Implements the LocalProcessDelegate method.
     */
    public func processTerminated(_: CustomLocalProcess, exitCode: Int32?) {
        processDelegate?.processTerminated(source: self, exitCode: exitCode)
    }

    /**
     * Implements the LocalProcessDelegate.dataReceived method
     */
    public func dataReceived(slice: ArraySlice<UInt8>) {
        feed(byteArray: slice)
    }

    /**
     * Implements the LocalProcessDelegate.getWindowSize method
     */
    public func getWindowSize() -> winsize {
        let f: CGRect = frame
        return winsize(ws_row: UInt16(getTerminal().rows), ws_col: UInt16(getTerminal().cols), ws_xpixel: UInt16(f.width), ws_ypixel: UInt16(f.height))
    }
}
