import XCTest

final class ManagementUITests: XCTestCase {
    @MainActor
    func testSelectingManagementRendersOverviewContent() {
        let app = XCUIApplication()
        app.launch()

        let managementItem = app.descendants(matching: .any)["sidebar.management"]
        XCTAssertTrue(managementItem.waitForExistence(timeout: 15))

        let managementRow = app.outlineRows.containing(.staticText, identifier: "sidebar.management").firstMatch
        if managementRow.waitForExistence(timeout: 2) {
            managementRow.click()
        } else {
            managementItem.click()
        }

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Control Center navigation result"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        let managementRoot = app.descendants(matching: .any)["control-center.root"]
        XCTAssertTrue(
            managementRoot.waitForExistence(timeout: 10),
            "Control Center root did not appear after selecting its sidebar row. Accessibility tree:\n\(app.debugDescription)"
        )

        let panePicker = app.descendants(matching: .any)["control-center.pane-picker"]
        XCTAssertTrue(
            panePicker.waitForExistence(timeout: 10),
            "Control Center root appeared without its pane picker. Accessibility tree:\n\(app.debugDescription)"
        )

        let systemStatus = app.descendants(matching: .any)["control-center.overview.system-status"]
        XCTAssertTrue(
            systemStatus.waitForExistence(timeout: 10),
            "Control Center overview has no system status heading. Accessibility tree:\n\(app.debugDescription)"
        )
    }
}
