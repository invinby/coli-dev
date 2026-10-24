from __future__ import annotations

import math
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
APP_ROOT = ROOT / "macOS" / "ColiDev"
VECTORS = ROOT / "02_Areas" / "Physics" / "lessons" / "vectors_and_kinematics.md"
THERMAL = ROOT / "02_Areas" / "Zoology" / "lessons" / "thermoregulation_and_heat_exchange.md"


def _section(markdown: str, language_heading: str, next_heading: str) -> str:
    return markdown.split(language_heading, 1)[1].split(next_heading, 1)[0]


def _answer_and_options(section: str, answer_heading: str, options_heading: str) -> tuple[int, list[str]]:
    answer = int(section.split(answer_heading, 1)[1].split("###", 1)[0].strip())
    options_block = section.split(options_heading, 1)[1].split("###", 1)[0]
    options = [line[2:].strip() for line in options_block.splitlines() if line.startswith("- ")]
    return answer, options


def test_vector_answer_key_matches_the_vertical_component_in_both_languages() -> None:
    markdown = VECTORS.read_text(encoding="utf-8")
    expected = 10 * math.sin(math.radians(60))
    assert round(expected, 2) == 8.66

    russian = _section(markdown, "## Русский", "## English")
    english = _section(markdown, "## English", "## Sources")
    for section, answer_heading, options_heading, label in (
        (russian, "### Ответ", "### Варианты", "8,66 м"),
        (english, "### Answer", "### Options", "8.66 m"),
    ):
        answer, options = _answer_and_options(section, answer_heading, options_heading)
        assert len(options) == 3
        assert options[answer - 1] == f"`{label}`"


def test_vector_lab_challenge_uses_the_same_components() -> None:
    strings = (APP_ROOT / "App" / "L10n.swift").read_text(encoding="utf-8")
    challenge = re.search(r'"lab\.vector\.challenge": \("([^"]+)", "([^"]+)"\)', strings)
    assert challenge is not None
    assert "Δx = 5 м" in challenge.group(1) and "Δy ≈ 8,66 м" in challenge.group(1)
    assert "Δx = 5 m" in challenge.group(2) and "Δy ≈ 8.66 m" in challenge.group(2)


def test_thermal_lesson_answer_separates_heat_source_from_stability() -> None:
    markdown = THERMAL.read_text(encoding="utf-8")
    russian = _section(markdown, "## Русский", "## English")
    english = _section(markdown, "## English", "## Sources")

    answer, options = _answer_and_options(russian, "### Ответ", "### Варианты")
    assert "источник тепла" in options[answer - 1] and "гомеотермия" in options[answer - 1]
    answer, options = _answer_and_options(english, "### Answer", "### Options")
    assert "heat source" in options[answer - 1] and "homeothermy" in options[answer - 1]


def test_ported_labs_are_wired_into_the_app_project_and_ci() -> None:
    views = (APP_ROOT / "App" / "LearningViews.swift").read_text(encoding="utf-8")
    project = (APP_ROOT / "ColiDev.xcodeproj" / "project.pbxproj").read_text(encoding="utf-8")
    workflow = (ROOT / ".github" / "workflows" / "ci.yml").read_text(encoding="utf-8")
    strings = (APP_ROOT / "App" / "L10n.swift").read_text(encoding="utf-8")

    assert 'moduleResource == "vectors_and_kinematics"' in views and "VectorKinematicsLab()" in views
    assert 'moduleResource == "thermoregulation_and_heat_exchange"' in views and "ThermalStrategyLab()" in views
    assert "VectorKinematics.swift in Sources" in project
    assert "ThermalStrategy.swift in Sources" in project
    assert "scripts/verify_vector_kinematics.swift" in workflow
    assert "scripts/verify_thermal_strategy.swift" in workflow

    defined = set(re.findall(r'^\s*"(lab\.(?:vector|zoology\.thermal)\.[A-Za-z.]+)":', strings, re.MULTILINE))
    used = set(re.findall(r'"(lab\.(?:vector|zoology\.thermal)\.[A-Za-z.]+)"', views))
    model = (APP_ROOT / "App" / "ThermalStrategy.swift").read_text(encoding="utf-8")
    prefixes = re.findall(r'"(lab\.zoology\.thermal\.[a-z]+)\.\\\(rawValue\)"', model)
    for prefix in prefixes:
        cases = {
            "lab.zoology.thermal.mode": ("ectotherm", "endotherm"),
            "lab.zoology.thermal.source": ("ectotherm", "endotherm"),
            "lab.zoology.thermal.environment": ("cool", "mild", "hot"),
            "lab.zoology.thermal.response": ("externalHeat", "coolerMicrohabitat", "conserveHeat", "dissipateHeat", "observe"),
            "lab.zoology.thermal.effect": ("externalHeat", "coolerMicrohabitat", "conserveHeat", "dissipateHeat", "observe"),
        }[prefix]
        used |= {f"{prefix}.{case}" for case in cases}
    assert used
    assert used <= defined
