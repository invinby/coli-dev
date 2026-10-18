import XCTest

final class ManagementUITests: XCTestCase {
    @MainActor
    func testSettingsExplainsOrchestratorIsNotTheSelectedModel() async throws {
        let app = XCUIApplication()
        app.launch()

        let settingsItem = app.staticTexts["sidebar.settings"]
        XCTAssertTrue(
            settingsItem.waitForExistence(timeout: 15),
            "Settings navigation item did not appear. / Не появился пункт настроек.\n\(app.debugDescription)"
        )
        settingsItem.click()

        let routeExplanation = app.staticTexts["settings.ai.orchestrator-status"]
        XCTAssertTrue(
            routeExplanation.waitForExistence(timeout: 30),
            "Settings must identify the orchestrator separately from the per-request model route. / Настройки должны отделять оркестратор от маршрута модели для отдельного запроса.\n\(app.debugDescription)"
        )
        XCTAssertTrue(
            (routeExplanation.value as? String)?.localizedCaseInsensitiveContains("consilium") == true,
            "The health payload's orchestrator identity was not rendered. / Идентификатор оркестратора из health не показан.\n\(routeExplanation.debugDescription)"
        )
        let routePolicy = app.staticTexts["settings.ai.route-resolution"]
        XCTAssertTrue(
            routePolicy.waitForExistence(timeout: 10),
            "Settings must explain that Auto resolves a route per request. / Настройки должны объяснять, что Auto выбирает маршрут для каждого запроса.\n\(app.debugDescription)"
        )
        XCTAssertTrue((routePolicy.value as? String)?.contains("Auto") == true)

        let paidRoutePolicy = app.descendants(matching: .any)["settings.ai.paid-routes"]
        XCTAssertTrue(
            paidRoutePolicy.waitForExistence(timeout: 10),
            "Settings must expose the live paid-route policy. / Настройки должны показывать текущую политику платных маршрутов.\n\(app.debugDescription)"
        )
        let paidRoutePolicyValue = paidRoutePolicy.value as? String ?? ""
        XCTAssertTrue(
            paidRoutePolicyValue.localizedCaseInsensitiveContains("blocked")
                || paidRoutePolicyValue.localizedCaseInsensitiveContains("заблокированы"),
            "The fresh test backend must show its default free-only policy. / Новый тестовый backend должен показывать политику без платных маршрутов.\n\(paidRoutePolicy.debugDescription)"
        )

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Settings with per-request AI routing explanation"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    @MainActor
    func testHomeDashboardShowsNextActionAndExportsScreenshot() async throws {
        let app = XCUIApplication()
        app.launch()

        let homeTitle = app.staticTexts["home.title"]
        XCTAssertTrue(
            homeTitle.waitForExistence(timeout: 15),
            "The Today dashboard did not appear after launch. / После запуска не открылся экран «Сегодня».\n\(app.debugDescription)"
        )

        let progressTitle = app.staticTexts["home.progress-title"]
        XCTAssertTrue(
            progressTitle.waitForExistence(timeout: 10),
            "The learning progress and next action card is missing. / Не найдена карточка прогресса и следующего шага.\n\(app.debugDescription)"
        )

        let primaryAction = app.buttons["home.primary-action"]
        XCTAssertTrue(
            primaryAction.waitForExistence(timeout: 10),
            "The dashboard does not expose its next learning action. / На главном экране нет следующего учебного действия.\n\(app.debugDescription)"
        )

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "ColiDev Today dashboard"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

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
        XCTAssertTrue(initialTapState?.hasPrefix("tap=0, part=nucleus") == true)
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
        let sceneBecameHittable = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hittable == true"),
            object: scene
        )
        let visibilityResult = await XCTWaiter.fulfillment(of: [sceneBecameHittable], timeout: 10)
        guard visibilityResult == .completed else {
            XCTFail("The test route must open the 3D cell scene inside the lesson viewport. / Тестовый маршрут должен открыть 3D-сцену клетки в видимой области урока.\nScene: \(scene.frame), viewport: \(viewport)\n\(scene.debugDescription)")
            return
        }
        guard viewport.contains(scene.frame) else {
            XCTFail("The 3D cell scene is outside the lesson viewport. / 3D-сцена клетки за пределами области урока.\nScene: \(scene.frame), viewport: \(viewport)\n\(scene.debugDescription)")
            return
        }

        // A seed click lets the live SceneKit renderer report its current target projection.
        // Первый щелчок активирует SceneKit; рендерер сообщит актуальную проекцию цели.
        scene.coordinate(withNormalizedOffset: CGVector(dx: 0.56, dy: 0.38)).click()
        let seedTapRecognized = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value != %@", initialTapState ?? "tap=0, part=nucleus"),
            object: tapState
        )
        let seedTapResult = await XCTWaiter.fulfillment(of: [seedTapRecognized], timeout: 5)
        guard seedTapResult == .completed,
              let seedDiagnostic = tapState.value as? String,
              let targetField = seedDiagnostic.split(separator: " ").first(where: { $0.hasPrefix("mitochondriaTarget=") }) else {
            XCTFail("The live SceneKit click did not provide a mitochondrion target point. / Активный рендерер SceneKit не сообщил координаты митохондрии.\n\(tapState.value ?? tapState.label)")
            return
        }
        let targetValue = targetField.dropFirst("mitochondriaTarget=".count)
        let targetComponents = targetValue.split(separator: ",")
        guard targetComponents.count == 2,
              let targetX = Double(targetComponents[0]),
              let targetY = Double(targetComponents[1]),
              (0...1).contains(targetX),
              (0...1).contains(targetY) else {
            XCTFail("The projected mitochondrion point is invalid. / Неверные координаты проекции митохондрии: \(targetValue)")
            return
        }
        let tapStateBeforeProjectedClick = tapState.value as? String
        scene.coordinate(withNormalizedOffset: CGVector(dx: CGFloat(targetX), dy: CGFloat(targetY))).click()

        let tapWasRecognized = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value != %@", tapStateBeforeProjectedClick ?? ""),
            object: tapState
        )
        let tapResult = await XCTWaiter.fulfillment(of: [tapWasRecognized], timeout: 5)
        guard tapResult == .completed else {
            XCTFail("The click did not reach the native SceneKit click recognizer. / Щелчок не дошёл до нативного обработчика SceneKit. Tap state / Состояние щелчка: \(tapState.value ?? tapState.label); scene frame after click / рамка сцены после щелчка: \(scene.frame); lesson viewport / область урока: \(viewport).\n\(app.debugDescription)")
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
            "Clicking the mitochondrion did not synchronize its selection and description. / Нажатие на митохондрию не синхронизировало выбор и описание. Tap state / Состояние щелчка: \(tapState.value ?? tapState.label); scene frame / рамка сцены: \(scene.frame); lesson viewport / область урока: \(viewport).\n\(app.debugDescription)"
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

    @MainActor
    func testRAGPaneExposesLocalEmbeddingModelControls() async throws {
        let app = XCUIApplication()
        app.launch()

        let managementItem = app.staticTexts["sidebar.management"]
        XCTAssertTrue(managementItem.waitForExistence(timeout: 15))
        managementItem.click()

        let ragTab = app.buttons["control-center.pane.rag"]
        XCTAssertTrue(ragTab.waitForExistence(timeout: 10))
        ragTab.click()

        let modelField = app.textFields["control-center.rag.embedding-model"]
        XCTAssertTrue(
            modelField.waitForExistence(timeout: 10),
            "RAG pane must expose a local Ollama embedding model field.\n\(app.debugDescription)"
        )
        XCTAssertTrue(app.buttons["control-center.rag.save-embedding-model"].exists)

        let disableButton = app.buttons["control-center.rag.disable-embedding-model"]
        XCTAssertTrue(disableButton.waitForExistence(timeout: 10))
        let disableButtonReady = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isEnabled == true"),
            object: disableButton
        )
        let disableButtonResult = await XCTWaiter.fulfillment(of: [disableButtonReady], timeout: 10)
        XCTAssertEqual(disableButtonResult, .completed)

        disableButton.click()
        let statusMessage = app.descendants(matching: .any)["control-center.status-message"]
        let disabledSuccessfully = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value CONTAINS %@ OR value CONTAINS %@", "отключена", "disabled"),
            object: statusMessage
        )
        let disableResult = await XCTWaiter.fulfillment(of: [disabledSuccessfully], timeout: 15)
        guard disableResult == .completed else {
            XCTFail(
                "Disabling semantic search should show a success message. / При отключении должен появиться статус успеха. "
                    + "Message value: \(statusMessage.value ?? "<missing>")\n\(app.debugDescription)"
            )
            return
        }
    }
}
