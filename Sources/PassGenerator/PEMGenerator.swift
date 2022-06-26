import Foundation
import Logging
import NIOCore

protocol PEMGeneratorType {
    func generatePemKey(from certificateURL: URL, to pemKeyURL: URL, password: String, on eventLoop: EventLoop) -> EventLoopFuture<Void>
    func generatePemCertificate(from certificateURL: URL, to pemCertURL: URL, password: String, on eventLoop: EventLoop) -> EventLoopFuture<Void>
}

struct PEMGenerator: PEMGeneratorType {
    private let logger: Logger
    
    init(logger: Logger) {
        self.logger = logger
    }
    
    /// Generate a pem key from certificate
    /// - parameters:
    ///     - certificateURL: Pass .p12 certificate url.
    ///     - pemKeyURL: Destination url of .pem key file
    ///     - password: Passowrd of certificate.
    ///     - eventLoop: Event loop to perform async task on.
    /// - returns: Empty future.
    func generatePemKey(from certificateURL: URL, to pemKeyURL: URL, password: String, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        logger.debug("try generate pem key", metadata: [
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
                logger.error("failed to generate pem key with result \(result)")
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
    func generatePemCertificate(from certificateURL: URL, to pemCertURL: URL, password: String, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        logger.debug("try generate pem certificate", metadata: [
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
                logger.error("failed to generate pem certificate", metadata: [
                    "result": .stringConvertible(result)
                ])
                throw PassGeneratorError.cannotGenerateCertificate(terminationStatus: result)
            }
        }
    }
}
