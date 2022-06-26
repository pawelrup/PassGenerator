import Foundation
import NIO
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
    let certificateURL: URL
    let certificatePassword: String
    let wwdrURL: URL
    let templateURL: URL
}
public protocol PassGeneratorType {
    init(configuration: PassGeneratorConfiguration, logger: Logger)
    func generatePass(_ pass: Pass, to destination: URL, on eventLoop: EventLoop) -> EventLoopFuture<Data>
}

public struct PassGenerator: PassGeneratorType {
	private let configuration: PassGeneratorConfiguration
    private let localizablesGenerator: LocalizablesGeneratorType
    private let itemsCopier: ItemsCopierType
    private let manifestGenerator: ManifestGeneratorType
    private let pemGenerator: PEMGeneratorType
    private let signatureGenerator: SignatureGeneratorType
    private let zipper: PassZipperType
	private let logger: Logger
    private let fileManager: FileManager
	
    init(configuration: PassGeneratorConfiguration, localizablesGenerator: LocalizablesGeneratorType,
         itemsCopier: ItemsCopierType, manifestGenerator: ManifestGeneratorType, pemGenerator: PEMGeneratorType,
         signatureGenerator: SignatureGeneratorType, zipper: PassZipperType, logger: Logger, fileManager: FileManager) {
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
                  zipper: PassZipper(logger: logger),
                  logger: logger,
                  fileManager: fileManager)
    }
	
	/// Generate a signed .pkpass file
	/// - parameters:
	///     - pass: A Pass object containing all pass information, ensure the `passTypeIdentifier` and `teamIdentifier` match those in supplied certificate.
	///     - destination: The destination of the .pkpass to be saved, if nil the pass will be saved to the execution directory (generally the case if the result Data is used).
	///     - eventLoop: Event loop to perform async task on.
	/// - returns: A future containing the data of the generated pass.
	public func generatePass(_ pass: Pass, to destination: URL, on eventLoop: EventLoop) -> EventLoopFuture<Data> {
		logger.debug("try prepare URLs")
		let temporaryDirectoryURL = destination.appendingPathComponent(UUID().uuidString)
		let passDirectoryURL = temporaryDirectoryURL.appendingPathComponent("pass")
		let pkpassURL = temporaryDirectoryURL.appendingPathComponent("pass.pkpass")
		let manifestURL = passDirectoryURL.appendingPathComponent("manifest.json")
		let signatureURL = passDirectoryURL.appendingPathComponent("signature")
		let pemKeyURL = temporaryDirectoryURL.appendingPathComponent("key.pem")
		let pemCertURL = temporaryDirectoryURL.appendingPathComponent("cert.pem")
		logger.debug("URLs prepared", metadata: [
			"temporaryDirectoryURL": .stringConvertible(temporaryDirectoryURL),
			"passDirectoryURL": .stringConvertible(passDirectoryURL),
			"pkpassURL": .stringConvertible(pkpassURL),
			"manifestURL": .stringConvertible(manifestURL),
			"signatureURL": .stringConvertible(signatureURL),
			"pemKeyURL": .stringConvertible(pemKeyURL),
			"pemCertURL": .stringConvertible(pemCertURL)
		])
        
        logger.debug("create temporary directory", metadata: [
            "temporaryDirectory": .stringConvertible(temporaryDirectoryURL)
        ])
        do {
            try fileManager.createDirectory(at: passDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
		
        return eventLoop.makeSucceededVoidFuture()
            .flatMapThrowing { try self.localizablesGenerator.generateLocalizables(for: pass, in: passDirectoryURL) }
            .flatMap { self.itemsCopier.copyItems(from: configuration.templateURL, to: passDirectoryURL, on: eventLoop) }
            .flatMap { self.savePassJSON(pass, to: passDirectoryURL, on: eventLoop) }
            .flatMap { self.manifestGenerator.generateManifest(for: passDirectoryURL, in: manifestURL, on: eventLoop) }
            .flatMap { self.pemGenerator.generatePemKey(from: configuration.certificateURL, to: pemKeyURL, password: configuration.certificatePassword, on: eventLoop) }
            .flatMap { self.pemGenerator.generatePemCertificate(from: configuration.certificateURL, to: pemCertURL, password: configuration.certificatePassword, on: eventLoop) }
            .flatMap { self.signatureGenerator.generateSignature(pemCertURL: pemCertURL, pemKeyURL: pemKeyURL, wwdrURL: configuration.wwdrURL, manifestURL: manifestURL, signatureURL: signatureURL, certificatePassword: configuration.certificatePassword, on: eventLoop) }
            .flatMap { self.zipper.zipItems(in: passDirectoryURL, to: pkpassURL, on: eventLoop) }
			.flatMapThrowing { try Data(contentsOf: pkpassURL) }
			.always { _ in try? fileManager.removeItem(at: temporaryDirectoryURL) }
	}
}

private extension PassGenerator {
    func savePassJSON(_ pass: Pass, to passDirectory: URL, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        let promise = eventLoop.makePromise(of: Void.self)
        DispatchQueue.global().async {
            do {
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
                promise.succeed(())
            } catch {
                logger.error("failed to save pass")
                promise.fail(error)
            }
        }
        return promise.futureResult
    }
}
