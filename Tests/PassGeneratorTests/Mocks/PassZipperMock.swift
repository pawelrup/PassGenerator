import Foundation
import NIOCore
@testable import PassGenerator

class PassZipperMock: PassZipperType {
    typealias ZipClosure = (URL) -> Void
    var callCount = 0
    var zip: ZipClosure?
    
    func zipItems(in directoryURL: URL, to zipURL: URL, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        callCount += 1
        zip?(zipURL)
        return eventLoop.makeSucceededVoidFuture()
    }
}
