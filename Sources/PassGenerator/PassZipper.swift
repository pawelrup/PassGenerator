import Foundation
import Logging
import NIOCore

protocol PassZipperType {
    func zipItems(in directoryURL: URL, to zipURL: URL, on eventLoop: EventLoop) -> EventLoopFuture<Void>
}

struct PassZipper: PassZipperType {
    private let logger: Logger
    
    init(logger: Logger) {
        self.logger = logger
    }
    
    func zipItems(in directoryURL: URL, to zipURL: URL, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        logger.debug("try zip items", metadata: [
            "directoryURL": .stringConvertible(directoryURL),
            "zipURL": .stringConvertible(zipURL)
        ])
        return Process.asyncExecute(
            URL(fileURLWithPath: "/usr/bin/zip"),
            in: directoryURL,
            zipURL.unixPath,
            "-r",
            "-q",
            ".",
            on: eventLoop,
            logger: logger, { (_: ProcessOutput) in })
        .flatMapThrowing { result in
            guard result == 0 else {
                logger.error("failed to zip items", metadata: [
                    "result": .stringConvertible(result)
                ])
                throw PassGeneratorError.cannotZip(terminationStatus: result)
            }
        }
    }
}
