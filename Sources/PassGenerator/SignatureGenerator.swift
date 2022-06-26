import Foundation
import Logging
import NIOCore

protocol SignatureGeneratorType {
    func generateSignature(pemCertURL: URL, pemKeyURL: URL, wwdrURL: URL, manifestURL: URL, signatureURL: URL, certificatePassword: String, on eventLoop: EventLoop) -> EventLoopFuture<Void>
}

struct SignatureGenerator: SignatureGeneratorType {
    private let logger: Logger
    
    init(logger: Logger) {
        self.logger = logger
    }
    
    func generateSignature(pemCertURL: URL, pemKeyURL: URL, wwdrURL: URL, manifestURL: URL, signatureURL: URL, certificatePassword: String, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        logger.debug("try generate signature", metadata: [
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
                self.logger.error("failed to generate signature", metadata: [
                    "result": .stringConvertible(result)
                ])
                throw PassGeneratorError.cannotGenerateSignature(terminationStatus: result)
            }
        }
    }
}
