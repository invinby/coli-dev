"""Проверяет доступность панелей Центра управления / Verify accessible Control Center panes."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
CONTENT_VIEW = ROOT / "macOS" / "ColiDev" / "App" / "ContentView.swift"
source = CONTENT_VIEW.read_text(encoding="utf-8")


def property_block(name: str) -> str:
    marker = f"private var {name}: some View"
    start = source.find(marker)
    if start < 0:
        raise AssertionError(f"Не найдена панель ManagementView / Missing ManagementView pane: {name}")
    candidates = [
        index
        for token in ("\n    private var ", "\n    private func ")
        if (index := source.find(token, start + len(marker))) >= 0
    ]
    end = min(candidates) if candidates else len(source)
    return source[start:end]


panes = {
    "overviewPane": "control-center.overview",
    "coursesPane": "control-center.courses",
    "modelsPane": "control-center.models",
    "ragPane": "control-center.rag",
    "sourcesPane": "control-center.sources",
    "integrationsPane": "control-center.integrations",
}

for pane_name, identifier in panes.items():
    if identifier not in property_block(pane_name):
        raise AssertionError(
            f"ID {identifier} должен принадлежать панели {pane_name} / "
            f"ID {identifier} must identify its own {pane_name} view"
        )

if '.accessibilityIdentifier("control-center.pane-picker")' not in source:
    raise AssertionError(
        "Переключателю Центра управления нужен стабильный accessibility ID / "
        "Control Center pane picker needs a stable accessibility identifier"
    )

management_row = source.find(".tag(AppSection.management)")
management_id = source.find('.accessibilityIdentifier("sidebar.management")')
if management_row < 0 or management_id < 0 or abs(management_row - management_id) > 220:
    raise AssertionError(
        "Пункт Центра управления в боковой панели должен иметь стабильный ID / "
        "Management sidebar item needs a stable accessibility identifier"
    )

print("Доступность панелей Центра управления проверена / Control Center pane accessibility mapping is consistent.")
