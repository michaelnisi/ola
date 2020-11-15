import XCTest
@testable import ola

final class olaTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(ola().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
