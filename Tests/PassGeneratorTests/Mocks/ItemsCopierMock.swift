import Foundation
import NIOCore
@testable import PassGenerator

class ItemsCopierMock: ItemsCopierType {
    var callCount = 0
    
    func copyItems(from templateDirectory: URL, to passDirectory: URL, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        callCount += 1
        return eventLoop.makeSucceededVoidFuture()
    }
}
