import XCTest
@testable import PassGenerator

final class PassGeneratorTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(PassGenerator().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
