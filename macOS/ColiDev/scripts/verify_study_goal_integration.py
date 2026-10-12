"""Check that active study-goal state reaches the existing Today dashboard."""

from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[3]


def require(path: str, marker: str, description: str) -> None:
    text = (ROOT / path).read_text(encoding="utf-8")
    if marker not in text:
        raise AssertionError(f"Missing {description}: {path} should contain {marker!r}")


require(
    "macOS/ColiDev/App/StudyRecommendation.swift",
    "struct StudyGoal: Codable, Equatable",
    "a persistable goal tied to a curriculum route",
)
require(
    "macOS/ColiDev/App/StudyRecommendation.swift",
    "enum StudyGoalPlanner",
    "goal milestones derived from real course prerequisites",
)
require(
    "macOS/ColiDev/App/AppModels.swift",
    'forKey: "colidev.activeStudyGoal"',
    "local persistence for the learner-selected goal",
)
require(
    "macOS/ColiDev/App/ContentView.swift",
    "StudyGoalPickerView",
    "an in-product goal picker connected to the existing dashboard",
)
require(
    "macOS/ColiDev/App/ContentView.swift",
    "goalProgress",
    "goal progress rendered in TodayView",
)
require(
    "macOS/ColiDev/App/L10n.swift",
    '"home.goal.title": (',
    "bilingual dashboard copy for study goals",
)
require(
    "macOS/ColiDev/App/L10n.swift",
    '"home.goal.lastOpened": (',
    "bilingual saved stop-point copy for returning learners",
)

l10n = (ROOT / "macOS/ColiDev/App/L10n.swift").read_text(encoding="utf-8")
content_view = (ROOT / "macOS/ColiDev/App/ContentView.swift").read_text(encoding="utf-8")
declared_keys = set(re.findall(r'^\s*"([^"]+)":\s*\(', l10n, flags=re.MULTILINE))
goal_keys = set(re.findall(r'"(home\.goal\.[^"]+)"', content_view))
missing_keys = sorted(goal_keys - declared_keys)
if missing_keys:
    raise AssertionError(f"Study-goal UI uses undefined RU/EN localization keys: {missing_keys}")
