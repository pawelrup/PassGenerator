import XCTest
import Logging
@testable import PassGenerator

final class PassGeneratorTests: XCTestCase {
    var logger = Logger(label: "PassGeneratorTests", factory: TestsLogHandler.standardOutput)
    lazy var config = PassGeneratorConfiguration(
        certificate: .init(url: URL(fileURLWithPath: ""), password: ""),
        wwdrURL: URL(fileURLWithPath: ""),
        templateURL: URL(fileURLWithPath: "")
    )
    let localizablesGenerator = LocalizablesGeneratorMock()
    let itemsCopier = ItemsCopierMock()
    let manifestGenerator = ManifestGeneratorMock()
    let pemGenerator = PemGeneratorMock()
    let signatureGenerator = SignatureGeneratorMock()
    let zipper = ZipperMock()
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
    
    override func setUp() {
        super.setUp()
        
        logger.logLevel = .debug
    }
    
    func testGeneratePassSuccessfully() async throws {
        logger.info(#function)
        let pass = Pass(description: [.en: "tests pass description"],
                        formatVersion: 1,
                        organizationName: "example",
                        passTypeIdentifier: "id",
                        serialNumber: UUID().uuidString,
                        teamIdentifier: "example")
        zipper.zip = { url in
            try? "test".write(to: url, atomically: true, encoding: .utf8)
        }
        let data = try await sut.generatePass(pass)
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
