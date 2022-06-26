import Foundation
@testable import PassGenerator

class SignatureGeneratorMock: SignatureGeneratorType {
    var callCount = 0
    
    func generateSignature(pemCertURL: URL, pemKeyURL: URL, wwdrURL: URL, manifestURL: URL, signatureURL: URL, certificatePassword: String) async throws {
        callCount += 1
    }
}
