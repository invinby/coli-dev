from pathlib import Path


APP = Path("macOS/ColiDev/App")
views = (APP / "LearningViews.swift").read_text(encoding="utf-8")
l10n = (APP / "L10n.swift").read_text(encoding="utf-8")
start = views.index("private struct BiomoleculeLab: View {")
end = views.index("private struct NaturalSelectionLab: View {", start)
lab = views[start:end]

required_view_wiring = (
    "@State private var selectedGroup: BiomoleculeGroup? = nil",
    "assessmentTracker.recordSubmission(",
    "group: selectedGroup,",
    "for: selectedExample",
    "store.recordStudyAssessment(",
    'lessonID: "biology.biomolecules_and_building_blocks",',
    "evidence: evidence",
    "selectedExample.correctGroup",
)
missing = [snippet for snippet in required_view_wiring if snippet not in lab]
assert not missing, f"Biomolecule lesson UI is missing assessment safeguards: {missing}"

for language_phrase in (
    "рибозимы",
    "ribozymes",
    "белковый фермент",
    "protein enzyme",
):
    assert language_phrase in l10n, f"Missing accurate bilingual enzyme scope: {language_phrase}"

assert 'case "enzyme": selectedGroup = "protein"' not in lab
assert 'case "starch": selectedGroup = "carbohydrate"' not in lab
print("Biomolecule lesson integration checks passed.")
