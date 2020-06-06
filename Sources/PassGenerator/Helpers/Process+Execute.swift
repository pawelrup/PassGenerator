import Foundation
import NIO
import Logging

/// Different types of process output.
public enum ProcessOutput {
    /// Standard process output.
    case stdout(Data)

    /// Standard process error output.
    case stderr(Data)
}

extension Process {
    /// Executes the supplied program in a new process, blocking until the process completes.
    /// Any data piped to `stdout` during the process will be returned as a string.
    /// If the process exits with a non-zero status code, an error will be thrown containing
    /// the contents of `stderr` and `stdout`.
    ///
    ///     let result = try Process.execute("echo", "hi")
    ///     print(result) /// "hi"
    ///
    /// - parameters:
    ///     - program: The name of the program to execute. If it does not begin with a `/`, the full
    ///                path will be resolved using `/bin/sh -c which ...`.
    ///     - arguments: An array of arguments to pass to the program.
    public static func execute(_ program: URL, in currentDirectoryURL: URL? = nil, _ arguments: String..., logger: Logger? = nil) throws -> String {
        return try execute(program, in: currentDirectoryURL, arguments, logger: logger)
    }

    /// Executes the supplied program in a new process, blocking until the process completes.
    /// Any data piped to `stdout` during the process will be returned as a string.
    /// If the process exits with a non-zero status code, an error will be thrown containing
    /// the contents of `stderr` and `stdout`.
    ///
    ///     let result = try Process.execute("echo", "hi")
    ///     print(result) /// "hi"
    ///
    /// - parameters:
    ///     - program: The name of the program to execute. If it does not begin with a `/`, the full
    ///                path will be resolved using `/bin/sh -c which ...`.
    ///     - arguments: An array of arguments to pass to the program.
    public static func execute(_ program: URL, in currentDirectoryURL: URL? = nil, _ arguments: [String], logger: Logger? = nil) throws -> String {
        var stderr: String = ""
        var stdout: String = ""
        let status = try asyncExecute(program, in: currentDirectoryURL, arguments, on: EmbeddedEventLoop()) { (output: ProcessOutput) in
            switch output {
            case .stderr(let data):
                stderr += String(data: data, encoding: .utf8) ?? ""
            case .stdout(let data):
                stdout += String(data: data, encoding: .utf8) ?? ""
            }
        }.wait()
        if status != 0 {
            throw ProcessExecuteError(status: status, stderr: stderr, stdout: stdout)
        }
        return stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Asynchronously the supplied program in a new process. Stderr and stdout will be supplied to the output closure
    /// as it is received. The returned future will finish when the process has terminated.
    ///
    ///     let status = try Process.asyncExecute("echo", "hi", on: ...) { output in
    ///         print(output)
    ///     }.wait()
    ///     print(result) // 0
    ///
    /// - parameters:
    ///     - program: The name of the program to execute. If it does not begin with a `/`, the full
    ///                path will be resolved using `/bin/sh -c which ...`.
    ///     - arguments: An array of arguments to pass to the program.
    ///     - worker: Worker to perform async task on.
    ///     - output: Handler for the process output.
    /// - returns: A future containing the termination status of the process.
    public static func asyncExecute(_ program: URL, in currentDirectoryURL: URL? = nil, _ arguments: String..., on eventLoop: EventLoop, logger: Logger? = nil, _ output: @escaping (ProcessOutput) -> ()) -> EventLoopFuture<Int32> {
        return asyncExecute(program, in: currentDirectoryURL, arguments, on: eventLoop, output)
    }

    /// Asynchronously the supplied program in a new process. Stderr and stdout will be supplied to the output closure
    /// as it is received. The returned future will finish when the process has terminated.
    ///
    ///     let status = try Process.asyncExecute("echo", ["hi"], on: ...) { output in
    ///         print(output)
    ///     }.wait()
    ///     print(result) // 0
    ///
    /// - parameters:
    ///     - program: The name of the program to execute. If it does not begin with a `/`, the full
    ///                path will be resolved using `/bin/sh -c which ...`.
    ///     - arguments: An array of arguments to pass to the program.
    ///     - worker: Worker to perform async task on.
    ///     - output: Handler for the process output.
    /// - returns: A future containing the termination status of the process.
    public static func asyncExecute(_ program: URL, in currentDirectoryURL: URL? = nil, _ arguments: [String], on eventLoop: EventLoop, logger: Logger? = nil, _ output: @escaping (ProcessOutput) -> ()) -> EventLoopFuture<Int32> {
        if program.path.hasPrefix("/") {
            let stdout = Pipe()
            let stderr = Pipe()

            // will be set to false when the program is done
            var running = true
            
            // readabilityHandler doesn't work on linux, so we are left with this hack
            DispatchQueue.global().async {
                while running {
                    let stdout = stdout.fileHandleForReading.availableData
                    if !stdout.isEmpty {
                        output(.stdout(stdout))
                    }
                }
            }
            DispatchQueue.global().async {
                while running {
                    let stderr = stderr.fileHandleForReading.availableData
                    if !stderr.isEmpty {
                        output(.stderr(stderr))
                    }
                }
            }

             stdout.fileHandleForReading.readabilityHandler = { handle in
                 let data = handle.availableData
                 guard !data.isEmpty else {
                     return
                 }
                 output(.stdout(data))
             }
             stderr.fileHandleForReading.readabilityHandler = { handle in
                 let data = handle.availableData
                 guard !data.isEmpty else {
                     return
                 }
                 output(.stderr(data))
             }
            let promise = eventLoop.makePromise(of: Int32.self)
            DispatchQueue.global().async {
                do {
                    let process = try launchProcess(at: program, in: currentDirectoryURL, arguments, stdout: stdout, stderr: stderr)
                    process.waitUntilExit()
                    running = false
                    promise.completeWith(.success(process.terminationStatus))
                } catch {
                    logger?.error("Launching process failed")
                    promise.completeWith(.failure(error))
                }
            }
            return promise.futureResult
        } else {
            var resolvedPath: String?
            return asyncExecute(URL(fileURLWithPath: "/bin/sh"), in: currentDirectoryURL, ["-c", "which \(program.unixPath)"], on: eventLoop, { (o: ProcessOutput) in
                switch o {
                case .stdout(let data): resolvedPath = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                default: break
                }
            }).flatMap { status in
                guard let path = resolvedPath, path.hasPrefix("/") else {
                    logger?.error("Process error: executable path not found")
                    return eventLoop.makeFailedFuture(ProcessError.executablePathNotFound)
                }
                return asyncExecute(URL(fileURLWithPath: path), in: currentDirectoryURL, arguments, on: eventLoop, output)
            }
        }
    }

    /// Powers `Process.execute(_:_:)` methods. Separated so that `/bin/sh -c which` can run as a separate command.
    private static func launchProcess(at executableURL: URL, in currentDirectoryURL: URL?, _ arguments: [String], stdout: Pipe, stderr: Pipe) throws -> Process {
        let process = Process()
        process.environment = ProcessInfo.processInfo.environment
        process.executableURL = executableURL
        process.currentDirectoryURL = currentDirectoryURL
        process.arguments = arguments
        process.standardOutput = stdout
        process.standardError = stderr
        try process.run()
        return process
    }
}

/// An error that can be thrown while using `Process.execute(_:_:)`
public struct ProcessExecuteError: Error {
    /// The exit status
    public let status: Int32

    /// Contents of `stderr`
    public var stderr: String

    /// Contents of `stdout`
    public var stdout: String
}

public enum ProcessError: Error {
    case executablePathNotFound
}
