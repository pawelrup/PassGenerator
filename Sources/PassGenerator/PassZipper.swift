import Foundation
import Logging

protocol PassZipperType {
    func zipItems(in directoryURL: URL, to zipURL: URL) async throws
}

struct PassZipper: PassZipperType {
    private let logger: Logger
    
    init(logger: Logger) {
        self.logger = logger
    }
    
    func zipItems(in directoryURL: URL, to zipURL: URL) async throws {
        logger.debug("try zip items", metadata: [
            "directoryURL": .stringConvertible(directoryURL),
            "zipURL": .stringConvertible(zipURL)
        ])
        let result = try Process.execute(URL(fileURLWithPath: "/usr/bin/zip"),
                                         in: directoryURL,
                                         zipURL.unixPath,
                                         "-r",
                                         "-q",
                                         ".",
                                         logger: logger)
        guard result == "0" else {
            logger.error("failed to zip items", metadata: [
                "result": .stringConvertible(result)
            ])
            throw PassGeneratorError.cannotZip(terminationStatus: Int32(result)!)
        }
    }
}
