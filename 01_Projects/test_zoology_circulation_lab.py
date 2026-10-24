from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
APP_ROOT = ROOT / "macOS" / "ColiDev"
LESSON = ROOT / "02_Areas" / "Zoology" / "lessons" / "comparative_gas_exchange_and_circulation.md"
ANIMALS = ("fish", "amphibian", "mammal")


def _strings() -> dict[str, tuple[str, str]]:
    text = (APP_ROOT / "App" / "L10n.swift").read_text(encoding="utf-8")
    return {
        key: (ru, en)
        for key, ru, en in re.findall(r'^\s*"([^"]+)": \("((?:[^"\\]|\\.)*)", "((?:[^"\\]|\\.)*)"\)', text, re.MULTILINE)
    }


def test_gas_exchange_lesson_gets_its_own_lab_instead_of_the_adaptation_fallback() -> None:
    views = (APP_ROOT / "App" / "LearningViews.swift").read_text(encoding="utf-8")
    routing = views.split('moduleResource == "comparative_gas_exchange_and_circulation"', 1)[1].split("} else", 1)[0]
    assert "CirculationRouteLab()" in routing


def test_lab_routes_match_the_lesson_and_count_heart_passes() -> None:
    strings = _strings()
    lesson = LESSON.read_text(encoding="utf-8")

    assert "сердце → жабры → ткани тела → сердце" in lesson
    assert strings["lab.circulation.route.fish"][0] == "сердце → жабры → ткани тела → сердце"
    for animal, passes in (("fish", 1), ("amphibian", 2), ("mammal", 2)):
        ru_route, en_route = strings[f"lab.circulation.route.{animal}"]
        assert ru_route.count("сердц") == passes + 1, animal
        assert en_route.count("heart") == passes + 1, animal


def test_model_matches_openstax_heart_chambers() -> None:
    model = (APP_ROOT / "App" / "CirculationRoute.swift").read_text(encoding="utf-8")
    assert "case .fish: HeartChambers(atria: 1, ventricles: 1)" in model
    assert "case .amphibian: HeartChambers(atria: 2, ventricles: 1)" in model
    assert "case .mammal: HeartChambers(atria: 2, ventricles: 2)" in model
    assert "openstax.org/books/biology-2e/pages/40-1-overview-of-the-circulatory-system" in LESSON.read_text(encoding="utf-8")


def test_every_circulation_key_is_localized_and_the_lab_is_in_the_project_and_ci() -> None:
    strings = _strings()
    keys = {"lab.circulation." + suffix for suffix in (
        "title", "hint", "animalTitle", "predict", "choose", "check", "correct", "review", "limit",
    )}
    for animal in ANIMALS:
        keys |= {f"lab.circulation.{kind}.{animal}" for kind in ("animal", "route", "heart", "exchange", "explain")}
    missing = keys - set(strings)
    assert not missing, missing
    assert all(ru.strip() and en.strip() and ru != en for key, (ru, en) in strings.items() if key in keys and key != "lab.circulation.choose")

    project = (APP_ROOT / "ColiDev.xcodeproj" / "project.pbxproj").read_text(encoding="utf-8")
    workflow = (ROOT / ".github" / "workflows" / "ci.yml").read_text(encoding="utf-8")
    assert "CirculationRoute.swift in Sources" in project
    assert "scripts/verify_circulation_route.swift" in workflow
