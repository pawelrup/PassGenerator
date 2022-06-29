import Foundation
import Logging
import CryptoSwift

public enum PassGeneratorError: Error {
	case invalidPassJSON
	case cannotGenerateKey(terminationStatus: Int32)
	case cannotGenerateCertificate(terminationStatus: Int32)
	case cannotGenerateSignature(terminationStatus: Int32)
	case cannotZip(terminationStatus: Int32)
}

/// Creates configuration for a new `PassGenerator`.
/// - parameters:
///     - certificateURL: URL to the pass certificate.
///     - certificatePassword: Password of the pass certificate.
///     - wwdrURL: URL to the WWDR certificate https://developer.apple.com/certificationauthority/AppleWWDRCA.cer.
///     - templateURL: URL of the template to be used for the pass, containing the images etc.
public struct PassGeneratorConfiguration {
    public struct Certificate {
        let url: URL
        let password: String
        
        public init(url: URL, password: String) {
            self.url = url
            self.password = password
        }
    }
    let certificate: Certificate
    let wwdrURL: URL
    let templateURL: URL
    
    public init(certificate: Certificate, wwdrURL: URL, templateURL: URL) {
        self.certificate = certificate
        self.wwdrURL = wwdrURL
        self.templateURL = templateURL
    }
}

public protocol PassGeneratorType {
    init(configuration: PassGeneratorConfiguration, logger: Logger)
    func generatePass(_ pass: Pass) async throws -> Data
}

public struct PassGenerator: PassGeneratorType {
	private let configuration: PassGeneratorConfiguration
    private let localizablesGenerator: LocalizablesGeneratorType
    private let itemsCopier: ItemsCopierType
    private let manifestGenerator: ManifestGeneratorType
    private let pemGenerator: PEMGeneratorType
    private let signatureGenerator: SignatureGeneratorType
    private let zipper: ZipperType
	private let logger: Logger
    private let fileManager: FileManager
	
    init(configuration: PassGeneratorConfiguration, localizablesGenerator: LocalizablesGeneratorType,
         itemsCopier: ItemsCopierType, manifestGenerator: ManifestGeneratorType, pemGenerator: PEMGeneratorType,
         signatureGenerator: SignatureGeneratorType, zipper: ZipperType, logger: Logger, fileManager: FileManager) {
		self.configuration = configuration
        self.localizablesGenerator = localizablesGenerator
        self.itemsCopier = itemsCopier
        self.manifestGenerator = manifestGenerator
        self.pemGenerator = pemGenerator
        self.signatureGenerator = signatureGenerator
        self.zipper = zipper
		self.logger = logger
        self.fileManager = fileManager
	}
    
    public init(configuration: PassGeneratorConfiguration, logger: Logger) {
        let fileManager = FileManager.default
        self.init(configuration: configuration,
                  localizablesGenerator: LocalizablesGenerator(logger: logger, fileManager: fileManager),
                  itemsCopier: ItemsCopier(logger: logger, fileManager: fileManager),
                  manifestGenerator: ManifestGenerator(logger: logger, fileManager: fileManager),
                  pemGenerator: PEMGenerator(logger: logger),
                  signatureGenerator: SignatureGenerator(logger: logger),
                  zipper: Zipper(logger: logger),
                  logger: logger,
                  fileManager: fileManager)
    }
    
    /// Generate a signed .pkpass file
    /// - parameters:
    ///     - pass: A Pass object containing all pass information, ensure the `passTypeIdentifier` and `teamIdentifier` match those in supplied certificate.
    ///     - destination: The destination of the .pkpass to be saved, if nil the pass will be saved to the execution directory (generally the case if the result Data is used).
    /// - returns: A future containing the data of the generated pass.
    public func generatePass(_ pass: Pass) async throws -> Data {
        logger.debug("try prepare URLs")
        let cachesDirectory = try fileManager.url(for: .cachesDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: true)
        let temporaryDirectory = cachesDirectory.appendingPathComponent(UUID().uuidString)
        defer {
            try? fileManager.removeItem(at: temporaryDirectory)
        }
        try fileManager.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true, attributes: nil)
        let pkpassURL = temporaryDirectory.appendingPathComponent("pass.pkpass")
        let pemKeyURL = temporaryDirectory.appendingPathComponent("key.pem")
        let pemCertURL = temporaryDirectory.appendingPathComponent("cert.pem")
        let passDirectoryURL = temporaryDirectory.appendingPathComponent("pass")
        let manifestURL = passDirectoryURL.appendingPathComponent("manifest.json")
        let signatureURL = passDirectoryURL.appendingPathComponent("signature")
        logger.debug("URLs prepared", metadata: [
            "temporaryDirectoryURL": .stringConvertible(temporaryDirectory),
            "passDirectoryURL": .stringConvertible(passDirectoryURL),
            "pkpassURL": .stringConvertible(pkpassURL),
            "manifestURL": .stringConvertible(manifestURL),
            "signatureURL": .stringConvertible(signatureURL),
            "pemKeyURL": .stringConvertible(pemKeyURL),
            "pemCertURL": .stringConvertible(pemCertURL)
        ])
        let certificate = configuration.certificate
        try fileManager.createDirectory(at: passDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        try localizablesGenerator.generateLocalizables(for: pass, in: passDirectoryURL)
        try await itemsCopier.copyItems(from: configuration.templateURL, to: passDirectoryURL)
        try await generatePassJSON(from: pass, to: passDirectoryURL)
        try await manifestGenerator.generateManifest(for: passDirectoryURL, in: manifestURL)
        try await pemGenerator.generatePemKey(from: certificate.url, with: certificate.password, to: pemKeyURL)
        try await pemGenerator.generatePemCertificate(from: certificate.url, with: certificate.password, to: pemCertURL)
        try await signatureGenerator.generateSignature(
            pemCertURL: pemCertURL,
            pemKeyURL: pemKeyURL,
            wwdrURL: configuration.wwdrURL,
            manifestURL: manifestURL,
            signatureURL: signatureURL,
            certificatePassword: certificate.password)
        try await zipper.zipItems(in: passDirectoryURL, to: pkpassURL)
        let data = try Data(contentsOf: pkpassURL)
        return data
    }
}

private extension PassGenerator {
    func generatePassJSON(from pass: Pass, to passDirectory: URL) async throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mmZZZZZ"
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .formatted(formatter)
        let passData: Data
        do {
            passData = try jsonEncoder.encode(pass)
        } catch {
            logger.error("invalid json")
            throw PassGeneratorError.invalidPassJSON
        }
        let passURL = passDirectory.appendingPathComponent("pass.json")
        logger.debug("try write pass json", metadata: [
            "passURL": .stringConvertible(passURL)
        ])
        try passData.write(to: passURL)
        logger.debug("save pass succeed")
    }
}
