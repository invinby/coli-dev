from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

from trusted_sources import TrustedSourceMonitor


LESSON = (
    Path(__file__).resolve().parents[1]
    / "02_Areas"
    / "Programming"
    / "lessons"
    / "search_and_complexity.md"
)
APP_ROOT = Path(__file__).resolve().parents[1] / "macOS" / "ColiDev"


def test_data_structure_lesson_covers_choice_and_memory_in_both_languages() -> None:
    markdown = LESSON.read_text(encoding="utf-8")
    russian = markdown.split("## Русский", 1)[1].split("## English", 1)[0]
    english = markdown.split("## English", 1)[1].split("## Sources", 1)[0]

    assert "### Выбор структуры данных" in russian
    assert "### Choosing a data structure" in english
    for section in (russian, english):
        assert "`list`" in section
        assert "`set`" in section
        assert "`dict`" in section
        assert "sys.getsizeof" in section
        assert "shallow" in section.lower() or "поверхност" in section.lower()


def test_python_shallow_size_reference_is_allowlisted_with_psf_policy() -> None:
    url = "https://docs.python.org/3.14/library/sys.html#sys.getsizeof"
    canonical = "https://docs.python.org/3.14/library/sys.html"

    assert TrustedSourceMonitor._canonical_url(url) == canonical
    policy = TrustedSourceMonitor._rag_policy(url)
    assert policy is not None
    assert policy["license"] == "Python Software Foundation License Version 2"
    assert policy["license_url"] == "https://docs.python.org/3/license.html"


def test_bilingual_memory_example_runs_without_claiming_fixed_sizes() -> None:
    markdown = LESSON.read_text(encoding="utf-8")
    blocks = re.findall(r"```python\s*\n(.*?)\n```", markdown, re.DOTALL)
    assert len(blocks) == 2
    assert blocks[0] == blocks[1]

    result = subprocess.run(
        [sys.executable, "-c", blocks[0]],
        capture_output=True,
        text=True,
        check=True,
    )
    lines = result.stdout.strip().splitlines()
    assert [line.split(maxsplit=1)[0] for line in lines] == ["list", "set", "dict"]
    assert all(re.fullmatch(r"(?:list|set|dict) \d+", line) for line in lines)


def test_data_structure_practice_is_wired_with_stable_assessment_ids() -> None:
    model = (APP_ROOT / "App" / "AlgorithmComplexity.swift").read_text(encoding="utf-8")
    verifier = (APP_ROOT / "scripts" / "verify_algorithm_complexity.swift").read_text(encoding="utf-8")
    views = (APP_ROOT / "App" / "LearningViews.swift").read_text(encoding="utf-8")

    scenario_ids = (
        "programming.data_structures.keep_order_and_duplicates",
        "programming.data_structures.unique_membership",
        "programming.data_structures.lookup_by_key",
    )
    assert "enum DataStructureChoicePractice" in model
    assert all(scenario_id in model for scenario_id in scenario_ids)
    assert "DataStructureChoicePractice" in verifier
    assert all(scenario_id in verifier for scenario_id in scenario_ids)
    assert "DataStructureChoiceLab()" in views
    assert "itemIDs: DataStructureChoicePractice.scenarios.map(\\.id)" in views
    assert "itemID: scenario.id" in views
    assert 'store.recordStudyAssessment(lessonID: "programming.search_and_complexity"' in views
