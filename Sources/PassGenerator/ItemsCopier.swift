import Foundation
import Logging
import NIOCore

protocol ItemsCopierType {
    func copyItems(from templateDirectory: URL, to passDirectory: URL, on eventLoop: EventLoop) -> EventLoopFuture<Void>
}

struct ItemsCopier: ItemsCopierType {
    private let logger: Logger
    private let fileManager: FileManager
    
    init(logger: Logger, fileManager: FileManager) {
        self.logger = logger
        self.fileManager = fileManager
    }
    
    func copyItems(from templateDirectory: URL, to passDirectory: URL, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        let promise = eventLoop.makePromise(of: Void.self)
        DispatchQueue.global().async {
            do {
                let lprojFiles = try fileManager
                    .contentsOfDirectory(atPath: passDirectory.path)
                    .filter { $0.contains("lproj") }
                if lprojFiles.isEmpty {
                    try fileManager.copyItem(at: templateDirectory, to: passDirectory)
                } else {
                    try lprojFiles.forEach { lprojFile in
                        try fileManager.contentsOfDirectory(atPath: templateDirectory.path).forEach { templateFile in
                            try fileManager.copyItem(
                                at: templateDirectory.appendingPathComponent(templateFile),
                                to: passDirectory.appendingPathComponent(lprojFile).appendingPathComponent(templateFile)
                            )
                        }
                    }
                }
                promise.succeed(())
            } catch {
                logger.error("failed to prepare pass")
                promise.fail(error)
            }
        }
        return promise.futureResult
    }
}
