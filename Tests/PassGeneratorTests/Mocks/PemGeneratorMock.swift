import Foundation
import NIOCore
@testable import PassGenerator

class PemGeneratorMock: PEMGeneratorType {
    var generatePemKeyCallCount = 0
    var generatePemCertificateCallCount = 0
    
    func generatePemKey(from certificateURL: URL, to pemKeyURL: URL, password: String, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        generatePemKeyCallCount += 1
        return eventLoop.makeSucceededVoidFuture()
    }
    
    func generatePemCertificate(from certificateURL: URL, to pemCertURL: URL, password: String, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        generatePemCertificateCallCount += 1
        return eventLoop.makeSucceededVoidFuture()
    }
}
