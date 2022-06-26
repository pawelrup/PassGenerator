import Foundation
import Logging

protocol ItemsCopierType {
    func copyItems(from templateDirectory: URL, to passDirectory: URL) async throws
}

struct ItemsCopier: ItemsCopierType {
    private let logger: Logger
    private let fileManager: FileManager
    
    init(logger: Logger, fileManager: FileManager) {
        self.logger = logger
        self.fileManager = fileManager
    }
    
    func copyItems(from templateDirectory: URL, to passDirectory: URL) async throws {
        logger.debug("try copy items", metadata: [
            "from": .stringConvertible(templateDirectory),
            "to": .stringConvertible(passDirectory)
        ])
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
    }
}
