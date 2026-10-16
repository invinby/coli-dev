"""Verify the 3D cell's scene, menu, labels, and hit-test IDs stay aligned."""

from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[3]
views = (ROOT / "macOS/ColiDev/App/LearningViews.swift").read_text(encoding="utf-8")
l10n = (ROOT / "macOS/ColiDev/App/L10n.swift").read_text(encoding="utf-8")
lesson = (ROOT / "02_Areas/Biology/lessons/eukaryotic_cell_organelles.md").read_text(encoding="utf-8")
ui_tests = (ROOT / "macOS/ColiDev/UITests/ManagementUITests.swift").read_text(encoding="utf-8")
content_view = (ROOT / "macOS/ColiDev/App/ContentView.swift").read_text(encoding="utf-8")
module_views = (ROOT / "macOS/ColiDev/App/LearningViews.swift").read_text(encoding="utf-8")
ids_start = views.index("private enum CellOrganelleID {")
ids_end = views.index("private struct EukaryoticCellLab: View {", ids_start)
ids_source = views[ids_start:ids_end]
ids_block = re.search(r"static let all: \[String\] = \[(.*?)\]", ids_source, re.S)
assert ids_block, "Missing canonical 3D cell organelle ID list"
declared_ids = tuple(re.findall(r'"([^\"]+)"', ids_block.group(1)))
ids = ("membrane", "nucleus", "rough_er", "golgi", "mitochondria", "ribosomes", "lysosome")
assert declared_ids == ids, f"Unexpected or out-of-order 3D cell IDs: {declared_ids}"

lab_start = views.index("private struct EukaryoticCellLab: View {")
lab_end = views.index("private struct AdaptationLab: View {", lab_start)
lab = views[lab_start:lab_end]
scene = views[views.index("private struct EukaryoticCellScene: NSViewRepresentable {"):lab_end]

for part in ids:
    assert f'"organelle-{part}"' in scene, f"Missing scene node for organelle ID: {part}"
    assert f'"biology.cell3d.{part}"' in l10n, f"Missing bilingual organelle label: {part}"
    assert f'"biology.cell3d.{part}.function"' in l10n, f"Missing bilingual organelle description: {part}"

for snippet in (
    "EukaryoticCellScene(",
    "tapScreenLocation: $sceneTapScreenLocation",
    "Picker(L10n.text(\"lab.cellPart\", store.language), selection: $selectedPart)",
    ".pickerStyle(.menu)",
    '.accessibilityIdentifier("biology.cell3d.organelles")',
    '.accessibilityIdentifier("biology.cell3d.scene")',
    ".accessibilityElement(children: .ignore)",
    '.accessibilityIdentifier("biology.cell3d.description")',
    '.accessibilityValue(Text(L10n.text("biology.cell3d.\\(selectedPart)", store.language)))',
    'Text(L10n.text("biology.cell3d.\\(selectedPart).function", store.language))',
    "lab.cell3d.interactionHint",
    ".onTapGesture",
    "NSEvent.mouseLocation",
    "sceneTapSequence += 1",
    'Text("tap=\\(sceneTapSequence), part=\\(selectedPart)")',
    '.accessibilityIdentifier("biology.cell3d.tapState")',
):
    assert snippet in lab, f"3D cell lesson UI is missing: {snippet}"

for snippet in (
    "func handleSceneTap(atScreenPoint point: CGPoint, sequence: Int, in view: SCNView)",
    "window.convertPoint(fromScreen: point)",
    "view.convert(windowPoint, from: nil)",
    "view.hitTest(point, options: [.searchMode: SCNHitTestSearchMode.all.rawValue])",
    "selectedPart.wrappedValue = part",
    "for child in node.childNodes",
    "nearestOrganelle(to: point, in: view)",
    "view.projectPoint(node.presentation.worldPosition)",
):
    assert snippet in scene, f"3D cell scene selection wiring is missing: {snippet}"

assert "Нажми прямо на органеллу в 3D-сцене" in lesson, "Russian lesson does not explain direct scene selection"
assert "Click an organelle directly in the 3D scene" in lesson, "English lesson does not explain direct scene selection"
assert "@State private var selection: AppSection? = .today" in content_view, "UI-test launch must start from a valid visible sidebar selection"
assert ".onAppear(perform: openCell3DUITestRouteIfNeeded)" in content_view, "UI-test lesson route must wait until the first screen appears"
assert "DispatchQueue.main.async" in content_view, "UI-test lesson route must be deferred until after the first render"
assert 'UserDefaults.standard.bool(forKey: "colidev.uiTestCell3D")' in content_view, "UI-test route must use a dedicated UserDefaults launch override. / Тестовый маршрут должен использовать отдельный флаг запуска UserDefaults."
assert "testClickingCellOrganelleUpdatesSelectionAndDescription" in ui_tests, "Missing macOS UI coverage for scene selection"
assert 'app.launchArguments = ["-colidev.uiTestCell3D", "YES"]' in ui_tests, "UI test must use a standard UserDefaults argument, not an unknown -- option. / UI-тест должен использовать стандартный аргумент UserDefaults, без неизвестной опции с --."
assert "app.activate()" in ui_tests, "UI test must bring ColiDev to the foreground before checking the window"
assert "window.waitForExistence(timeout: 10)" in ui_tests, "UI test must verify that the main window opens"
assert "description.value as? String" in ui_tests, "UI test must read the lesson text from its accessibility value. / UI-тест должен читать текст урока из значения accessibility."
assert 'NSPredicate(format: "value == %@", mitochondriaDescription)' in ui_tests, "UI test must wait for the selected description value. / UI-тест должен ждать изменения значения выбранного описания."
assert 'app.popUpButtons["biology.cell3d.organelles"]' in ui_tests, "UI test must verify that the accessible organelle menu follows the scene selection. / UI-тест должен проверять, что доступное меню следует за выбором в 3D-сцене."
assert '.id("module-interactive-practice")' in module_views, "The interactive lesson scroll anchor must remain available. / Якорь прокрутки к интерактиву должен сохраниться."
assert '.accessibilityIdentifier("module.interactive-practice")' not in module_views, "The practice container must not override child accessibility IDs. / Контейнер практики не должен перезаписывать ID вложенных элементов доступности."
assert "window.scrollViews.element(boundBy: 1)" in ui_tests, "UI test must scroll the lesson pane instead of the sidebar. / UI-тест должен прокручивать урок, а не боковую панель."
assert "viewport.contains(scene.frame)" in ui_tests, "UI test must keep the 3D scene inside the visible lesson viewport before clicking. / Перед кликом UI-тест должен удерживать 3D-сцену внутри видимой области урока."
assert 'scene.coordinate(withNormalizedOffset: CGVector(dx: 0.56, dy: 0.38)).click()' in ui_tests, "UI test does not click the mitochondrion in the scene"
assert 'app.staticTexts["biology.cell3d.description"]' in ui_tests, "UI test does not inspect the live organelle description"
assert 'app.staticTexts["biology.cell3d.tapState"]' in ui_tests, "UI test does not verify that the scene tap reaches SwiftUI"
assert "The click did not reach the SwiftUI tap gesture." in ui_tests, "UI test does not diagnose whether SwiftUI received the scene tap"

print("3D cell selection IDs, bilingual labels, click handling, keyboard menu, and deferred UI-test routing are aligned. / Идентификаторы органелл, RU/EN-подписи, выбор щелчком, меню и отложенный тестовый маршрут согласованы.")
