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

        let reloadButton = app.buttons["Обновить данные панели"]
        XCTAssertTrue(
            reloadButton.waitForExistence(timeout: 10),
            "Control Center overview did not expose its refresh button.\n\(app.debugDescription)"
        )
        let overviewTab = app.radioButtons["Обзор"]
        XCTAssertTrue(
            overviewTab.waitForExistence(timeout: 10),
            "Control Center overview tab was missing.\n\(app.debugDescription)"
        )

        let backendReady = app.staticTexts.matching(
            NSPredicate(
                format: "value IN %@ OR label IN %@",
                ["Работает", "Running"],
                ["Работает", "Running"]
            )
        ).firstMatch
        XCTAssertTrue(
            backendReady.waitForExistence(timeout: 30),
            "The app did not start its bundled local backend.\n\(app.debugDescription)"
        )

        let dashboardStatusMessage = app.descendants(matching: .any)["control-center.status-message"]
        let dashboardLoaded = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: dashboardStatusMessage
        )
        let dashboardLoadResult = await XCTWaiter.fulfillment(of: [dashboardLoaded], timeout: 10)
        XCTAssertEqual(
            dashboardLoadResult,
            .completed,
            "The Control Center remained in a load-error state after the backend became ready.\n\(app.debugDescription)"
        )

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Control Center after backend readiness"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "Control Center accessibility hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)

        let visibleRefreshButton = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hittable == true"),
            object: reloadButton
        )
        let visibleOverviewTab = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hittable == true"),
            object: overviewTab
        )
        let visibilityResult = await XCTWaiter.fulfillment(
            of: [visibleRefreshButton, visibleOverviewTab],
            timeout: 10
        )
        XCTAssertEqual(
            visibilityResult,
            .completed,
            "Control Center refresh button exists in accessibility but is not interactable.\n\(reloadButton.debugDescription)\n\(app.debugDescription)"
        )
    }
}
