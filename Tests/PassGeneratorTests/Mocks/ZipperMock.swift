import Foundation
@testable import PassGenerator

class ZipperMock: ZipperType {
    typealias ZipClosure = (URL) -> Void
    var callCount = 0
    var zip: ZipClosure?
    
    func zipItems(in directoryURL: URL, to zipURL: URL) async throws {
        callCount += 1
        zip?(zipURL)
    }
}
