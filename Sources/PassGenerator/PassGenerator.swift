import Foundation
import NIO
import Core
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
    ///     - certificateURL: URL to the pass certificate.
    ///     - certificatePassword: Password of the pass certificate.
    ///     - wwdrURL: URL to the WWDR certificate https://developer.apple.com/certificationauthority/AppleWWDRCA.cer.
    ///     - templateDirectoryURL: URL of the template to be used for the pass, containing the images etc.
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
        let directory = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
        let temporaryDirectory = directory.appendingPathComponent(UUID().uuidString)
        let passDirectory = temporaryDirectory.appendingPathComponent("pass")
        let destinationURL = (destination ?? temporaryDirectory).appendingPathComponent("pass.pkpass")
        
        let prepare = preparePass(pass: pass, temporaryDirectory: temporaryDirectory, passDirectory: passDirectory, on: eventLoop)
        return prepare
            .flatMap { (_) -> EventLoopFuture<Void> in
                self.generateManifest(directory: passDirectory, on: eventLoop)
            }
            .flatMap { (_) -> EventLoopFuture<Void> in
                self.generateKey(directory: temporaryDirectory, on: eventLoop)
            }
            .flatMap { (_) -> EventLoopFuture<Void> in
                self.generateCertificate(directory: temporaryDirectory, on: eventLoop)
            }
            .flatMap { (_) -> EventLoopFuture<Void> in
                self.generateSignature(directory: temporaryDirectory, passDirectory: passDirectory, on: eventLoop)
            }
            .flatMap { (_) -> EventLoopFuture<Void> in
                self.zipPass(passURL: passDirectory, zipURL: destinationURL, on: eventLoop)
            }
            .thenThrowing { try Data(contentsOf: destinationURL) }
            .always { try? self.fileManager.removeItem(at: temporaryDirectory) }
    }
}

private extension PassGenerator {
    
    func preparePass(pass: Pass, temporaryDirectory: URL, passDirectory: URL, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        let promise = eventLoop.newPromise(of: Void.self)
        DispatchQueue.global().async {
            do {
                try self.fileManager.createDirectory(at: temporaryDirectory, withIntermediateDirectories: false, attributes: nil)
                try self.fileManager.copyItem(at: self.templateDirectoryURL, to: passDirectory)
                
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
                self.fileManager.createFile(atPath: passURL.path, contents: passData, attributes: nil)
                promise.succeed(result: ())
            } catch {
                promise.fail(error: error)
            }
        }
        return promise.futureResult
    }
    
    func generateManifest(directory: URL, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        let promise = eventLoop.newPromise(of: Void.self)
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
                promise.succeed(result: ())
            } catch {
                promise.fail(error: error)
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
            "pass:" + certificatePassword, on: eventLoop, { (_: ProcessOutput) in }).thenThrowing({ result in
                guard result == 0 else {
                    throw PassGeneratorError.cannotGenerateKey
                }
            })
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
            "pass:" + certificatePassword, on: eventLoop, { (_: ProcessOutput) in }).thenThrowing { result in
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
            "pass:" + certificatePassword, on: eventLoop, { (_: ProcessOutput) in }).thenThrowing { result in
                guard result == 0 else {
                    throw PassGeneratorError.cannotGenerateCertificate
                }
        }
    }
    
    func zipPass(passURL: URL, zipURL: URL, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        let promise = eventLoop.newPromise(of: Void.self)
        DispatchQueue.global().async {
            do {
                try self.fileManager.zipItem(at: passURL, to: zipURL, shouldKeepParent: false)
                promise.succeed(result: ())
            } catch {
                promise.fail(error: error)
            }
        }
        return promise.futureResult
    }
}
