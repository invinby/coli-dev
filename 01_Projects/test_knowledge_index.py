from __future__ import annotations

import hashlib
import re
import sqlite3
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

from knowledge_index import (
    KnowledgeIndex,
    OllamaEmbeddingProvider,
    _source_checked_date,
    _source_review_interval_days,
    _source_review_schedule,
    _split_markdown,
)


class FakeEmbeddingProvider:
    model = "test-embedding-model"

    def __init__(self) -> None:
        self.calls: list[list[str]] = []

    def embed(self, texts: list[str]) -> list[list[float]]:
        self.calls.append(texts)
        return [
            [1.0, 0.0] if "optimization methods" in text.casefold()
            or "calculus" in text.casefold()
            else [0.0, 1.0]
            for text in texts
        ]


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


def test_retrieval_attaches_only_canonical_official_source_links(tmp_path: Path) -> None:
    project = tmp_path / "project"
    course = project / "02_Areas" / "Biology" / "lessons"
    course.mkdir(parents=True)
    lesson = course / "active_transport.md"
    lesson.write_text(
        "# Active transport\n\n"
        "Cells move substances against a concentration gradient by using energy.\n\n"
        "- OpenStax, [Active transport](https://openstax.org/books/biology-2e/pages/5-3-active-transport#pump)\n"
        "- Untrusted: https://example.test/lesson\n",
        encoding="utf-8",
    )
    index = KnowledgeIndex(project, tmp_path / "state" / "knowledge.sqlite3")

    results = index.refresh_and_search("move substances against concentration gradient energy")

    assert results
    assert results[0]["official_references"] == [{
        "title": "Active transport",
        "url": "https://openstax.org/books/biology-2e/pages/5-3-active-transport",
    }]


def test_manual_refresh_indexes_sources_without_calling_embeddings(tmp_path: Path) -> None:
    project = tmp_path / "project"
    course = project / "02_Areas" / "Physics"
    course.mkdir(parents=True)
    (course / "momentum.md").write_text(
        "# Momentum\n\nMomentum equals mass times velocity.\n",
        encoding="utf-8",
    )
    embeddings = FakeEmbeddingProvider()
    index = KnowledgeIndex(project, tmp_path / "state" / "knowledge.sqlite3", embeddings)

    status = index.refresh_sources()

    assert status["document_count"] == 1
    assert status["last_checked_at"]
    assert embeddings.calls == []
    assert index.refresh_and_search("momentum velocity")
    assert embeddings.calls


def test_index_status_summarizes_author_review_schedules_without_claiming_freshness(tmp_path: Path) -> None:
    project = tmp_path / "project"
    course = project / "02_Areas" / "Physics"
    course.mkdir(parents=True)
    database = tmp_path / "state" / "knowledge.sqlite3"
    index = KnowledgeIndex(project, database)

    empty_status = index.status()
    assert empty_status["document_count"] == 0
    assert empty_status["review_due_document_count"] == 0
    assert empty_status["review_scheduled_document_count"] == 0
    assert empty_status["review_schedule_missing_document_count"] == 0

    (course / "due.md").write_text(
        "---\nsource_checked: 2020-01-01\nsource_review_interval_days: 30\n---\n"
        "# Due source\n\nA source with a review reminder in the past.\n",
        encoding="utf-8",
    )
    (course / "scheduled.md").write_text(
        "---\nsource_checked: 2099-01-01\nsource_review_interval_days: 30\n---\n"
        "# Scheduled source\n\nA source with a future author review date.\n",
        encoding="utf-8",
    )
    (course / "no-date.md").write_text(
        "---\nsource_review_interval_days: 30\n---\n"
        "# Missing check date\n\nAn interval without a checked date is not a schedule.\n",
        encoding="utf-8",
    )
    (course / "no-schedule.md").write_text(
        "# No schedule\n\nThis document has no author review metadata.\n",
        encoding="utf-8",
    )

    index.refresh_sources()
    status = index.status()

    assert status["document_count"] == 4
    assert status["review_due_document_count"] == 1
    assert status["review_scheduled_document_count"] == 1
    assert status["review_schedule_missing_document_count"] == 2


def test_source_review_date_is_distinct_and_migrates_existing_index(tmp_path: Path) -> None:
    project = tmp_path / "project"
    course = project / "02_Areas" / "Physics"
    course.mkdir(parents=True)
    lesson = course / "periods.md"
    content = (
        "---\nsource_checked: 2026-10-05\nsource_review_interval_days: 30\n---\n"
        "# Orbital periods\n\n"
        "Orbital periods scale with the semimajor axis in a two-body model.\n"
    )
    lesson.write_text(content, encoding="utf-8")
    stat = lesson.stat()
    database = tmp_path / "state" / "knowledge.sqlite3"
    database.parent.mkdir(parents=True)
    with sqlite3.connect(database) as connection:
        connection.execute(
            """CREATE TABLE documents (
                path TEXT PRIMARY KEY, title TEXT NOT NULL, digest TEXT NOT NULL,
                modified_ns INTEGER NOT NULL, size_bytes INTEGER NOT NULL, modified_at TEXT NOT NULL
            )"""
        )
        connection.execute(
            """CREATE TABLE chunks (
                path TEXT NOT NULL REFERENCES documents(path) ON DELETE CASCADE,
                chunk_index INTEGER NOT NULL, heading TEXT NOT NULL, start_line INTEGER NOT NULL,
                end_line INTEGER NOT NULL, text TEXT NOT NULL, PRIMARY KEY (path, chunk_index)
            )"""
        )
        connection.execute(
            "INSERT INTO documents VALUES (?, ?, ?, ?, ?, ?)",
            (
                "02_Areas/Physics/periods.md", "Orbital periods", hashlib.sha256(content.encode()).hexdigest(),
                stat.st_mtime_ns, stat.st_size, "2026-10-04T00:00:00Z",
            ),
        )
        connection.execute(
            "INSERT INTO chunks VALUES (?, ?, ?, ?, ?, ?)",
            (
                "02_Areas/Physics/periods.md", 0, "Orbital periods", 6, 6,
                "Orbital periods scale with the semimajor axis in a two-body model.",
            ),
        )

    index = KnowledgeIndex(project, database)
    legacy_status = index.status()
    assert legacy_status["document_count"] == 1
    assert legacy_status["review_due_document_count"] == 0
    assert legacy_status["review_scheduled_document_count"] == 0
    assert legacy_status["review_schedule_missing_document_count"] == 1

    result = index.refresh_and_search("orbital periods semimajor axis", limit=1)[0]

    assert result["source_checked_at"] == "2026-10-05"
    assert result["source_review_interval_days"] == "30"
    assert result["source_review_due_on"] == "2026-11-04"
    assert result["source_review_status"] in {"due", "scheduled"}
    assert result["modified_at"].endswith("Z")
    assert result["modified_at"] != result["source_checked_at"]
    assert "source_checked" not in result["excerpt"]


def test_source_review_date_rejects_invalid_or_ambiguous_frontmatter() -> None:
    assert _source_checked_date("---\nsource_checked: 2026-10-05\n---\nBody") == "2026-10-05"
    assert _source_checked_date("---\nsource_checked: 2026-02-30\n---\nBody") is None
    assert _source_checked_date(
        "---\nsource_checked: 2026-10-05\nsource_checked: 2026-10-04\n---\nBody"
    ) is None
    assert _source_checked_date(
        "---\nmetadata:\n  source_checked: 2026-10-05\n---\nBody"
    ) is None
    assert _source_checked_date("# Body\nsource_checked: 2026-10-05") is None


def test_source_review_interval_is_strict_and_bounded() -> None:
    assert _source_review_interval_days(
        "---\nsource_review_interval_days: 30\n---\nBody"
    ) == 30
    assert _source_review_interval_days(
        "---\nsource_review_interval_days: 0\n---\nBody"
    ) is None
    assert _source_review_interval_days(
        "---\nsource_review_interval_days: 3651\n---\nBody"
    ) is None
    assert _source_review_interval_days(
        "---\nsource_review_interval_days: 30\nsource_review_interval_days: 45\n---\nBody"
    ) is None
    assert _source_review_interval_days(
        "---\nsource_review_interval_days: \"30\"\n---\nBody"
    ) is None
    assert _source_review_interval_days(
        "---\nmetadata:\n  source_review_interval_days: 30\n---\nBody"
    ) is None


def test_author_declared_review_schedule_has_deterministic_due_status() -> None:
    from datetime import date

    assert _source_review_schedule("2026-10-01", 3, date(2026, 10, 3)) == ("2026-10-04", "scheduled")
    assert _source_review_schedule("2026-10-01", 3, date(2026, 10, 4)) == ("2026-10-04", "due")
    assert _source_review_schedule("2026-10-01", None, date(2026, 10, 4)) == (None, None)


def test_markdown_frontmatter_is_not_indexed_and_line_numbers_stay_absolute() -> None:
    chunks = _split_markdown(
        "---\nsource_checked: 2026-10-05\nsource_review_interval_days: 30\n---\n"
        "# Orbital periods\n\n"
        "Use orbital period to estimate a body's year.\n",
        "Orbital periods",
    )

    assert chunks
    assert all(start_line > 3 for start_line, _, _, _ in chunks)
    assert "source_checked" not in "\n".join(chunk for _, _, _, chunk in chunks)
    assert "source_review_interval_days" not in "\n".join(chunk for _, _, _, chunk in chunks)
    assert "orbital period" in "\n".join(chunk for _, _, _, chunk in chunks)


def test_plain_text_cheatsheet_is_not_treated_as_yaml_frontmatter() -> None:
    chunks = _split_markdown(
        "---\nsource_checked: keep this literal text\n---\nUseful cheat-sheet data.\n",
        "Cheat sheet",
        allow_frontmatter=False,
    )

    assert "source_checked: keep this literal text" in "\n".join(chunk for _, _, _, chunk in chunks)


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
    ("phylogenetics population genetics bioinformatics", "Biology"),
    ("ethology animal behavior", "Zoology"),
    ("programming concurrency async", "Programming"),
])
def test_priority_curriculum_roadmaps_are_retrievable(
    tmp_path: Path, query: str, expected_path: str
) -> None:
    project = Path(__file__).resolve().parent.parent
    index = KnowledgeIndex(project, tmp_path / "knowledge.sqlite3")

    results = index.refresh_and_search(query, limit=8)

    assert results
    assert any(
        source["path"] == f"02_Areas/{expected_path}/curriculum.md"
        for source in results
    )


@pytest.mark.parametrize(("query", "expected_path"), [
    (
        "linear function model taxi starting charge slope kilometres fare traffic waiting",
        "Mathematics/lessons/functions_as_models.md",
    ),
    (
        "real valued square root radicand nonnegative x less than or equal eight domain interval range",
        "Mathematics/lessons/domain_and_range.md",
    ),
    (
        "derivative instantaneous rate secant tangent difference quotient limit h to zero slope x squared",
        "Mathematics/lessons/rates_of_change_and_derivative.md",
    ),
    (
        "present simple present continuous habits temporary be ing stative verbs she studies",
        "English/lessons/present_simple_and_continuous.md",
    ),
    (
        "present perfect simple continuous result quantity duration for since has read has been reading",
        "English/lessons/present_perfect_simple_continuous.md",
    ),
    (
        "результат количество длительность for since has read has been reading present perfect",
        "English/lessons/present_perfect_simple_continuous.md",
    ),
    (
        "east 14 N west 6 N 4 kg free-body diagram resultant force",
        "Physics/lessons/net_force_and_acceleration.md",
    ),
    (
        "work-energy theorem net work changes kinetic energy mass speed joules",
        "Physics/lessons/work_and_kinetic_energy.md",
    ),
    (
        "signed velocity perfectly inelastic collision carts stick total momentum impulse",
        "Physics/lessons/impulse_and_momentum.md",
    ),
    (
        "erythrocyte hypertonic water leaves aquaporins osmosis solute",
        "Biology/lessons/passive_transport_osmosis.md",
    ),
    (
        "heterozygous genotype Aa recessive aa segregation gametes Punnett cross probability",
        "Biology/lessons/mendelian_inheritance.md",
    ),
    (
        "thicker coat fox heritable trait population generations acclimation behavior",
        "Zoology/lessons/adaptation_and_behavior.md",
    ),
    (
        "single circuit fish gills amphibian pulmocutaneous gas exchange closed open circulation four chamber crocodilians",
        "Zoology/lessons/comparative_gas_exchange_and_circulation.md",
    ),
    (
        "count_even number modulo two return count list empty list",
        "Programming/lessons/conditions_loops_functions.md",
    ),
])
def test_bilingual_lesson_modules_are_retrievable(
    tmp_path: Path, query: str, expected_path: str
) -> None:
    project = Path(__file__).resolve().parent.parent
    index = KnowledgeIndex(project, tmp_path / "knowledge.sqlite3")

    results = index.refresh_and_search(query, limit=4)

    assert results
    assert results[0]["path"] == f"02_Areas/{expected_path}"
    lesson = project / "02_Areas" / expected_path
    expected_source_checked = _source_checked_date(lesson.read_text(encoding="utf-8"))
    assert results[0]["source_checked_at"] == expected_source_checked
    assert "source_checked" not in results[0]["excerpt"]


def test_bundled_english_lesson_rag_returns_its_official_primary_source(tmp_path: Path) -> None:
    project = Path(__file__).resolve().parent.parent
    index = KnowledgeIndex(project, tmp_path / "knowledge.sqlite3")

    results = index.refresh_and_search("present perfect result quantity duration for since")

    assert results
    lesson = next(
        source for source in results
        if source["path"] == "02_Areas/English/lessons/present_perfect_simple_continuous.md"
    )
    assert {
        "title": "British Council LearnEnglish, “Present perfect simple and continuous” (B1–B2)",
        "url": "https://learnenglish.britishcouncil.org/free-resources/grammar/b1-b2/present-perfect-simple-continuous",
    } in lesson["official_references"]


def test_programming_variables_lesson_rag_returns_python_docs_source(tmp_path: Path) -> None:
    project = Path(__file__).resolve().parent.parent
    index = KnowledgeIndex(project, tmp_path / "knowledge.sqlite3")

    results = index.refresh_and_search("Python variable names assignment dynamic types int str float")

    assert results
    lesson = next(
        source for source in results
        if source["path"] == "02_Areas/Programming/lessons/variables_and_types.md"
    )
    assert lesson["source_checked_at"] == "2026-10-06"
    assert {
        "title": "Python 3.14 Tutorial, “An Informal Introduction to Python” (official Python documentation; consulted 2026-10-06)",
        "url": "https://docs.python.org/3/tutorial/introduction.html",
    } in lesson["official_references"]


def test_programming_collections_lesson_rag_returns_official_python_tutorial_pages(
    tmp_path: Path,
) -> None:
    project = Path(__file__).resolve().parent.parent
    index = KnowledgeIndex(project, tmp_path / "knowledge.sqlite3")

    results = index.refresh_and_search(
        "ordered list append items enumerate index for loop sequence"
    )

    assert results
    lesson = next(
        source for source in results
        if source["path"] == "02_Areas/Programming/lessons/collections_and_loops.md"
    )
    assert lesson["source_checked_at"] == "2026-10-06"
    assert {
        "title": "Python Tutorial: Lists and sequences — Python Software Foundation",
        "url": "https://docs.python.org/3/tutorial/introduction.html",
    } in lesson["official_references"]
    assert {
        "title": "Python Tutorial: for Statements and range — Python Software Foundation",
        "url": "https://docs.python.org/3/tutorial/controlflow.html",
    } in lesson["official_references"]


def test_bundled_biology_lesson_links_official_genetics_basics(tmp_path: Path) -> None:
    project = Path(__file__).resolve().parent.parent
    index = KnowledgeIndex(project, tmp_path / "knowledge.sqlite3")

    results = index.refresh_and_search(
        "DNA bases gene protein RNA genotype phenotype environmental conditions"
    )

    lesson = next(
        source for source in results
        if source["path"] == "02_Areas/Biology/lessons/dna_genes_and_traits.md"
    )
    assert lesson["source_checked_at"] == "2026-10-06"
    assert {
        "title": "What is DNA?",
        "url": "https://medlineplus.gov/genetics/understanding/basics/dna/",
    } in lesson["official_references"]
    assert {
        "title": "What is a gene?",
        "url": "https://medlineplus.gov/genetics/understanding/basics/gene/",
    } in lesson["official_references"]


def test_bundled_photosynthesis_lesson_links_openstax_primary_material(tmp_path: Path) -> None:
    project = Path(__file__).resolve().parent.parent
    index = KnowledgeIndex(project, tmp_path / "knowledge.sqlite3")

    results = index.refresh_and_search("photosynthesis light reactions ATP NADPH Calvin cycle carbon dioxide G3P")

    lesson = next(
        source for source in results
        if source["path"] == "02_Areas/Biology/lessons/photosynthesis_energy_and_carbon.md"
    )
    assert lesson["source_checked_at"] == "2026-10-06"
    reference_urls = {reference["url"] for reference in lesson["official_references"]}
    assert "https://openstax.org/books/biology-2e/pages/8-1-overview-of-photosynthesis" in reference_urls
    assert "https://openstax.org/books/biology-2e/pages/8-2-the-light-dependent-reactions-of-photosynthesis" in reference_urls
    assert "https://openstax.org/books/biology-2e/pages/8-3-using-light-energy-to-make-organic-molecules" in reference_urls


def test_bundled_cell_lesson_links_primary_eukaryotic_and_membrane_references(tmp_path: Path) -> None:
    project = Path(__file__).resolve().parent.parent
    index = KnowledgeIndex(project, tmp_path / "knowledge.sqlite3")

    results = index.refresh_and_search(
        "eukaryotic cell nucleus rough ER Golgi vesicle organelle plasma membrane"
    )

    lesson = next(
        source for source in results
        if source["path"] == "02_Areas/Biology/lessons/eukaryotic_cell_organelles.md"
    )
    assert lesson["source_checked_at"] == "2026-10-06"
    reference_urls = {reference["url"] for reference in lesson["official_references"]}
    assert "https://openstax.org/books/biology-2e/pages/4-3-eukaryotic-cells" in reference_urls
    assert "https://openstax.org/books/biology-2e/pages/4-4-the-endomembrane-system-and-proteins" in reference_urls
    assert "https://openstax.org/books/biology-2e/pages/5-1-components-and-structure" in reference_urls


def test_bundled_zoology_lesson_links_official_animal_symmetry_material(tmp_path: Path) -> None:
    project = Path(__file__).resolve().parent.parent
    index = KnowledgeIndex(project, tmp_path / "knowledge.sqlite3")

    results = index.refresh_and_search(
        "animal asymmetry radial bilateral symmetry body plan echinoderm larvae sea star"
    )

    lesson = next(
        source for source in results
        if source["path"] == "02_Areas/Zoology/lessons/symmetry_and_body_plans.md"
    )
    assert lesson["source_checked_at"] == "2026-10-06"
    reference_urls = {reference["url"] for reference in lesson["official_references"]}
    assert "https://openstax.org/books/biology-2e/pages/27-2-features-used-to-classify-animals" in reference_urls
    assert "https://openstax.org/books/biology-2e/pages/33-1-animal-form-and-function" in reference_urls


def test_bundled_zoology_lineages_lesson_links_licensed_elife_xml(tmp_path: Path) -> None:
    project = Path(__file__).resolve().parent.parent
    index = KnowledgeIndex(project, tmp_path / "knowledge.sqlite3")

    results = index.refresh_and_search(
        "phylogenetic tree clade common ancestor Ecdysozoa Lophotrochozoa arthropods nematodes"
    )

    lesson = next(
        source for source in results
        if source["path"] == "02_Areas/Zoology/lessons/major_animal_lineages.md"
    )
    assert lesson["source_checked_at"] == "2026-10-06"
    assert {
        "title": "eLife Research Article: Peripheral and central employment of acid-sensing ion channels during early bilaterian evolution",
        "url": "https://raw.githubusercontent.com/elifesciences/elife-article-xml/master/articles/elife-81613-v1.xml",
    } in lesson["official_references"]


def test_curriculum_lesson_links_resolve_to_bilingual_module_files() -> None:
    project = Path(__file__).resolve().parent.parent
    areas = project / "02_Areas"
    linked_subjects: set[str] = set()

    for curriculum in areas.glob("*/curriculum.md"):
        subject = curriculum.parent.name
        content = curriculum.read_text(encoding="utf-8")
        resources = []
        table_width: int | None = None
        for line in content.splitlines():
            if not line.strip().startswith("|"):
                table_width = None
                continue
            columns = [column.strip() for column in line.strip().strip("|").split("|")]
            if columns and ("Module" in columns[0] or "Модуль" in columns[0]):
                table_width = len(columns)
                continue
            if not columns or all(set(column) <= {"-", ":"} for column in columns):
                continue
            linked_cells = [index for index, column in enumerate(columns) if column.startswith("lesson:")]
            if linked_cells:
                assert len(columns) == table_width, f"Inconsistent curriculum table columns in {curriculum}"
                assert len(columns) >= 3 and linked_cells == [2], f"Lesson links must use the third column in {curriculum}"
                resources.append(columns[2].removeprefix("lesson:"))
        assert resources, f"{curriculum.relative_to(project)} has no linked lesson"

        for resource in resources:
            lesson = curriculum.parent / "lessons" / f"{resource}.md"
            assert lesson.is_file(), f"Missing lesson linked from {curriculum}: {resource}"
            lesson_text = lesson.read_text(encoding="utf-8")
            expected_id = f"{subject.casefold()}.{resource}"
            assert f"lesson_id: {expected_id}" in lesson_text
            assert "## Русский" in lesson_text
            assert "## English" in lesson_text
            russian_remainder = lesson_text.split("## Русский", 1)[1]
            russian = russian_remainder.split("## English", 1)[0]
            english_remainder = lesson_text.split("## English", 1)[1]
            english = english_remainder.split("## Sources", 1)[0]
            for section, question_heading in ((russian, "Вопрос"), (english, "Question")):
                def heading_body(name: str) -> str:
                    match = re.search(
                        rf"^### {re.escape(name)}\s*\n(.*?)(?=^### |\Z)",
                        section,
                        flags=re.MULTILINE | re.DOTALL,
                    )
                    return match.group(1).strip() if match else ""

                question = heading_body(question_heading)
                options = re.findall(r"(?m)^- .+$", heading_body("Варианты" if question_heading == "Вопрос" else "Options"))
                answer = heading_body("Ответ" if question_heading == "Вопрос" else "Answer")
                explanation = heading_body("Разбор" if question_heading == "Вопрос" else "Explanation")
                assert question, f"Missing {question_heading.lower()} in {lesson}"
                assert options, f"Missing answer choices in {lesson}"
                assert answer.isdigit() and 1 <= int(answer) <= len(options), f"Invalid answer index in {lesson}"
                assert explanation, f"Missing answer explanation in {lesson}"
            linked_subjects.add(subject)

    assert linked_subjects == {
        "Biology", "English", "Mathematics", "Physics", "Programming", "Zoology"
    }


def test_biology_gene_expression_intermediate_lesson_is_linked() -> None:
    project = Path(__file__).resolve().parent.parent
    curriculum = (project / "02_Areas/Biology/curriculum.md").read_text(encoding="utf-8")
    lesson = project / "02_Areas/Biology/lessons/gene_expression_and_regulation.md"

    assert "lesson:gene_expression_and_regulation" in curriculum
    assert lesson.is_file()
    content = lesson.read_text(encoding="utf-8")
    assert "lesson_id: biology.gene_expression_and_regulation" in content
    assert "languages: ru, en" in content
    assert "### Границы модели" in content
    assert "### Limits and safe execution" in content


def test_biology_cell_cycle_intermediate_lesson_is_linked() -> None:
    project = Path(__file__).resolve().parent.parent
    curriculum = (project / "02_Areas/Biology/curriculum.md").read_text(encoding="utf-8")
    lesson = project / "02_Areas/Biology/lessons/cell_cycle_and_differentiation.md"

    assert "lesson:cell_cycle_and_differentiation" in curriculum
    assert lesson.is_file()
    content = lesson.read_text(encoding="utf-8")
    assert "lesson_id: biology.cell_cycle_and_differentiation" in content
    assert "languages: ru, en" in content
    assert "### Границы модели" in content
    assert "### Limits and safe execution" in content


def test_zoology_animal_function_foundations_lesson_is_linked() -> None:
    project = Path(__file__).resolve().parent.parent
    curriculum = (project / "02_Areas/Zoology/curriculum.md").read_text(encoding="utf-8")
    lesson = project / "02_Areas/Zoology/lessons/animal_function_and_environment.md"

    assert "lesson:animal_function_and_environment" in curriculum
    assert lesson.is_file()
    content = lesson.read_text(encoding="utf-8")
    assert "lesson_id: zoology.animal_function_and_environment" in content
    assert "languages: ru, en" in content
    assert "### Границы модели" in content
    assert "### Limits and safe execution" in content


def test_zoology_function_trainer_has_all_bilingual_labels() -> None:
    project = Path(__file__).resolve().parent.parent
    localization = (project / "macOS/ColiDev/App/L10n.swift").read_text(encoding="utf-8")
    raw_values = ["feeding", "gasExchange", "movement", "reproduction"]

    for raw_value in raw_values:
        for group in ["function", "example", "mechanism", "limitation"]:
            key = f'"lab.zoology.{group}.{raw_value}"'
            assert key in localization, f"Missing RU/EN localization for {key}"


def test_bundled_lessons_have_a_complete_bilingual_learning_structure() -> None:
    project = Path(__file__).resolve().parent.parent
    areas = project / "02_Areas"
    required_sections = {
        "Русский": ["Цель", "Идея и механизм", "Вопрос", "Варианты", "Ответ", "Разбор"],
        "English": ["Goal", "Idea and mechanism", "Question", "Options", "Answer", "Explanation"],
    }
    practice_headings = {
        "Русский": ["Исследуй и потренируйся", "Исследуй 3D-модель", "Исследуй в тренажёре"],
        "English": ["Explore and practise", "Explore and practice", "Explore the 3D model", "Explore the lab"],
    }
    limit_headings = {
        "Русский": ["Границы модели", "Границы правила", "Границы вывода", "Границы и безопасный запуск"],
        "English": ["Limits", "Limits of the inference", "Limits and safe execution"],
    }

    def body_after_heading(markdown: str, heading: str, next_level: str) -> str:
        match = re.search(
            rf"^{re.escape(heading)}\s*\n(.*?)(?=^{re.escape(next_level)}|\Z)",
            markdown,
            flags=re.MULTILINE | re.DOTALL,
        )
        return match.group(1).strip() if match else ""

    def section_body(language_body: str, section_headings: list[str]) -> str:
        for heading in section_headings:
            match = re.search(
                rf"^### {re.escape(heading)}\s*\n(.*?)(?=^### |\Z)",
                language_body,
                flags=re.MULTILINE | re.DOTALL,
            )
            if match and match.group(1).strip():
                return match.group(1).strip()
        return ""

    lessons = sorted(areas.glob("*/lessons/*.md"))
    assert lessons, "No bundled lessons found"
    for lesson in lessons:
        markdown = lesson.read_text(encoding="utf-8")
        assert re.search(r"^## Sources\s*$", markdown, re.MULTILINE), f"Missing Sources in {lesson}"
        sources = markdown.split("## Sources", 1)[1]
        assert re.search(r"https://\S+", sources), f"No source link in {lesson}"

        for language, required in required_sections.items():
            language_heading = f"## {language}"
            following_heading = "## English" if language == "Русский" else "## Sources"
            language_body = body_after_heading(markdown, language_heading, following_heading)
            assert language_body, f"Missing {language} section in {lesson}"
            for section in required:
                assert section_body(language_body, [section]), f"Missing {section} in {language} in {lesson}"
            assert section_body(language_body, practice_headings[language]), f"Missing practice in {language} in {lesson}"
            assert section_body(language_body, limit_headings[language]), f"Missing limitations in {language} in {lesson}"


def test_local_embeddings_find_semantic_match_and_cache_document_vectors(tmp_path: Path) -> None:
    project = tmp_path / "project"
    math = project / "02_Areas" / "Mathematics"
    physics = project / "02_Areas" / "Physics"
    math.mkdir(parents=True)
    physics.mkdir(parents=True)
    (math / "calculus.md").write_text(
        "# Differential calculus\n\nDerivatives measure local rates of change.\n",
        encoding="utf-8",
    )
    (physics / "fields.md").write_text(
        "# Electromagnetic fields\n\nElectric and magnetic fields propagate waves.\n",
        encoding="utf-8",
    )
    provider = FakeEmbeddingProvider()
    index = KnowledgeIndex(
        project,
        tmp_path / "state" / "knowledge.sqlite3",
        embedding_provider=provider,
    )

    result = index.refresh_and_search("optimization methods", limit=1)
    assert result[0]["path"] == "02_Areas/Mathematics/calculus.md"
    assert len(provider.calls) == 2  # One document batch and one query.

    result = index.refresh_and_search("optimization methods", limit=1)
    assert result[0]["path"] == "02_Areas/Mathematics/calculus.md"
    assert len(provider.calls) == 3  # Cached document vectors; only the query is embedded.


def test_embeddings_fail_safely_to_lexical_search(tmp_path: Path) -> None:
    project = tmp_path / "project"
    course = project / "02_Areas" / "Biology"
    course.mkdir(parents=True)
    (course / "cells.md").write_text(
        "# Cell membranes\n\nMembranes regulate the movement of molecules.\n",
        encoding="utf-8",
    )

    class OfflineEmbeddingProvider:
        model = "offline-model"

        def __init__(self) -> None:
            self.call_count = 0

        def embed(self, texts: list[str]) -> list[list[float]]:
            self.call_count += 1
            raise ConnectionError("Ollama is offline")

    provider = OfflineEmbeddingProvider()
    index = KnowledgeIndex(
        project,
        tmp_path / "state" / "knowledge.sqlite3",
        embedding_provider=provider,
    )
    assert index.refresh_and_search("membranes molecules")[0]["path"] == "02_Areas/Biology/cells.md"
    assert index.refresh_and_search("membranes molecules")
    assert provider.call_count == 1  # Avoid a slow local timeout on every question.


def test_ollama_embedding_provider_rejects_remote_endpoints() -> None:
    with pytest.raises(ValueError, match="loopback"):
        OllamaEmbeddingProvider("https://example.com", "embeddinggemma")


def test_ollama_embedding_provider_accepts_loopback_without_network_call() -> None:
    provider = OllamaEmbeddingProvider("http://127.0.0.1:11434", "embeddinggemma")
    assert provider.model.endswith(":embeddinggemma")


def test_ollama_embedding_provider_uses_local_embed_api_without_proxy() -> None:
    provider = OllamaEmbeddingProvider("http://127.0.0.1:11434", "embeddinggemma")
    response = MagicMock()
    response.json.return_value = {"embeddings": [[0.2, 0.8]]}
    client = MagicMock()
    client.__enter__.return_value = client
    client.post.return_value = response

    with patch("httpx.Client", return_value=client) as client_factory:
        assert provider.embed(["local study text"]) == [[0.2, 0.8]]

    client_factory.assert_called_once()
    assert client_factory.call_args.kwargs["trust_env"] is False
    assert client_factory.call_args.kwargs["follow_redirects"] is False
    client.post.assert_called_once_with(
        "http://127.0.0.1:11434/api/embed",
        json={"model": "embeddinggemma", "input": ["local study text"]},
    )
