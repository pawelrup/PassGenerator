import Foundation
@testable import PassGenerator

class ItemsCopierMock: ItemsCopierType {
    var callCount = 0
    
    func copyItems(from templateDirectory: URL, to passDirectory: URL) async throws {
        callCount += 1
    }
}
