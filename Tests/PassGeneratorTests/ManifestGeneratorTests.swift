import XCTest
import Logging
@testable import PassGenerator

final class ManifestGeneratorTests: XCTestCase {
    lazy var temporaryDirectoryURL = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(UUID().uuidString)
    var passURL: URL {
        temporaryDirectoryURL.appendingPathComponent("pass")
    }
    var manifestURL: URL {
        passURL.appendingPathComponent("manifest.json")
    }
    let fileManager: FileManager = .default
    var logger = Logger(label: "ManifestGeneratorTests", factory: TestsLogHandler.standardOutput)
    lazy var sut: ManifestGeneratorType = ManifestGenerator(logger: logger, fileManager: fileManager)
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        logger.logLevel = .debug
        try fileManager.createDirectory(at: temporaryDirectoryURL, withIntermediateDirectories: true)
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        
        try fileManager.removeItem(at: temporaryDirectoryURL)
    }
    
    func testSaveManifestSuccessfullyForNotEpmtyDirectory() async throws {
        logger.info(#function)
        try fileManager.createDirectory(at: passURL, withIntermediateDirectories: true)
        let testFileURL = passURL.appendingPathComponent("test")
        try Data("test".utf8).write(to: testFileURL)
        try await sut.generateManifest(for: passURL, in: manifestURL)
        let manifestExists = fileManager.fileExists(atPath: manifestURL.path)
        XCTAssertTrue(manifestExists, "manifest.json file should be created")
        let manifest = try Data(contentsOf: manifestURL)
        let result = try JSONDecoder().decode([String: String].self, from: manifest)
        XCTAssertEqual(result["test"], "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3",
                       "manifest.json should contain test sha")
    }
    
    func testSaveEmptyManifestSuccessfullyForEpmtyDirectory() async throws {
        logger.info(#function)
        try fileManager.createDirectory(at: passURL, withIntermediateDirectories: true)
        try await sut.generateManifest(for: passURL, in: manifestURL)
        let manifestExists = fileManager.fileExists(atPath: manifestURL.path)
        XCTAssertTrue(manifestExists, "manifest.json file should be created")
        let manifest = try Data(contentsOf: manifestURL)
        let result = try JSONDecoder().decode([String: String].self, from: manifest)
        XCTAssertTrue(result.keys.isEmpty, "manifest.json should be empty")
    }
    
    func testSaveManifestFailedForNotExistingDirectory() async throws {
        logger.info(#function)
        do {
            try await sut.generateManifest(for: passURL, in: manifestURL)
            XCTFail("Expected to throw while awaiting, but succeeded")
        } catch { }
        let manifestExists = fileManager.fileExists(atPath: manifestURL.path)
        XCTAssertFalse(manifestExists, "manifest.json file should not be created")
    }
}
