import Foundation
@testable import PassGenerator

class PemGeneratorMock: PEMGeneratorType {
    var generatePemKeyCallCount = 0
    var generatePemCertificateCallCount = 0
    
    func generatePemKey(from certificateURL: URL, with password: String, to pemKeyURL: URL) async throws {
        generatePemKeyCallCount += 1
    }
    
    func generatePemCertificate(from certificateURL: URL, with password: String, to pemCertURL: URL) async throws {
        generatePemCertificateCallCount += 1
    }
}
