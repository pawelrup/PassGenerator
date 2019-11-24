import Foundation
import NIO
import CryptoSwift
import ZIPFoundation

enum PassGeneratorError: Error {
    case invalidPassJSON
    case cannotGenerateKey
    case cannotGenerateCertificate
    case cannotGenerateSignature
}

public struct PassGenerator {
    
    private let certificateURL: URL
    private let certificatePassword: String
    private let wwdrURL: URL
    private let templateDirectoryURL: URL
    private let fileManager = FileManager.default
    
    /// Creates a new `WalletKit`.
    /// - parameters:
    ///     - certificateURL: Path to the pass certificate.
    ///     - certificatePassword: Password of the pass certificate.
    ///     - wwdrURL: Path to the WWDR certificate https://developer.apple.com/certificationauthority/AppleWWDRCA.cer.
    ///     - templateDirectoryURL: Path of the template to be used for the pass, containing the images etc.
    public init(certificateURL: URL, certificatePassword: String, wwdrURL: URL, templateDirectoryURL: URL) {
        self.certificateURL = certificateURL
        self.certificatePassword = certificatePassword
        self.wwdrURL = wwdrURL
        self.templateDirectoryURL = templateDirectoryURL
    }
    
    /// Generate a signed .pkpass file
    /// - parameters:
    ///     - pass: A Pass object containing all pass information, ensure the `passTypeIdentifier` and `teamIdentifier` match those in supplied certificate.
    ///     - destination: The destination of the .pkpass to be saved, if nil the pass will be saved to the execution directory (generally the case if the result Data is used).
    ///     - arguments: An array of arguments to pass to the program.
    ///     - worker: Worker to perform async task on.
    /// - returns: A future containing the data of the generated pass.
    public func generatePass(pass: Pass, destination: URL? = nil, on eventLoop: EventLoop) throws -> EventLoopFuture<Data> {
        let currentDirectoryURL = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
        let temporaryDirectoryURL = currentDirectoryURL.appendingPathComponent(UUID().uuidString)
        let passDirectoryURL = temporaryDirectoryURL.appendingPathComponent("pass")
        let destinationURL = (destination ?? temporaryDirectoryURL).appendingPathComponent("pass.pkpass")
        
        let prepare = preparePass(pass: pass, temporaryDirectory: temporaryDirectoryURL, passDirectory: passDirectoryURL, on: eventLoop)
        return prepare
            .flatMap { _ in self.generateManifest(directory: passDirectoryURL, on: eventLoop) }
            .flatMap { _ in self.generateKey(directory: temporaryDirectoryURL, on: eventLoop) }
            .flatMap { _ in self.generateCertificate(directory: temporaryDirectoryURL, on: eventLoop) }
            .flatMap { _ in self.generateSignature(directory: temporaryDirectoryURL, passDirectory: passDirectoryURL, on: eventLoop) }
            .flatMap { _ in self.zipPass(passURL: passDirectoryURL, zipURL: destinationURL, on: eventLoop) }
            .flatMapThrowing { _ in try Data(contentsOf: destinationURL) }
            .always { _ in try? self.fileManager.removeItem(at: temporaryDirectoryURL) }
    }
}

private extension PassGenerator {
    
    func preparePass(pass: Pass, temporaryDirectory: URL, passDirectory: URL, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        let promise = eventLoop.makePromise(of: Void.self)
        DispatchQueue.global().async {
            do {
                try self.fileManager.createDirectory(at: temporaryDirectory, withIntermediateDirectories: false, attributes: nil)
                try self.fileManager.copyItem(at: self.templateDirectoryURL, to: passDirectory)
                
                let jsonEncoder = JSONEncoder()
                jsonEncoder.dateEncodingStrategy = .iso8601
                let passData: Data
                do {
                    passData = try jsonEncoder.encode(pass)
                } catch {
                    throw PassGeneratorError.invalidPassJSON
                }
                let passURL = passDirectory.appendingPathComponent("pass.json")
                self.fileManager.createFile(atPath: passURL.path, contents: passData, attributes: nil)
                promise.succeed(())
            } catch {
                promise.fail(error)
            }
        }
        return promise.futureResult
    }
    
    func generateManifest(directory: URL, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        let promise = eventLoop.makePromise(of: Void.self)
        DispatchQueue.global().async {
            do {
                let contents = try self.fileManager.contentsOfDirectory(atPath: directory.path)
                var manifest: [String: String] = [:]
                contents.forEach({ (item) in
                    let itemPath = directory.appendingPathComponent(item).path
                    guard let data = self.fileManager.contents(atPath: itemPath) else { return }
                    manifest[item] = data.sha1().toHexString()
                })
                let manifestData = try JSONSerialization.data(withJSONObject: manifest, options: .prettyPrinted)
                let manifestPath = directory.appendingPathComponent("manifest.json").path
                self.fileManager.createFile(atPath: manifestPath, contents: manifestData, attributes: nil)
                promise.succeed(())
            } catch {
                promise.fail(error)
            }
        }
        return promise.futureResult
    }
    
    func generateKey(directory: URL, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        let keyPath = directory.appendingPathComponent("key.pem")
        return Process.asyncExecute(
            "openssl",
            "pkcs12",
            "-in",
            certificateURL.path,
            "-nocerts",
            "-out",
            keyPath.path,
            "-passin",
            "pass:" + certificatePassword,
            "-passout",
            "pass:" + certificatePassword, on: eventLoop) { _ in }.flatMapThrowing { result in
                guard result == 0 else {
                    throw PassGeneratorError.cannotGenerateKey
                }
        }
    }
    
    func generateCertificate(directory: URL, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        let certURL = directory.appendingPathComponent("cert.pem")
        return Process.asyncExecute(
            "openssl",
            "pkcs12",
            "-in",
            certificateURL.path,
            "-clcerts",
            "-nokeys",
            "-out",
            certURL.path,
            "-passin",
            "pass:" + certificatePassword, on: eventLoop) { _ in }.flatMapThrowing { result in
                guard result == 0 else {
                    throw PassGeneratorError.cannotGenerateCertificate
                }
        }
    }
    
    func generateSignature(directory: URL, passDirectory: URL, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        return Process.asyncExecute(
            "openssl",
            "smime",
            "-sign",
            "-signer",
            directory.appendingPathComponent("cert.pem").path,
            "-inkey",
            directory.appendingPathComponent("key.pem").path,
            "-certfile",
            wwdrURL.path,
            "-in",
            passDirectory.appendingPathComponent("manifest.json").path,
            "-out",
            passDirectory.appendingPathComponent("signature").path,
            "-outform",
            "der",
            "-binary",
            "-passin",
            "pass:" + certificatePassword, on: eventLoop) { _ in }.flatMapThrowing { result in
                guard result == 0 else {
                    throw PassGeneratorError.cannotGenerateCertificate
                }
        }
    }
    
    func zipPass(passURL: URL, zipURL: URL, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        let promise = eventLoop.makePromise(of: Void.self)
        DispatchQueue.global().async {
            do {
                try self.fileManager.zipItem(at: passURL, to: zipURL, shouldKeepParent: false)
                promise.succeed(())
            } catch {
                promise.fail(error)
            }
        }
        return promise.futureResult
    }
}
