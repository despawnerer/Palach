import Foundation
import SwiftTerm

public protocol CustomLocalProcessDelegate: AnyObject {
    func processTerminated(_ source: CustomLocalProcess, exitCode: Int32?)
    func dataReceived(slice: ArraySlice<UInt8>)
    func getWindowSize() -> winsize
}

public class CustomLocalProcess {
    /* Our buffer for reading data from the child process */
    var readBuffer: [UInt8] = Array(repeating: 0, count: 8192)

    /* The file descriptor used to communicate with the child process */
    public private(set) var childfd: Int32 = -1

    /* The PID of our subprocess */
    var shellPid: pid_t = 0
    var debugIO = false

    /* number of sent requests */
    var sendCount = 0
    var total = 0

    weak var delegate: CustomLocalProcessDelegate?

    // Queue used to send the data received from the local process
    var dispatchQueue: DispatchQueue

    /**
     * Initializes the LocalProcess runner and communication with the host happens via the provided
     * `LocalProcessDelegate` instance.
     * - Parameter delegate: the delegate that will receive events or request data from your application
     * - Parameter dispatchQueue: this is the queue that will be used to post data received from the
     * child process when calling the `send(dataReceived:)` delegate method.  If the value provided is `nil`,
     * then this will default to `DispatchQueue.main`
     */
    public init(delegate: CustomLocalProcessDelegate, dispatchQueue: DispatchQueue? = nil) {
        self.delegate = delegate
        self.dispatchQueue = dispatchQueue ?? DispatchQueue.main
    }

    /**
     * Sends the array slice to the local process using DispatchIO
     * - Parameter data: The range of bytes to send to the child process
     */
    public func send(data: ArraySlice<UInt8>) {
        guard running
        else {
            return
        }
        let copy = sendCount
        sendCount += 1
        data.withUnsafeBytes { ptr in
            let ddata = DispatchData(bytes: ptr)
            let copyCount = ddata.count
            if debugIO {
                print("[SEND-\(copy)] Queuing data to client: \(data) ")
            }

            DispatchIO.write(toFileDescriptor: childfd, data: ddata, runningHandlerOn: DispatchQueue.global(qos: .userInitiated), handler: { _, errno in
                self.total += copyCount
                if self.debugIO {
                    print("[SEND-\(copy)] completed bytes=\(self.total)")
                }
                if errno != 0 {
                    print("Error writing data to the child, errno=\(errno)")
                }
            })
        }
    }

    /* Used to generate the next file name counter */
    var logFileCounter = 0

    /* Total number of bytes read */
    var totalRead = 0
    func childProcessRead(data: DispatchData, errno _: Int32) {
        if debugIO {
            totalRead += data.count
            print("[READ] count=\(data.count) received from host total=\(totalRead)")
        }

        if data.count == 0 {
            childfd = -1
            if running {
                running = false
                // delegate.processTerminated (self, exitCode: nil)
            }
            return
        }
        var b: [UInt8] = Array(repeating: 0, count: data.count)
        b.withUnsafeMutableBufferPointer { ptr in
            _ = data.copyBytes(to: ptr)
            if let dir = loggingDir {
                let path = dir + "/log-\(logFileCounter)"
                do {
                    let dataCopy = Data(ptr)
                    try dataCopy.write(to: URL(fileURLWithPath: path))
                    logFileCounter += 1
                } catch {
                    // Ignore write error
                    print("Got error while logging data dump to \(path): \(error)")
                }
            }
        }
        delegate?.dataReceived(slice: b[...])
        // print ("All data processed \(data.count)")
        DispatchIO.read(fromFileDescriptor: childfd, maxLength: readBuffer.count, runningHandlerOn: dispatchQueue, handler: childProcessRead)
    }

    var childMonitor: DispatchSourceProcess?

    func processTerminated() {
        var n: Int32 = 0
        waitpid(shellPid, &n, WNOHANG)
        delegate?.processTerminated(self, exitCode: n)
        running = false
    }

    /// Indicates if the child process is currently running
    public private(set) var running: Bool = false

    /**
     * Launches a child process inside a pseudo-terminal
     * - Parameter executable: The executable to launch inside the pseudo terminal, defaults to /bin/bash
     * - Parameter args: an array of strings that is passed as the arguments to the underlying process
     * - Parameter environment: an array of environment variables to pass to the child process, if this is null, this picks a good set of defaults from `Terminal.getEnvironmentVariables`.
     * - Parameter execName: If provided, this is used as the Unix argv[0] parameter, otherwise, the executable is used as the args [0], this is used when the intent is to set a different process name than the file that backs it.
     */
    public func startProcess(executable: String = "/bin/bash", args: [String] = [], environment: [String]? = nil, execName: String? = nil)
    {
        if running {
            return
        }
        var size = delegate?.getWindowSize() ?? winsize()

        var shellArgs = args
        if let firstArgName = execName {
            shellArgs.insert(firstArgName, at: 0)
        } else {
            shellArgs.insert(executable, at: 0)
        }

        var env: [String]
        if environment == nil {
            env = Terminal.getEnvironmentVariables(termName: "xterm-256color")
        } else {
            env = environment!
        }

        if let (shellPid, childfd) = PseudoTerminalHelpers.fork(andExec: executable, args: shellArgs, env: env, desiredWindowSize: &size)
        {
            childMonitor = DispatchSource.makeProcessSource(identifier: shellPid, eventMask: .exit, queue: dispatchQueue)
            if let cm = childMonitor {
                if #available(OSX 10.12, *) {
                    cm.activate()
                } else {
                    // Fallback on earlier versions
                }
                cm.setEventHandler(handler: processTerminated)
            }

            running = true
            self.childfd = childfd
            self.shellPid = shellPid
            DispatchIO.read(fromFileDescriptor: childfd, maxLength: readBuffer.count, runningHandlerOn: dispatchQueue, handler: childProcessRead)
        }
    }

    var loggingDir: String?

    /**
     * Use this method to toggle the logging of data coming from the host, or pass nil to stop
     * - Parameter directory: location where the log files will be stored.
     */
    public func setHostLogging(directory: String?) {
        loggingDir = directory
    }

    public func kill(signal: Int32) {
        guard running
        else {
            return
        }

        Darwin.kill(shellPid, signal)
    }
}
