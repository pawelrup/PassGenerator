import Foundation
@testable import PassGenerator

class PassZipperMock: PassZipperType {
    typealias ZipClosure = (URL) -> Void
    var callCount = 0
    var zip: ZipClosure?
    
    func zipItems(in directoryURL: URL, to zipURL: URL) async throws {
        callCount += 1
        zip?(zipURL)
    }
}
