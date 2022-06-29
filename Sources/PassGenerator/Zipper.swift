import Foundation
import Logging

protocol ZipperType {
    func zipItems(in directoryURL: URL, to zipURL: URL) async throws
}

struct Zipper: ZipperType {
    private let logger: Logger
    
    init(logger: Logger) {
        self.logger = logger
    }
    
    func zipItems(in directoryURL: URL, to zipURL: URL) async throws {
        logger.debug("try zip items", metadata: [
            "directoryURL": .stringConvertible(directoryURL),
            "zipURL": .stringConvertible(zipURL)
        ])
        let result = try await Process.asyncExecute(URL(fileURLWithPath: "/usr/bin/zip"),
                                                    in: directoryURL, zipURL.unixPath, "-r", "-q", ".")
        guard result == 0 else {
            logger.error("failed to zip items", metadata: [
                "result": .stringConvertible(result)
            ])
            throw PassGeneratorError.cannotZip(terminationStatus: result)
        }
    }
}
