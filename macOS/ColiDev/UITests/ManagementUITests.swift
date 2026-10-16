import XCTest

final class ManagementUITests: XCTestCase {
    @MainActor
    func testClickingCellOrganelleUpdatesSelectionAndDescription() async throws {
        let app = XCUIApplication()
        app.launchArguments = ["--coli-dev-ui-test-cell3d", "-colidev.language", "ru"]
        app.launch()

        let scene = app.descendants(matching: .any)["biology.cell3d.scene"]
        XCTAssertTrue(
            scene.waitForExistence(timeout: 15),
            "3D cell scene was not opened by the UI-test route. / UI-тест не открыл 3D-сцену клетки.\n\(app.debugDescription)"
        )

        let description = app.staticTexts["biology.cell3d.description"]
        XCTAssertTrue(
            description.waitForExistence(timeout: 10),
            "The selected organelle description is missing. / Не найдено описание выбранной органеллы.\n\(app.debugDescription)"
        )
        XCTAssertEqual(
            description.label,
            "Хранит большую часть ДНК клетки; оболочка ядра отделяет её от цитоплазмы.",
            "The nucleus must be selected initially. / При открытии должно быть выбрано ядро."
        )

        if !scene.isHittable {
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(
            scene.isHittable,
            "The 3D cell scene is not hittable. / По 3D-сцене клетки нельзя нажать.\n\(scene.debugDescription)"
        )

        // The first mitochondrion is in the front-right quadrant of the orthographic scene.
        // Первая митохондрия находится в передней правой четверти ортографической сцены.
        scene.coordinate(withNormalizedOffset: CGVector(dx: 0.56, dy: 0.38)).click()

        let mitochondriaDescription = "Участвуют в клеточном дыхании и производстве ATP для многих процессов клетки."
        let descriptionChanged = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", mitochondriaDescription),
            object: description
        )
        let selectionResult = await XCTWaiter.fulfillment(of: [descriptionChanged], timeout: 5)
        XCTAssertEqual(
            selectionResult,
            .completed,
            "Clicking the mitochondrion did not synchronize its selection and description. / Нажатие на митохондрию не синхронизировало выбор и описание.\n\(app.debugDescription)"
        )

        let sceneSelection = app.descendants(matching: .any)["biology.cell3d.scene"]
        XCTAssertEqual(
            sceneSelection.value as? String,
            "Митохондрии",
            "The accessible scene value must announce the selected organelle. / Значение сцены должно объявлять выбранную органеллу."
        )
    }

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
        let overviewTab = app.buttons["control-center.pane.overview"]
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

        let additionalPanes: [(title: String, id: String, anchorID: String)] = [
            ("Курсы", "courses", "control-center.courses.description"),
            ("Локальные модели", "models", "control-center.models.description"),
            ("RAG", "rag", "control-center.rag.description"),
            ("Источники", "sources", "control-center.sources.description"),
            ("Сервисы", "integrations", "control-center.integrations.providers-heading"),
        ]

        for pane in additionalPanes {
            let tab = app.buttons["control-center.pane.\(pane.id)"]
            XCTAssertTrue(
                tab.waitForExistence(timeout: 10),
                "Control Center tab '\(pane.title)' was missing.\n\(app.debugDescription)"
            )
            XCTAssertTrue(
                tab.isEnabled,
                "Control Center tab '\(pane.title)' is disabled.\n\(tab.debugDescription)\n\(app.debugDescription)"
            )
            XCTAssertTrue(
                tab.isHittable,
                "Control Center tab '\(pane.title)' is not hittable.\n\(tab.debugDescription)\n\(app.debugDescription)"
            )
            app.activate()
            XCTAssertEqual(
                app.state,
                .runningForeground,
                "ColiDev lost foreground focus before selecting Control Center tab '\(pane.title)'.\n\(app.debugDescription)"
            )
            tab.click()

            let paneContent = app.descendants(matching: .any)
                .matching(identifier: pane.anchorID)
                .firstMatch
            XCTAssertTrue(
                paneContent.waitForExistence(timeout: 10),
                "Control Center tab '\(pane.title)' opened without its expected content.\n\(app.debugDescription)"
            )

            let paneScreenshot = XCTAttachment(screenshot: app.screenshot())
            paneScreenshot.name = "Control Center pane: \(pane.title)"
            paneScreenshot.lifetime = .keepAlways
            add(paneScreenshot)
        }

        overviewTab.click()
        XCTAssertTrue(
            systemStatus.waitForExistence(timeout: 10),
            "Control Center could not return to its overview after visiting every pane.\n\(app.debugDescription)"
        )
    }
}
