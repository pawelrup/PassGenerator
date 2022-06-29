import XCTest
import Logging
@testable import PassGenerator

final class ZipperTests: XCTestCase {
    lazy var temporaryDirectoryURL = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(UUID().uuidString)
    var fileURL: URL {
        temporaryDirectoryURL.appendingPathComponent("test")
    }
    var zipURL: URL {
        temporaryDirectoryURL.appendingPathComponent("test").appendingPathExtension("zip")
    }
    let fileManager: FileManager = .default
    var logger = Logger(label: "ZipperTests", factory: TestsLogHandler.standardOutput)
    lazy var sut: ZipperType = Zipper(logger: logger)
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        logger.logLevel = .debug
        try fileManager.createDirectory(at: temporaryDirectoryURL, withIntermediateDirectories: true)
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        
        try fileManager.removeItem(at: temporaryDirectoryURL)
    }
    
    func testFileIsZippedSuccessfully() async throws {
        try "test".write(to: fileURL, atomically: true, encoding: .utf8)
        try await sut.zipItems(in: temporaryDirectoryURL, to: zipURL)
        let fileExists = fileManager.fileExists(atPath: zipURL.path)
        XCTAssertTrue(fileExists, "zip file should be created")
    }
    
    func testEmptyFilderZippingFailed() async throws {
        logger.info(#function)
        do {
            try await sut.zipItems(in: temporaryDirectoryURL, to: zipURL)
            XCTFail("Expected to throw while awaiting, but succeeded")
        } catch { }
        let fileExists = fileManager.fileExists(atPath: zipURL.path)
        XCTAssertFalse(fileExists, "zip file should not be created")
    }
}
