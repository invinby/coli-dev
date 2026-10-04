from __future__ import annotations

from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

from knowledge_index import KnowledgeIndex, OllamaEmbeddingProvider


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
