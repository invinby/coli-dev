import XCTest

final class ManagementUITests: XCTestCase {
    @MainActor
    func testSelectingManagementRendersOverviewContent() {
        let app = XCUIApplication()
        app.launch()

        let managementItem = app.staticTexts["sidebar.management"]
        XCTAssertTrue(managementItem.waitForExistence(timeout: 15))
        managementItem.click()

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Control Center navigation result"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        let systemStatus = app.staticTexts["control-center.overview.system-status"]
        XCTAssertTrue(
            systemStatus.waitForExistence(timeout: 10),
            "Control Center overview did not show its system status heading after navigation."
        )
        XCTAssertTrue(systemStatus.isHittable, "System status heading is present but not visible in the window.")
    }
}
