from __future__ import annotations

import re
from pathlib import Path


APP = Path(__file__).resolve().parents[1] / "macOS" / "ColiDev" / "App"
KEY = "StudyProgressionPolicy.previewLockedLessonsDefaultsKey"


def test_preview_setting_is_opt_in_and_localized() -> None:
    policy = (APP / "StudyRecommendation.swift").read_text(encoding="utf-8")
    content = (APP / "ContentView.swift").read_text(encoding="utf-8")
    strings = (APP / "L10n.swift").read_text(encoding="utf-8")

    assert 'static let previewLockedLessonsDefaultsKey = "colidev.previewLockedLessons"' in policy
    settings = content.split("private struct SettingsView: View {", 1)[1]
    assert f"@AppStorage({KEY}) private var previewLockedLessons = false" in settings
    assert "Toggle(isOn: $previewLockedLessons)" in settings
    for key in ("settings.learningPath", "settings.previewLocked", "settings.previewLockedHelp", "roadmap.previewLesson"):
        assert re.search(rf'^\s*"{re.escape(key)}": \(', strings, re.MULTILINE), key


def test_preview_only_relaxes_opening_a_lesson_not_recommendations() -> None:
    content = (APP / "ContentView.swift").read_text(encoding="utf-8")
    views = (APP / "LearningViews.swift").read_text(encoding="utf-8")

    opener = content.split("private func openCourseLesson(subject: Subject, resource: String, focusPractice: Bool)", 1)[1].split("\n    }\n", 1)[0]
    assert "!previewLockedLessons, !StudyProgressionPolicy.previewLockedLessonsForUITest," in opener

    roadmap = views.split("struct SubjectOverviewView: View {", 1)[1].split("\nstruct ", 1)[0]
    assert f"@AppStorage({KEY}) private var previewLockedLessons = false" in roadmap
    assert ".disabled(!isAvailable && !isPreview)" in roadmap
    assert '"lock.fill"' in roadmap, "levels stay visibly locked while preview is off"

    # Continue and recommendations keep using the progression policy directly.
    recommendations = content.split("private func openCourseLesson(subject: Subject, resource: String, focusPractice: Bool)", 1)[1]
    assert "return StudyProgressionPolicy.isAvailable(" in recommendations
    assert "previewLockedLessons" not in recommendations.split("return StudyProgressionPolicy.isAvailable(", 1)[1].split("}", 1)[0]
