import XCTest

final class ManagementUITests: XCTestCase {
    @MainActor
    func testSelectingManagementRendersOverviewContent() async throws {
        let app = XCUIApplication()
        app.launch()

        let managementItem = app.staticTexts["sidebar.management"]
        XCTAssertTrue(managementItem.waitForExistence(timeout: 15))
        managementItem.click()

        let systemStatus = app.staticTexts["control-center.overview.system-status"]
        XCTAssertTrue(
            systemStatus.waitForExistence(timeout: 10),
            "Control Center overview did not show its system status heading after navigation."
        )

        try await Task.sleep(nanoseconds: 800_000_000)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Control Center after navigation settles"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
