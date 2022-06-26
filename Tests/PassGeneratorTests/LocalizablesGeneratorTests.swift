import XCTest
import Logging
@testable import PassGenerator

struct LocalizableMock: Localizable {
    var strings: [PassLanguage : [String : String]]
}

final class LocalizablesGeneratorTests: XCTestCase {
    lazy var temporaryDirectoryURL = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(UUID().uuidString)
    var passURL: URL {
        temporaryDirectoryURL.appendingPathComponent("pass")
    }
    let fileManager: FileManager = .default
    var logger = Logger(label: "LocalizablesGeneratorTests", factory: TestsLogHandler.standardOutput)
    lazy var sut: LocalizablesGeneratorType = LocalizablesGenerator(logger: logger, fileManager: fileManager)
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        logger.logLevel = .debug
        try fileManager.createDirectory(at: temporaryDirectoryURL, withIntermediateDirectories: true)
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        
        try fileManager.removeItem(at: temporaryDirectoryURL)
    }
    
    func testLocalizablesSuccessfullySavedForAllLanguages() throws {
        logger.info(#function)
        let localizable = LocalizableMock(strings: [
            .pl: ["key": "value"],
            .en: ["key": "value"]
        ])
        try sut.generateLocalizables(for: localizable, in: passURL)
        
        var isDir: ObjCBool = true
        XCTAssertTrue(fileManager.fileExists(atPath: passURL.path, isDirectory: &isDir),
                      "Pass directory should exist at \(passURL)")
        let lprojDirectories = try fileManager.contentsOfDirectory(atPath: passURL.path)
        XCTAssertTrue(lprojDirectories.contains("pl.lproj"), "Should contain pl.lproj directory")
        XCTAssertTrue(lprojDirectories.contains("en.lproj"), "Should contain en.lproj directory")
        
        let plLprojFileURL = passURL.appendingPathComponent("pl.lproj", isDirectory: true)
            .appendingPathComponent("pass.strings")
        let plLprojFile = try String(contentsOfFile: plLprojFileURL.path, encoding: .utf8)
        XCTAssertTrue(plLprojFile.contains(#""key" = "value";"#),
                      "Strings file should contain string with key and value")
        
        let enLprojFileURL = passURL.appendingPathComponent("en.lproj", isDirectory: true)
            .appendingPathComponent("pass.strings")
        let enLprojFile = try String(contentsOfFile: enLprojFileURL.path, encoding: .utf8)
        XCTAssertTrue(enLprojFile.contains(#""key" = "value";"#),
                      "Strings file should contain string with key and value")
    }
    
    func testLocalizablesSuccessfullySavedEmptyFileForEmptyStrings() throws {
        logger.info(#function)
        let localizable = LocalizableMock(strings: [
            .pl: [:]
        ])
        try sut.generateLocalizables(for: localizable, in: passURL)
        
        var isDir: ObjCBool = true
        XCTAssertTrue(fileManager.fileExists(atPath: passURL.path, isDirectory: &isDir),
                      "Pass directory should exist at \(passURL)")
        let lprojDirectories = try fileManager.contentsOfDirectory(atPath: passURL.path)
        XCTAssertTrue(lprojDirectories.contains("pl.lproj"), "Should contain pl.lproj directory")
        
        let plLprojFileURL = passURL.appendingPathComponent("pl.lproj", isDirectory: true)
            .appendingPathComponent("pass.strings")
        let plLprojFile = try String(contentsOfFile: plLprojFileURL.path, encoding: .utf8)
        XCTAssertTrue(plLprojFile.isEmpty, "Strings file should be empty")
    }
    
    func testLocalizablesDoesNothingForEmpty() throws {
        logger.info(#function)
        let localizable = LocalizableMock(strings: [:])
        try sut.generateLocalizables(for: localizable, in: passURL)
        
        var isDir: ObjCBool = true
        XCTAssertFalse(fileManager.fileExists(atPath: passURL.path, isDirectory: &isDir),
                      "Pass directory should not exist at \(passURL)")
    }
}
