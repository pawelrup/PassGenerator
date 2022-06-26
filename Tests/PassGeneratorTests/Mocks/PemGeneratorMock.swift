import Foundation
@testable import PassGenerator

class PemGeneratorMock: PEMGeneratorType {
    var generatePemKeyCallCount = 0
    var generatePemCertificateCallCount = 0
    
    func generatePemKey(from certificateURL: URL, to pemKeyURL: URL, password: String) async throws {
        generatePemKeyCallCount += 1
    }
    
    func generatePemCertificate(from certificateURL: URL, to pemCertURL: URL, password: String) async throws {
        generatePemCertificateCallCount += 1
    }
}
