import XCTest

final class ManagementUITests: XCTestCase {
    @MainActor
    func testClickingCellOrganelleUpdatesSelectionAndDescription() async throws {
        let app = XCUIApplication()
        app.launchArguments = ["-colidev.uiTestCell3D", "YES"]
        app.launch()
        app.activate()

        let window = app.windows.firstMatch
        guard window.waitForExistence(timeout: 10) else {
            XCTFail("ColiDev did not present its main window. / ColiDev не показал главное окно.\n\(app.debugDescription)")
            return
        }

        let scene = app.descendants(matching: .any)["biology.cell3d.scene"]
        guard scene.waitForExistence(timeout: 15) else {
            XCTFail("3D cell scene was not opened by the UI-test route. / UI-тест не открыл 3D-сцену клетки.\n\(app.debugDescription)")
            return
        }

        let description = app.staticTexts["biology.cell3d.description"]
        guard description.waitForExistence(timeout: 10) else {
            XCTFail("The selected organelle description is missing. / Не найдено описание выбранной органеллы.\n\(app.debugDescription)")
            return
        }
        let organelleMenu = app.popUpButtons["biology.cell3d.organelles"]
        guard organelleMenu.waitForExistence(timeout: 5) else {
            XCTFail("The organelle menu is missing. / Не найдено меню органелл.\n\(app.debugDescription)")
            return
        }
        let tapState = app.staticTexts["biology.cell3d.tapState"]
        guard tapState.waitForExistence(timeout: 5) else {
            XCTFail("The test-only scene tap diagnostic is missing. / Не найден тестовый счётчик щелчков сцены.\n\(app.debugDescription)")
            return
        }
        XCTAssertEqual(
            description.value as? String,
            "Хранит большую часть ДНК клетки; оболочка ядра отделяет её от цитоплазмы.",
            "The nucleus must be selected initially. / При открытии должно быть выбрано ядро."
        )
        let initialTapState = tapState.value as? String
        XCTAssertEqual(initialTapState, "tap=0, part=nucleus")
        XCTAssertEqual(organelleMenu.value as? String, "Ядро", "The menu must start on the nucleus. / В меню должно быть выбрано ядро.")
        XCTAssertEqual(
            scene.label,
            "Упрощённая вращаемая 3D-модель животной клетки; органеллу можно выбрать нажатием или в меню.",
            "The 3D scene must expose its accessible label. / У 3D-сцены должна быть доступная подпись."
        )

        let lessonScrollView = window.scrollViews.element(boundBy: 1)
        guard lessonScrollView.waitForExistence(timeout: 5) else {
            XCTFail("The lesson scroll area is missing. / Не найдена область прокрутки урока.\n\(app.debugDescription)")
            return
        }
        let viewport = lessonScrollView.frame.insetBy(dx: 0, dy: 12)
        for _ in 0..<10 {
            let sceneFrame = scene.frame
            if viewport.contains(sceneFrame) { break }

            // Scroll toward the scene using its live accessibility frame. A fixed
            // series of upward swipes can carry the scene completely past the viewport.
            // Прокручиваем к сцене по её текущей рамке: фиксированные свайпы вверх
            // могут унести сцену далеко за видимую область.
            if sceneFrame.minY < viewport.minY {
                lessonScrollView.swipeDown()
            } else {
                lessonScrollView.swipeUp()
            }
            try await Task.sleep(nanoseconds: 150_000_000)
        }
        XCTAssertTrue(
            viewport.contains(scene.frame),
            "The 3D cell scene is outside the lesson viewport. / 3D-сцена клетки за пределами области урока.\nScene: \(scene.frame), viewport: \(viewport)\n\(scene.debugDescription)"
        )

        // The first mitochondrion is in the front-right quadrant of the orthographic scene.
        // Первая митохондрия находится в передней правой четверти ортографической сцены.
        scene.coordinate(withNormalizedOffset: CGVector(dx: 0.56, dy: 0.38)).click()

        let tapReachedSwiftUI = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value != %@", initialTapState ?? "tap=0, part=nucleus"),
            object: tapState
        )
        let tapResult = await XCTWaiter.fulfillment(of: [tapReachedSwiftUI], timeout: 5)
        guard tapResult == .completed else {
            XCTFail("The click did not reach the SwiftUI tap gesture. / Щелчок не дошёл до SwiftUI-жеста.\n\(app.debugDescription)")
            return
        }

        let mitochondriaDescription = "Участвуют в клеточном дыхании и производстве ATP для многих процессов клетки."
        let descriptionChanged = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", mitochondriaDescription),
            object: description
        )
        let selectionResult = await XCTWaiter.fulfillment(of: [descriptionChanged], timeout: 5)
        XCTAssertEqual(
            selectionResult,
            .completed,
            "Clicking the mitochondrion did not synchronize its selection and description. / Нажатие на митохондрию не синхронизировало выбор и описание.\n\(app.debugDescription)"
        )

        XCTAssertEqual(
            organelleMenu.value as? String,
            "Митохондрии",
            "The menu must follow the organelle selected in the scene. / Меню должно показывать органеллу, выбранную в сцене."
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
