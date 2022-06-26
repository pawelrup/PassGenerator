import Foundation
import Logging

protocol LocalizablesGeneratorType {
    func generateLocalizables(for localizable: Localizable, in directory: URL) throws
}

class LocalizablesGenerator: LocalizablesGeneratorType {
    private let logger: Logger
    private let fileManager: FileManager
    
    init(logger: Logger, fileManager: FileManager = .default) {
        self.logger = logger
        self.fileManager = fileManager
    }
    
    func generateLocalizables(for localizable: Localizable, in directory: URL) throws {
        logger.debug("save localizables")
        for (language, strings) in localizable.strings {
            try save(strings: strings, for: language, in: directory)
        }
    }
    
    private func save(strings: [String: String], for language: PassLanguage, in directory: URL) throws {
        let lprojURL = directory
            .appendingPathComponent(language.rawValue)
            .appendingPathExtension("lproj")
        logger.debug("create lproj directory", metadata: [
            "language": .stringConvertible(language.rawValue),
            "lprojURL": .stringConvertible(lprojURL)
        ])
        try fileManager.createDirectory(at: lprojURL, withIntermediateDirectories: true, attributes: nil)
        let stringsFileURL = lprojURL
            .appendingPathComponent("pass")
            .appendingPathExtension("strings")
        logger.debug("save strings file", metadata: [
            "stringsFileURL": .stringConvertible(stringsFileURL)
        ])
        try strings
            .reduce("") { $0 + "\"\($1.key)\" = \"\($1.value)\";\n" }
            .write(to: stringsFileURL, atomically: true, encoding: .utf8)
    }
}
