import Foundation
import Logging
import CryptoSwift

protocol ManifestGeneratorType {
    func generateManifest(for directoryURL: URL, in manifestURL: URL) async throws
}

struct ManifestGenerator: ManifestGeneratorType {
    private let logger: Logger
    private let fileManager: FileManager
    
    init(logger: Logger, fileManager: FileManager) {
        self.logger = logger
        self.fileManager = fileManager
    }
    
    func generateManifest(for directoryURL: URL, in manifestURL: URL) async throws {
        logger.debug("get contents of directory", metadata: [
            "directoryURL": .stringConvertible(directoryURL)
        ])
        var manifest: [String: String] = [:]
        try addContentsSHAs(to: &manifest, for: directoryURL)
        logger.debug("serialize manifest")
        let manifestData = try JSONSerialization.data(withJSONObject: manifest, options: .prettyPrinted)
        logger.debug("try write manifest", metadata: [
            "manifestURL": .stringConvertible(manifestURL)
        ])
        try manifestData.write(to: manifestURL)
    }
    
    private func addContentsSHAs(to manifest: inout [String: String], for directory: URL) throws {
        var isDir : ObjCBool = false
        if fileManager.fileExists(atPath: directory.path, isDirectory:&isDir) {
            if isDir.boolValue {
                // file exists and is a directory
                let contents = try fileManager.contentsOfDirectory(atPath: directory.path)
                try contents.forEach({ (item) in
                    let itemPath = directory.appendingPathComponent(item)
                    try addContentsSHAs(to: &manifest, for: itemPath)
                })
            } else {
                // file exists and is not a directory
                logger.debug("get contents of item", metadata: [
                    "item": .string(directory.lastPathComponent)
                ])
                guard let data = fileManager.contents(atPath: directory.path) else { return }
                logger.debug("generate sha1")
                var key = directory.lastPathComponent
                if let containingFolder = directory.pathComponents.last(where: { $0 != key }),
                   containingFolder.contains("lproj") {
                    key = "\(containingFolder)/\(key)"
                }
                manifest[key] = data.sha1().toHexString()
            }
        }
    }
}
