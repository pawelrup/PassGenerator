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

public struct PassGenerator {
	
	private let certificateURL: URL
	private let certificatePassword: String
	private let wwdrURL: URL
	private let templateURL: URL
	private let logger: Logger
	private let fileManager = FileManager.default
	
	/// Creates a new `WalletKit`.
	/// - parameters:
	///     - certificateURL: URL to the pass certificate.
	///     - certificatePassword: Password of the pass certificate.
	///     - wwdrURL: URL to the WWDR certificate https://developer.apple.com/certificationauthority/AppleWWDRCA.cer.
	///     - templateURL: URL of the template to be used for the pass, containing the images etc.
	public init(certificateURL: URL, certificatePassword: String, wwdrURL: URL, templateURL: URL, logger: Logger) {
		self.certificateURL = certificateURL
		self.certificatePassword = certificatePassword
		self.wwdrURL = wwdrURL
		self.templateURL = templateURL
		self.logger = logger
	}
	
	/// Generate a signed .pkpass file
	/// - parameters:
	///     - pass: A Pass object containing all pass information, ensure the `passTypeIdentifier` and `teamIdentifier` match those in supplied certificate.
	///     - destination: The destination of the .pkpass to be saved, if nil the pass will be saved to the execution directory (generally the case if the result Data is used).
	///     - eventLoop: Event loop to perform async task on.
	/// - returns: A future containing the data of the generated pass.
	public func generatePass(_ pass: Pass, to destination: URL, on eventLoop: EventLoop) -> EventLoopFuture<Data> {
		logger.debug("[ PassGenerator ] 👷‍♂️ try prepare URLs")
		let temporaryDirectoryURL = destination.appendingPathComponent(UUID().uuidString)
		let passDirectoryURL = temporaryDirectoryURL.appendingPathComponent("pass")
		let pkpassURL = temporaryDirectoryURL.appendingPathComponent("pass.pkpass")
		let manifestURL = passDirectoryURL.appendingPathComponent("manifest.json")
		let signatureURL = passDirectoryURL.appendingPathComponent("signature")
		let pemKeyURL = temporaryDirectoryURL.appendingPathComponent("key.pem")
		let pemCertURL = temporaryDirectoryURL.appendingPathComponent("cert.pem")
		logger.debug("[ PassGenerator ] 👷‍♂️ URLs prepared", metadata: [
			"temporaryDirectoryURL": .stringConvertible(temporaryDirectoryURL),
			"passDirectoryURL": .stringConvertible(passDirectoryURL),
			"pkpassURL": .stringConvertible(pkpassURL),
			"manifestURL": .stringConvertible(manifestURL),
			"signatureURL": .stringConvertible(signatureURL),
			"pemKeyURL": .stringConvertible(pemKeyURL),
			"pemCertURL": .stringConvertible(pemCertURL)
		])
		
		let prepare = preparePass(pass, temporaryDirectory: temporaryDirectoryURL, passDirectory: passDirectoryURL, on: eventLoop)
		return prepare
			.flatMap { generateManifest(for: passDirectoryURL, in: manifestURL, on: eventLoop) }
			.flatMap { Self.generatePemKey(from: certificateURL, to: pemKeyURL, password: certificatePassword, on: eventLoop, logger: logger) }
			.flatMap { Self.generatePemCertificate(from: certificateURL, to: pemCertURL, password: certificatePassword, on: eventLoop, logger: logger) }
			.flatMap { generateSignature(pemCertURL: pemCertURL, pemKeyURL: pemKeyURL, wwdrURL: wwdrURL, manifestURL: manifestURL, signatureURL: signatureURL, certificatePassword: certificatePassword, on: eventLoop) }
			.flatMap { zipItems(in: passDirectoryURL, to: pkpassURL, on: eventLoop) }
			.flatMapThrowing { try Data(contentsOf: pkpassURL) }
			.always { _ in try? fileManager.removeItem(at: temporaryDirectoryURL) }
	}
}

private extension PassGenerator {
	func preparePass(_ pass: Pass, temporaryDirectory: URL, passDirectory: URL, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
		logger.debug("[ PassGenerator ] 👷‍♂️ preparePass: try prepare pass")
		let promise = eventLoop.makePromise(of: Void.self)
		DispatchQueue.global().async {
			do {
				logger.debug("[ PassGenerator ] 👷‍♂️ preparePass: create directory", metadata: [
					"temporaryDirectory": .stringConvertible(temporaryDirectory)
				])
				try fileManager.createDirectory(at: temporaryDirectory, withIntermediateDirectories: false, attributes: nil)
				logger.debug("[ PassGenerator ] 👷‍♂️ preparePass: copy item", metadata: [
					"from templateURL": .stringConvertible(templateURL),
					"to passDirectory": .stringConvertible(passDirectory)
				])
				try fileManager.copyItem(at: templateURL, to: passDirectory)
				
				let formatter = DateFormatter()
				formatter.dateFormat = "yyyy-MM-dd'T'HH:mmZZZZZ"
				let jsonEncoder = JSONEncoder()
				jsonEncoder.dateEncodingStrategy = .formatted(formatter)
				let passData: Data
				do {
					passData = try jsonEncoder.encode(pass)
				} catch {
					logger.error("[ PassGenerator ] 👷‍♂️ preparePass: invalid json")
					throw PassGeneratorError.invalidPassJSON
				}
				let passURL = passDirectory.appendingPathComponent("pass.json")
				logger.debug("[ PassGenerator ] 👷‍♂️ preparePass: try write pass json", metadata: [
					"to passURL": .stringConvertible(passURL)
				])
				try passData.write(to: passURL)
				logger.debug("[ PassGenerator ] 👷‍♂️ preparePass: prepare pass succeed")
				promise.succeed(())
			} catch {
				logger.error("[ PassGenerator ] 👷‍♂️ preparePass: failed to prepare pass")
				promise.fail(error)
			}
		}
		return promise.futureResult
	}
	
	func generateManifest(for directoryURL: URL, in manifestURL: URL, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
		logger.debug("[ PassGenerator ] 👷‍♂️ generateManifest: try generate manifest")
		let promise = eventLoop.makePromise(of: Void.self)
		DispatchQueue.global().async {
			do {
				logger.debug("[ PassGenerator ] 👷‍♂️ generateManifest: get contents of directory", metadata: [
					"directoryURL": .stringConvertible(directoryURL)
				])
				let contents = try fileManager.contentsOfDirectory(atPath: directoryURL.path)
				var manifest: [String: String] = [:]
				contents.forEach({ (item) in
					let itemPath = directoryURL.appendingPathComponent(item).path
					logger.debug("[ PassGenerator ] 👷‍♂️ generateManifest: get contents of item", metadata: [
						"item": .string(item)
					])
					guard let data = fileManager.contents(atPath: itemPath) else { return }
					logger.debug("[ PassGenerator ] 👷‍♂️ generateManifest: generate sha1")
					manifest[item] = data.sha1().toHexString()
				})
				logger.debug("[ PassGenerator ] 👷‍♂️ generateManifest: serialize manifest")
				let manifestData = try JSONSerialization.data(withJSONObject: manifest, options: .prettyPrinted)
				logger.debug("[ PassGenerator ] 👷‍♂️ generateManifest: try write manifest", metadata: [
					"manifestURL": .stringConvertible(manifestURL)
				])
				try manifestData.write(to: manifestURL)
				promise.succeed(())
			} catch {
				logger.error("PassGenerator failed to generate manifest")
				promise.fail(error)
			}
		}
		return promise.futureResult
	}
	
	func generateSignature(pemCertURL: URL, pemKeyURL: URL, wwdrURL: URL, manifestURL: URL, signatureURL: URL, certificatePassword: String, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
		logger.debug("[ PassGenerator ] 👷‍♂️ generateSignature: try generate signature", metadata: [
			"pemCertURL": .stringConvertible(pemCertURL),
			"pemKeyURL": .stringConvertible(pemKeyURL),
			"wwdrURL": .stringConvertible(wwdrURL),
			"manifestURL": .stringConvertible(manifestURL),
			"signatureURL": .stringConvertible(signatureURL)
		])
		return Process.asyncExecute(
			URL(fileURLWithPath: "/usr/bin/openssl"),
			"smime",
			"-sign",
			"-signer",
			pemCertURL.path,
			"-inkey",
			pemKeyURL.path,
			"-certfile",
			wwdrURL.path,
			"-in",
			manifestURL.path,
			"-out",
			signatureURL.path,
			"-outform",
			"der",
			"-binary",
			"-passin",
			"pass:" + certificatePassword, on: eventLoop,
			logger: logger, { (_: ProcessOutput) in })
			.flatMapThrowing { result in
				guard result == 0 else {
					self.logger.error("[ PassGenerator ] 👷‍♂️ generateSignature: failed to generate signature with result \(result)")
					throw PassGeneratorError.cannotGenerateSignature(terminationStatus: result)
				}
		}
	}
	
	func zipItems(in directoryURL: URL, to zipURL: URL, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
		logger.debug("[ PassGenerator ] 👷‍♂️ generateSignature: try zip items", metadata: [
			"directoryURL": .stringConvertible(directoryURL),
			"zipURL": .stringConvertible(zipURL)
		])
		return Process.asyncExecute(
			URL(fileURLWithPath: "/usr/bin/zip"),
			in: directoryURL,
			zipURL.unixPath,
			"-r",
			"-q",
			".",
			on: eventLoop,
			logger: logger, { (_: ProcessOutput) in })
			.flatMapThrowing { result in
				guard result == 0 else {
					logger.error("[ PassGenerator ] 👷‍♂️ generateSignature: failed to zip items with result \(result)")
					throw PassGeneratorError.cannotZip(terminationStatus: result)
				}
		}
	}
}

public extension PassGenerator {
	
	/// Generate a pem key from certificate
	/// - parameters:
	///     - certificateURL: Pass .p12 certificate url.
	///     - pemKeyURL: Destination url of .pem key file
	///     - password: Passowrd of certificate.
	///     - eventLoop: Event loop to perform async task on.
	/// - returns: Empty future.
	static func generatePemKey(from certificateURL: URL, to pemKeyURL: URL, password: String, on eventLoop: EventLoop, logger: Logger? = nil) -> EventLoopFuture<Void> {
		logger?.debug("[ PassGenerator ] 👷‍♂️ generateSignature: try generate pem key", metadata: [
			"certificateURL": .stringConvertible(certificateURL),
			"pemKeyURL": .stringConvertible(pemKeyURL)
		])
		return Process.asyncExecute(
			URL(fileURLWithPath: "/usr/bin/openssl"),
			"pkcs12",
			"-in",
			certificateURL.path,
			"-nocerts",
			"-out",
			pemKeyURL.path,
			"-passin",
			"pass:" + password,
			"-passout",
			"pass:" + password, on: eventLoop,
			logger: logger, { (_: ProcessOutput) in })
			.flatMapThrowing { result in
				guard result == 0 else {
					logger?.error("[ PassGenerator ] 👷‍♂️ generateSignature: failed to generate pem key with result \(result)")
					throw PassGeneratorError.cannotGenerateKey(terminationStatus: result)
				}
		}
	}
	
	/// Generate a pem key from certificate
	/// - parameters:
	///     - certificateURL: Pass .p12 certificate url.
	///     - pemKeyURL: Destination url of .pem certificate file
	///     - password: Passowrd of certificate.
	///     - eventLoop: Event loop to perform async task on.
	/// - returns: Empty future.
	static func generatePemCertificate(from certificateURL: URL, to pemCertURL: URL, password: String, on eventLoop: EventLoop, logger: Logger? = nil) -> EventLoopFuture<Void> {
		logger?.debug("[ PassGenerator ] 👷‍♂️ generateSignature: try generate pem certificate", metadata: [
			"certificateURL": .stringConvertible(certificateURL),
			"pemCertURL": .stringConvertible(pemCertURL)
		])
		return Process.asyncExecute(
			URL(fileURLWithPath: "/usr/bin/openssl"),
			"pkcs12",
			"-in",
			certificateURL.path,
			"-clcerts",
			"-nokeys",
			"-out",
			pemCertURL.path,
			"-passin",
			"pass:" + password, on: eventLoop,
			logger: logger, { (_: ProcessOutput) in })
			.flatMapThrowing { result in
				guard result == 0 else {
					logger?.error("[ PassGenerator ] 👷‍♂️ generateSignature: failed to generate pem certificate with result \(result)")
					throw PassGeneratorError.cannotGenerateCertificate(terminationStatus: result)
				}
		}
	}
}
