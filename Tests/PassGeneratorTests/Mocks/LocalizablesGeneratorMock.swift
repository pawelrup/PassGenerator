import Foundation
@testable import PassGenerator

class LocalizablesGeneratorMock: LocalizablesGeneratorType {
    var callCount = 0
    
    func generateLocalizables(for localizable: Localizable, in directory: URL) throws {
        callCount += 1
    }
}
