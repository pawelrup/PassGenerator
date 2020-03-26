import Foundation
import NIO
import CryptoSwift
import ZIPFoundation

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
    private let fileManager = FileManager.default
    
    /// Creates a new `WalletKit`.
    /// - parameters:
    ///     - certificateURL: URL to the pass certificate.
    ///     - certificatePassword: Password of the pass certificate.
    ///     - wwdrURL: URL to the WWDR certificate https://developer.apple.com/certificationauthority/AppleWWDRCA.cer.
    ///     - templateURL: URL of the template to be used for the pass, containing the images etc.
    public init(certificateURL: URL, certificatePassword: String, wwdrURL: URL, templateURL: URL) {
        self.certificateURL = certificateURL
        self.certificatePassword = certificatePassword
        self.wwdrURL = wwdrURL
        self.templateURL = templateURL
    }
    
    /// Generate a signed .pkpass file
    /// - parameters:
    ///     - pass: A Pass object containing all pass information, ensure the `passTypeIdentifier` and `teamIdentifier` match those in supplied certificate.
    ///     - destination: The destination of the .pkpass to be saved, if nil the pass will be saved to the execution directory (generally the case if the result Data is used).
    ///     - eventLoop: Event loop to perform async task on.
    /// - returns: A future containing the data of the generated pass.
    public func generatePass(_ pass: Pass, to destination: URL, on eventLoop: EventLoop) -> EventLoopFuture<Data> {
        let temporaryDirectoryURL = destination.appendingPathComponent(UUID().uuidString)
        let passDirectoryURL = temporaryDirectoryURL.appendingPathComponent("pass")
        let pkpassURL = temporaryDirectoryURL.appendingPathComponent("pass.pkpass")
        let manifestURL = passDirectoryURL.appendingPathComponent("manifest.json")
        let signatureURL = passDirectoryURL.appendingPathComponent("signature")
        let pemKeyURL = temporaryDirectoryURL.appendingPathComponent("key.pem")
        let pemCertURL = temporaryDirectoryURL.appendingPathComponent("cert.pem")
        
        let prepare = preparePass(pass, temporaryDirectory: temporaryDirectoryURL, passDirectory: passDirectoryURL, on: eventLoop)
        return prepare
            .flatMap { self.generateManifest(for: passDirectoryURL, in: manifestURL, on: eventLoop) }
            .flatMap { Self.generatePemKey(from: self.certificateURL, to: pemKeyURL, password: self.certificatePassword, on: eventLoop) }
            .flatMap { Self.generatePemCertificate(from: self.certificateURL, to: pemCertURL, password: self.certificatePassword, on: eventLoop) }
            .flatMap { self.generateSignature(pemCertURL: pemCertURL, pemKeyURL: pemKeyURL, wwdrURL: self.wwdrURL, manifestURL: manifestURL, signatureURL: signatureURL, certificatePassword: self.certificatePassword, on: eventLoop) }
            .flatMap { self.zipItems(in: passDirectoryURL, to: pkpassURL, on: eventLoop) }
            .flatMapThrowing { try Data(contentsOf: pkpassURL) }
            .always { _ in try? self.fileManager.removeItem(at: temporaryDirectoryURL) }
    }
}

private extension PassGenerator {
    
    func preparePass(_ pass: Pass, temporaryDirectory: URL, passDirectory: URL, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        let promise = eventLoop.makePromise(of: Void.self)
        DispatchQueue.global().async {
            do {
                try self.fileManager.createDirectory(at: temporaryDirectory, withIntermediateDirectories: false, attributes: nil)
                try self.fileManager.copyItem(at: self.templateURL, to: passDirectory)
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mmZZZZZ"
                let jsonEncoder = JSONEncoder()
                jsonEncoder.dateEncodingStrategy = .formatted(formatter)
                let passData: Data
                do {
                    passData = try jsonEncoder.encode(pass)
                } catch {
                    throw PassGeneratorError.invalidPassJSON
                }
                let passURL = passDirectory.appendingPathComponent("pass.json")
                try passData.write(to: passURL)
                promise.succeed(())
            } catch {
                promise.fail(error)
            }
        }
        return promise.futureResult
    }
    
    func generateManifest(for directoryURL: URL, in manifestURL: URL, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        let promise = eventLoop.makePromise(of: Void.self)
        DispatchQueue.global().async {
            do {
                let contents = try self.fileManager.contentsOfDirectory(atPath: directoryURL.path)
                var manifest: [String: String] = [:]
                contents.forEach({ (item) in
                    let itemPath = directoryURL.appendingPathComponent(item).path
                    guard let data = self.fileManager.contents(atPath: itemPath) else { return }
                    manifest[item] = data.sha1().toHexString()
                })
                let manifestData = try JSONSerialization.data(withJSONObject: manifest, options: .prettyPrinted)
                try manifestData.write(to: manifestURL)
                promise.succeed(())
            } catch {
                promise.fail(error)
            }
        }
        return promise.futureResult
    }
    
    func generateSignature(pemCertURL: URL, pemKeyURL: URL, wwdrURL: URL, manifestURL: URL, signatureURL: URL, certificatePassword: String, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
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
            "pass:" + certificatePassword, on: eventLoop, { (_: ProcessOutput) in })
            .flatMapThrowing { result in
                guard result == 0 else {
                    throw PassGeneratorError.cannotGenerateSignature(terminationStatus: result)
                }
            }
    }
    
    func zipItems(in directoryURL: URL, to zipURL: URL, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        Process.asyncExecute(
            URL(fileURLWithPath: "/usr/bin/zip"),
            in: directoryURL,
            zipURL.unixPath,
            "-r",
            "-q",
            ".",
            on: eventLoop, { (_: ProcessOutput) in })
            .flatMapThrowing { result in
                guard result == 0 else {
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
    static func generatePemKey(from certificateURL: URL, to pemKeyURL: URL, password: String, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
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
            "pass:" + password, on: eventLoop, { (_: ProcessOutput) in })
            .flatMapThrowing { result in
                guard result == 0 else {
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
    static func generatePemCertificate(from certificateURL: URL, to pemCertURL: URL, password: String, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
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
            "pass:" + password, on: eventLoop, { (_: ProcessOutput) in })
            .flatMapThrowing { result in
                guard result == 0 else {
                    throw PassGeneratorError.cannotGenerateCertificate(terminationStatus: result)
                }
            }
    }
}
