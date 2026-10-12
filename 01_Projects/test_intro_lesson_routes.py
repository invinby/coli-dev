from __future__ import annotations

import json
import re
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = PROJECT_ROOT / "02_Areas" / "intro_lesson_routes.json"

EXPECTED_ROUTES = {
    "mathematics": "intro",
    "english": "intro",
    "physics": "intro",
    "biology": "intro",
    "zoology": "intro",
    "programming": "intro",
}


def _lesson_frontmatter(markdown: str) -> dict[str, str]:
    parts = markdown.split("---", 2)
    assert len(parts) == 3 and not parts[0].strip(), "lesson must have YAML front matter"
    return {
        key.strip(): value.strip().strip("\"'")
        for line in parts[1].splitlines()
        if ":" in line
        for key, value in [line.split(":", 1)]
    }


def test_intro_routes_preserve_progress_ids_and_open_distinct_source_backed_lessons() -> None:
    assert MANIFEST_PATH.is_file(), (
        "intro lesson routes must point to distinct source-backed Markdown lessons while preserving intro.* IDs"
    )
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    assert manifest["schema_version"] == 1
    routes = manifest["routes"]
    assert {route["subject_id"] for route in routes} == set(EXPECTED_ROUTES)
    assert len(routes) == len(EXPECTED_ROUTES)

    for route in routes:
        subject = route["subject_id"]
        resource = route["resource"]
        assert resource == EXPECTED_ROUTES[subject]
        assert route["progress_lesson_id"] == f"intro.{subject}"

        lesson_path = PROJECT_ROOT / "02_Areas" / subject.capitalize() / "lessons" / f"{resource}.md"
        assert lesson_path.is_file(), f"missing bundled lesson for {subject}: {lesson_path}"
        lesson = lesson_path.read_text(encoding="utf-8")
        metadata = _lesson_frontmatter(lesson)
        assert metadata.get("lesson_id") == route["progress_lesson_id"]
        assert metadata.get("source_checked")
        assert "## Русский" in lesson and "## English" in lesson
        assert re.search(r"(?m)^## Sources\s*$", lesson)
        sources = lesson.split("## Sources", 1)[1]
        assert re.search(r"https://", sources), f"missing cited source for {subject}"
