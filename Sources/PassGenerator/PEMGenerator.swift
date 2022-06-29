import Foundation
import Logging

protocol PEMGeneratorType {
    func generatePemKey(from certificateURL: URL, with password: String, to pemKeyURL: URL) async throws
    func generatePemCertificate(from certificateURL: URL, with password: String, to pemCertURL: URL) async throws
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
    func generatePemKey(from certificateURL: URL, with password: String, to pemKeyURL: URL) async throws {
        logger.debug("try generate pem key", metadata: [
            "certificateURL": .stringConvertible(certificateURL),
            "pemKeyURL": .stringConvertible(pemKeyURL)
        ])
        let result = try await Process.asyncExecute(URL(fileURLWithPath: "/usr/bin/openssl"),
                                              "pkcs12",
                                              "-in",
                                              certificateURL.path,
                                              "-nocerts",
                                              "-out",
                                              pemKeyURL.path,
                                              "-passin",
                                              "pass:" + password,
                                              "-passout",
                                              "pass:" + password)
        guard result == 0 else {
            logger.error("failed to generate pem key", metadata: [
                "result": .stringConvertible(result)
            ])
            throw PassGeneratorError.cannotZip(terminationStatus: result)
        }
    }
    
    /// Generate a pem key from certificate
    /// - parameters:
    ///     - certificateURL: Pass .p12 certificate url.
    ///     - pemKeyURL: Destination url of .pem certificate file
    ///     - password: Passowrd of certificate.
    func generatePemCertificate(from certificateURL: URL, with password: String, to pemCertURL: URL) async throws {
        logger.debug("try generate pem certificate", metadata: [
            "certificateURL": .stringConvertible(certificateURL),
            "pemCertURL": .stringConvertible(pemCertURL)
        ])
        let result = try await Process.asyncExecute(URL(fileURLWithPath: "/usr/bin/openssl"),
                                              "pkcs12",
                                              "-in",
                                              certificateURL.path,
                                              "-clcerts",
                                              "-nokeys",
                                              "-out",
                                              pemCertURL.path,
                                              "-passin",
                                              "pass:" + password)
        guard result == 0 else {
            logger.error("failed to generate pem certificate", metadata: [
                "result": .stringConvertible(result)
            ])
            throw PassGeneratorError.cannotZip(terminationStatus: result)
        }
    }
}
