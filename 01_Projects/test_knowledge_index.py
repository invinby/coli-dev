from __future__ import annotations

from pathlib import Path

import pytest

from knowledge_index import KnowledgeIndex


def test_local_index_searches_russian_and_english_and_reports_file_metadata(tmp_path: Path) -> None:
    project = tmp_path / "project"
    course = project / "02_Areas" / "Physics"
    course.mkdir(parents=True)
    lesson = course / "momentum.md"
    lesson.write_text(
        "# Импульс и momentum\n\n"
        "Импульс тела равен произведению массы на скорость.\n\n"
        "Momentum equals mass times velocity and is conserved in a closed system.\n",
        encoding="utf-8",
    )
    index = KnowledgeIndex(project, tmp_path / "state" / "knowledge.sqlite3")

    russian = index.refresh_and_search("импульс масса скорость")
    assert russian
    assert russian[0]["path"] == "02_Areas/Physics/momentum.md"
    assert russian[0]["source_type"] == "course"
    assert russian[0]["modified_at"].endswith("Z")
    assert russian[0]["location"].count("-") == 1

    english = index.refresh_and_search("conserved momentum system")
    assert english
    assert any("conserved" in source["excerpt"].casefold() for source in english)
    assert index.status()["document_count"] == 1
    assert index.status()["last_checked_at"]


def test_index_refreshes_changed_and_removed_files_and_ignores_unapproved_roots(tmp_path: Path) -> None:
    project = tmp_path / "project"
    course_root = project / "02_Areas" / "Math"
    cheat_root = project / "03_Resources" / "Cheatsheets"
    plan_root = project / "project-plan"
    course_root.mkdir(parents=True)
    cheat_root.mkdir(parents=True)
    plan_root.mkdir(parents=True)

    lesson = course_root / "matrix.md"
    lesson.write_text("# Matrix lesson\n\nMatrix determinant rules and eigenvalues.\n", encoding="utf-8")
    (cheat_root / "linear-algebra.txt").write_text("Vector spaces and matrix transformations.\n", encoding="utf-8")
    (project / "03_Resources" / "system_rules.md").write_text(
        "SECRETKEYWORD should never be included in the course index.\n", encoding="utf-8"
    )
    (plan_root / "requirements.md").write_text(
        "SECRETKEYWORD appears in planning notes only.\n", encoding="utf-8"
    )
    (project / "02_Areas" / ".hidden.md").write_text(
        "SECRETKEYWORD is hidden and must not be indexed.\n", encoding="utf-8"
    )
    index = KnowledgeIndex(project, tmp_path / "state" / "knowledge.sqlite3")

    assert index.refresh_and_search("eigenvalues")
    assert index.refresh_and_search("vector spaces")
    assert index.refresh_and_search("SECRETKEYWORD") == []
    assert index.status()["document_count"] == 2

    lesson.write_text("# Matrix lesson\n\nA unique theorem about eigenvectors.\n", encoding="utf-8")
    assert index.refresh_and_search("eigenvectors")
    assert index.refresh_and_search("determinant") == []

    lesson.unlink()
    (cheat_root / "linear-algebra.txt").unlink()
    assert index.refresh_and_search("eigenvectors") == []
    assert index.status()["document_count"] == 0


@pytest.mark.parametrize(("query", "expected_path"), [
    ("derivatives integrals calculus", "Mathematics"),
    ("pronunciation listening vocabulary", "English"),
    ("electromagnetic induction", "Physics"),
    ("DNA genomics gene expression", "Biology"),
    ("ethology animal behavior", "Zoology"),
    ("programming concurrency async", "Programming"),
])
def test_priority_curriculum_roadmaps_are_retrievable(
    tmp_path: Path, query: str, expected_path: str
) -> None:
    project = Path(__file__).resolve().parent.parent
    index = KnowledgeIndex(project, tmp_path / "knowledge.sqlite3")

    results = index.refresh_and_search(query, limit=4)

    assert results
    assert any(
        source["path"] == f"02_Areas/{expected_path}/curriculum.md"
        for source in results
    )
