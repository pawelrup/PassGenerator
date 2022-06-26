import Foundation
@testable import PassGenerator

class ManifestGeneratorMock: ManifestGeneratorType {
    var callCount = 0
    
    func generateManifest(for directoryURL: URL, in manifestURL: URL) async throws {
        callCount += 1
    }
}
