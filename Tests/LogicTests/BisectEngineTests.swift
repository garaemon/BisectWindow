import XCTest
@testable import BisectWindow

final class BisectEngineTests: XCTestCase {
    func testPlaceholder() {
        let engine = BisectEngine()
        XCTAssertNotNil(engine)
    }
}
