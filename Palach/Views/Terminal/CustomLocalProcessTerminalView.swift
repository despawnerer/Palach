import AppKit
import Foundation
import SwiftTerm

protocol CustomLocalProcessTerminalViewDelegate: AnyObject {
    func sizeChanged(source: CustomLocalProcessTerminalView, newCols: Int, newRows: Int)
    func setTerminalTitle(source: CustomLocalProcessTerminalView, title: String)
    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?)
    func processTerminated(source: TerminalView, exitCode: Int32?)
}

class CustomLocalProcessTerminalView: TerminalView, TerminalViewDelegate, LocalProcessDelegate {
    var process: LocalProcess!

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
        process = LocalProcess(delegate: self)
    }

    public func terminateRunningProcess() {
        process.terminate()
    }

    /**
     * The `processDelegate` is used to deliver messages and information relevant t
     */
    public weak var processDelegate: CustomLocalProcessTerminalViewDelegate?

    /**
     * This method is invoked to notify the client of the new columsn and rows that have been set by the UI
     */
    public func sizeChanged(source _: TerminalView, newCols: Int, newRows: Int) {
        guard process.running else {
            return
        }
        var size = getWindowSize()
        let _ = PseudoTerminalHelpers.setWinSize(masterPtyDescriptor: process.childfd, windowSize: &size)

        processDelegate?.sizeChanged(source: self, newCols: newCols, newRows: newRows)
    }

    public func clipboardCopy(source _: TerminalView, content: Data) {
        if let str = String(bytes: content, encoding: .utf8) {
            let pasteBoard = NSPasteboard.general
            pasteBoard.clearContents()
            pasteBoard.writeObjects([str as NSString])
        }
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
     * Implementation of the TerminalViewDelegate method
     */
    open func send(source _: TerminalView, data: ArraySlice<UInt8>) {
        process.send(data: data)
    }

    /**
     * Use this method to toggle the logging of data coming from the host, or pass nil to stop
     */
    public func setHostLogging(directory: String?) {
        process.setHostLogging(directory: directory)
    }

    /// Implementation of the TerminalViewDelegate method
    open func scrolled(source _: TerminalView, position _: Double) {
        // noting
    }

    open func rangeChanged(source _: TerminalView, startY _: Int, endY _: Int) {
        //
    }

    /**
     * Launches a child process inside a pseudo-terminal.
     * - Parameter executable: The executable to launch inside the pseudo terminal, defaults to /bin/bash
     * - Parameter args: an array of strings that is passed as the arguments to the underlying process
     * - Parameter environment: an array of environment variables to pass to the child process, if this is null, this picks a good set of defaults from `Terminal.getEnvironmentVariables`.
     * - Parameter execName: If provided, this is used as the Unix argv[0] parameter, otherwise, the executable is used as the args [0], this is used when the intent is to set a different process name than the file that backs it.
     */
    public func startProcess(executable: String = "/bin/bash", args: [String] = [], environment: [String]? = nil, execName: String? = nil) {
        process.startProcess(executable: executable, args: args, environment: environment, execName: execName)
    }

    /**
     * Implements the LocalProcessDelegate method.
     */
    open func processTerminated(_: LocalProcess, exitCode: Int32?) {
        processDelegate?.processTerminated(source: self, exitCode: exitCode)
    }

    /**
     * Implements the LocalProcessDelegate.dataReceived method
     */
    open func dataReceived(slice: ArraySlice<UInt8>) {
        feed(byteArray: slice)
    }

    /**
     * Implements the LocalProcessDelegate.getWindowSize method
     */
    open func getWindowSize() -> winsize {
        let f: CGRect = frame
        return winsize(ws_row: UInt16(getTerminal().rows), ws_col: UInt16(getTerminal().cols), ws_xpixel: UInt16(f.width), ws_ypixel: UInt16(f.height))
    }
}
