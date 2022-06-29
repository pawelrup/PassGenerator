import Foundation
import Logging

/// Different types of process output.
public enum ProcessOutput {
	/// Standard process output.
	case stdout(Data)
	
	/// Standard process error output.
	case stderr(Data)
}

extension Process {
    public typealias ProcessOutputClosure = (ProcessOutput) -> ()
	/// Asynchronously the supplied program in a new process. Stderr and stdout will be supplied to the output closure
	/// as it is received. The returned future will finish when the process has terminated.
	///
	///     let status = try await Process.asyncExecute("echo", "hi", on: ...) { output in
	///         print(output)
	///     }
	///     print(result) // 0
	///
	/// - parameters:
	///     - program: The name of the program to execute. If it does not begin with a `/`, the full
	///                path will be resolved using `/bin/sh -c which ...`.
	///     - arguments: An array of arguments to pass to the program.
	///     - output: Handler for the process output.
	/// - returns: A future containing the termination status of the process.
    public static func asyncExecute(_ program: URL, in currentDirectoryURL: URL? = nil, _ arguments: String..., output: @escaping ProcessOutputClosure = { _ in }) async throws -> Int32 {
		try await asyncExecute(program, in: currentDirectoryURL, arguments, output)
	}
    
    /// Asynchronously the supplied program in a new process. Stderr and stdout will be supplied to the output closure
    /// as it is received. The returned future will finish when the process has terminated.
    ///
    ///     let status = try await Process.asyncExecute("echo", ["hi"], on: ...) { output in
    ///         print(output)
    ///     }
    ///     print(result) // 0
    ///
    /// - parameters:
    ///     - program: The name of the program to execute. If it does not begin with a `/`, the full
    ///     path will be resolved using `/bin/sh -c which ...`.
    ///     - currentDirectoryURL: optionally curent directory url
    ///     - arguments: An array of arguments to pass to the program.
    ///     - output: Handler for the process output.
    /// - returns: Status of the process.
    @discardableResult
    public static func asyncExecute(_ program: URL, in currentDirectoryURL: URL? = nil, _ arguments: [String], _ output: @escaping ProcessOutputClosure) async throws -> Int32 {
        if program.path.hasPrefix("/") {
            let stdout = Pipe()
            let stderr = Pipe()
            
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
            return try await Task(priority: .userInitiated, operation: {
                let process = makeProcess(at: program, in: currentDirectoryURL, arguments, stdout: stdout, stderr: stderr)
                try process.run()
                process.waitUntilExit()
                return process.terminationStatus
            }).value
        } else {
            var resolvedPath: String?
            try await asyncExecute(URL(fileURLWithPath: "/bin/sh"), in: currentDirectoryURL, ["-c", "which \(program.unixPath)"]) { output in
                switch output {
                case .stdout(let data): resolvedPath = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                default: break
                }
            }
            guard let path = resolvedPath, path.hasPrefix("/") else {
                throw ProcessError.executablePathNotFound
            }
            return try await asyncExecute(URL(fileURLWithPath: path), in: currentDirectoryURL, arguments, output)
        }
    }
	
	/// Powers `Process.execute(_:_:)` methods. Separated so that `/bin/sh -c which` can run as a separate command.
	private static func makeProcess(at executableURL: URL, in currentDirectoryURL: URL?, _ arguments: [String], stdout: Pipe, stderr: Pipe) -> Process {
		let process = Process()
		process.environment = ProcessInfo.processInfo.environment
		process.executableURL = executableURL
		process.currentDirectoryURL = currentDirectoryURL
		process.arguments = arguments
		process.standardOutput = stdout
		process.standardError = stderr
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
