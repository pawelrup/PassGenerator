import XCTest
import Logging
import NIOCore
import NIOEmbedded
@testable import PassGenerator

final class PassGeneratorTests: XCTestCase {
    lazy var temporaryDirectoryURL = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(UUID().uuidString)

    let fileManager: FileManager = .default
    var logger = Logger(label: "PassGeneratorTests", factory: TestsLogHandler.standardOutput)
    lazy var config = PassGeneratorConfiguration(
        certificateURL: temporaryDirectoryURL,
        certificatePassword: "",
        wwdrURL: temporaryDirectoryURL,
        templateURL: temporaryDirectoryURL
    )
    let localizablesGenerator = LocalizablesGeneratorMock()
    let itemsCopier = ItemsCopierMock()
    let manifestGenerator = ManifestGeneratorMock()
    let pemGenerator = PemGeneratorMock()
    let signatureGenerator = SignatureGeneratorMock()
    let zipper = PassZipperMock()
    lazy var sut: PassGeneratorType = PassGenerator(
        configuration: config,
        localizablesGenerator: localizablesGenerator,
        itemsCopier: itemsCopier,
        manifestGenerator: manifestGenerator,
        pemGenerator: pemGenerator,
        signatureGenerator: signatureGenerator,
        zipper: zipper,
        logger: logger,
        fileManager: .default)
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        logger.logLevel = .debug
        try fileManager.createDirectory(at: temporaryDirectoryURL, withIntermediateDirectories: true)
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        
        try fileManager.removeItem(at: temporaryDirectoryURL)
    }
    
    func testGeneratePassSuccessfully() throws {
        let pass = Pass(description: [.en: "tests pass description"],
                        formatVersion: 1,
                        organizationName: "example",
                        passTypeIdentifier: "id",
                        serialNumber: UUID().uuidString,
                        teamIdentifier: "example")
        let eventLoop: EventLoop = EmbeddedEventLoop()
        zipper.zip = { url in
            try? "test".write(to: url, atomically: true, encoding: .utf8)
        }
        let data = try sut.generatePass(pass, to: temporaryDirectoryURL, on: eventLoop).wait()
        XCTAssertTrue(localizablesGenerator.callCount > 0, "Should call localizables generator at least once")
        XCTAssertTrue(itemsCopier.callCount > 0, "Should call items copier at least once")
        XCTAssertTrue(manifestGenerator.callCount > 0, "Should call manifest generator at least once")
        XCTAssertTrue(pemGenerator.generatePemKeyCallCount > 0, "Should call pem key generator at least once")
        XCTAssertTrue(pemGenerator.generatePemCertificateCallCount > 0, "Should call pem certificate generator at least once")
        XCTAssertTrue(signatureGenerator.callCount > 0, "Should call signature generator at least once")
        XCTAssertTrue(zipper.callCount > 0, "Should call zipper at least once")
        let result = String(decoding: data, as: UTF8.self)
        XCTAssertEqual(result, "test", "result should be equal to 'test'")
    }
}
