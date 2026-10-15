import XCTest

final class ManagementUITests: XCTestCase {
    @MainActor
    func testSelectingManagementRendersOverviewContent() {
        let app = XCUIApplication()
        app.launch()

        let managementItem = app.descendants(matching: .any)["sidebar.management"]
        XCTAssertTrue(managementItem.waitForExistence(timeout: 15))
        managementItem.click()

        let panePicker = app.descendants(matching: .any)["control-center.pane-picker"]
        XCTAssertTrue(panePicker.waitForExistence(timeout: 10))

        let systemStatus = app.descendants(matching: .any)["control-center.overview.system-status"]
        XCTAssertTrue(systemStatus.waitForExistence(timeout: 10))
    }
}
