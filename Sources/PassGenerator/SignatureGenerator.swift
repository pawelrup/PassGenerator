import Foundation
import Logging

protocol SignatureGeneratorType {
    func generateSignature(pemCertURL: URL, pemKeyURL: URL, wwdrURL: URL, manifestURL: URL, signatureURL: URL, certificatePassword: String) async throws
}

struct SignatureGenerator: SignatureGeneratorType {
    private let logger: Logger
    
    init(logger: Logger) {
        self.logger = logger
    }
    
    func generateSignature(pemCertURL: URL, pemKeyURL: URL, wwdrURL: URL, manifestURL: URL, signatureURL: URL, certificatePassword: String) async throws {
        logger.debug("try generate signature", metadata: [
            "pemCertURL": .stringConvertible(pemCertURL),
            "pemKeyURL": .stringConvertible(pemKeyURL),
            "wwdrURL": .stringConvertible(wwdrURL),
            "manifestURL": .stringConvertible(manifestURL),
            "signatureURL": .stringConvertible(signatureURL)
        ])
        let result = try await Process.asyncExecute(URL(fileURLWithPath: "/usr/bin/openssl"),
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
                                                    "pass:" + certificatePassword)
        guard result == 0 else {
            logger.error("failed to generate signature", metadata: [
                "result": .stringConvertible(result)
            ])
            throw PassGeneratorError.cannotZip(terminationStatus: result)
        }
    }
}
