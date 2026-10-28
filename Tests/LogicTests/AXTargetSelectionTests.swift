import XCTest
@testable import BisectWindow

final class AXTargetSelectionTests: XCTestCase {

    // MARK: - selectProcessId

    func testValidWorkspacePidWinsWithoutAskingAccessibility() {
        var didAskFocusedApplication = false
        let pid = AXTargetSelection.selectProcessId(
            workspaceProcessId: 123,
            focusedApplicationProcessId: {
                didAskFocusedApplication = true
                return 456
            }
        )
        XCTAssertEqual(pid, 123)
        XCTAssertFalse(didAskFocusedApplication)
    }

    func testNegativeWorkspacePidFallsBackToFocusedApplication() {
        // NSWorkspace reports pid -1 for Emacs.
        let pid = AXTargetSelection.selectProcessId(
            workspaceProcessId: -1,
            focusedApplicationProcessId: { 456 }
        )
        XCTAssertEqual(pid, 456)
    }

    func testMissingWorkspaceAppFallsBackToFocusedApplication() {
        let pid = AXTargetSelection.selectProcessId(
            workspaceProcessId: nil,
            focusedApplicationProcessId: { 456 }
        )
        XCTAssertEqual(pid, 456)
    }

    func testInvalidPidsFromBothSourcesReturnNil() {
        XCTAssertNil(AXTargetSelection.selectProcessId(
            workspaceProcessId: -1,
            focusedApplicationProcessId: { 0 }
        ))
        XCTAssertNil(AXTargetSelection.selectProcessId(
            workspaceProcessId: -1,
            focusedApplicationProcessId: { nil }
        ))
    }

    // MARK: - selectWindow

    func testFocusedWindowWinsWithoutFurtherLookups() {
        var lookups: [String] = []
        let window = AXTargetSelection.selectWindow(
            focusedWindow: { lookups.append("focused"); return "focused" },
            mainWindow: { lookups.append("main"); return "main" },
            windows: { lookups.append("windows"); return ["first"] }
        )
        XCTAssertEqual(window, "focused")
        XCTAssertEqual(lookups, ["focused"])
    }

    func testMissingFocusedWindowFallsBackToMainWindow() {
        let window = AXTargetSelection.selectWindow(
            focusedWindow: { nil },
            mainWindow: { "main" },
            windows: { ["first"] }
        )
        XCTAssertEqual(window, "main")
    }

    func testMissingMainWindowFallsBackToFirstWindow() {
        let window = AXTargetSelection.selectWindow(
            focusedWindow: { nil },
            mainWindow: { nil },
            windows: { ["first", "second"] }
        )
        XCTAssertEqual(window, "first")
    }

    func testNoWindowAnywhereReturnsNil() {
        let window: String? = AXTargetSelection.selectWindow(
            focusedWindow: { nil },
            mainWindow: { nil },
            windows: { [] }
        )
        XCTAssertNil(window)
    }
}
