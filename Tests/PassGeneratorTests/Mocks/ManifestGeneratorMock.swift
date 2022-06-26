import Foundation
import NIOCore
@testable import PassGenerator

class ManifestGeneratorMock: ManifestGeneratorType {
    var callCount = 0
    
    func generateManifest(for directoryURL: URL, in manifestURL: URL, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        callCount += 1
        return eventLoop.makeSucceededVoidFuture()
    }
}
