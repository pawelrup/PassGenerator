import Foundation
import NIOCore
@testable import PassGenerator

class SignatureGeneratorMock: SignatureGeneratorType {
    var callCount = 0
    
    func generateSignature(pemCertURL: URL, pemKeyURL: URL, wwdrURL: URL, manifestURL: URL, signatureURL: URL, certificatePassword: String, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        callCount += 1
        return eventLoop.makeSucceededVoidFuture()
    }
}
