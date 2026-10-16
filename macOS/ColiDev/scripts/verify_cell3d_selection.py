"""Verify the 3D cell's scene, menu, labels, and hit-test IDs stay aligned."""

from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[3]
views = (ROOT / "macOS/ColiDev/App/LearningViews.swift").read_text(encoding="utf-8")
l10n = (ROOT / "macOS/ColiDev/App/L10n.swift").read_text(encoding="utf-8")
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
    "EukaryoticCellScene(selectedPart: $selectedPart)",
    "Picker(L10n.text(\"lab.cellPart\", store.language), selection: $selectedPart)",
    ".pickerStyle(.menu)",
    '.accessibilityIdentifier("biology.cell3d.organelles")',
    '.accessibilityValue(Text(L10n.text("biology.cell3d.\\(selectedPart)", store.language)))',
    'Text(L10n.text("biology.cell3d.\\(selectedPart).function", store.language))',
    "lab.cell3d.interactionHint",
):
    assert snippet in lab, f"3D cell lesson UI is missing: {snippet}"

for snippet in (
    "NSClickGestureRecognizer",
    "view.hitTest(point, options: [.searchMode: SCNHitTestSearchMode.all.rawValue])",
    "selectedPart.wrappedValue = part",
    "for child in node.childNodes",
):
    assert snippet in scene, f"3D cell scene selection wiring is missing: {snippet}"

print("3D cell selection IDs, bilingual labels, click handling, and keyboard menu are aligned.")
