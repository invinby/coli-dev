from __future__ import annotations

import asyncio
import sqlite3
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

import httpx
import pytest

import trusted_sources
from trusted_sources import TrustedSourceMonitor, _MAX_SOURCES


def _write_lesson(root: Path, body: str) -> None:
    lesson = root / "02_Areas" / "Physics" / "lessons" / "source_test.md"
    lesson.parent.mkdir(parents=True)
    lesson.write_text(body, encoding="utf-8")


def _monitor(root: Path, tmp_path: Path) -> TrustedSourceMonitor:
    return TrustedSourceMonitor(root, tmp_path / "knowledge.sqlite3")


def test_inventory_explicitly_closes_database_connection(tmp_path: Path, monkeypatch) -> None:
    class TrackingConnection(sqlite3.Connection):
        def close(self) -> None:
            self.was_closed = True
            super().close()

    opened: list[TrackingConnection] = []
    original_connect = sqlite3.connect

    def tracked_connect(*args, **kwargs):
        connection = original_connect(*args, **kwargs, factory=TrackingConnection)
        connection.was_closed = False
        opened.append(connection)
        return connection

    monkeypatch.setattr(trusted_sources.sqlite3, "connect", tracked_connect)
    monitor = _monitor(tmp_path, tmp_path)

    monitor.inventory()

    assert opened
    assert all(connection.was_closed for connection in opened)


def test_automatic_check_is_due_for_new_and_stale_sources(tmp_path: Path) -> None:
    monitor = _monitor(tmp_path, tmp_path)
    url = "https://openstax.org/books/college-physics-2e/pages/7-1-work-the-scientific-definition"
    _write_lesson(tmp_path, f"[OpenStax work page]({url})")
    checked_at = datetime(2025, 1, 1, tzinfo=timezone.utc)

    assert monitor.seconds_until_automatic_check(now=checked_at) == 0

    reference = monitor._references()[0][0]
    checked_text = checked_at.isoformat().replace("+00:00", "Z")
    monitor._save_check(
        reference,
        etag='"version-1"',
        last_modified=None,
        checked_at=checked_text,
        http_status=200,
        state="unchanged",
        content_digest="digest-1",
        content_checked_at=checked_text,
    )

    assert monitor.seconds_until_automatic_check(
        now=checked_at + timedelta(hours=23)
    ) == 3600
    assert monitor.seconds_until_automatic_check(
        now=checked_at + timedelta(hours=24)
    ) == 0


@pytest.mark.parametrize("state", ["network_error", "unavailable"])
def test_automatic_check_retries_transient_source_failures_after_six_hours(
    tmp_path: Path, state: str,
) -> None:
    monitor = _monitor(tmp_path, tmp_path)
    url = "https://openstax.org/books/college-physics-2e/pages/7-1-work-the-scientific-definition"
    _write_lesson(tmp_path, f"[OpenStax work page]({url})")
    reference = monitor._references()[0][0]
    checked_at = datetime(2025, 1, 1, tzinfo=timezone.utc)
    checked_text = checked_at.isoformat().replace("+00:00", "Z")
    monitor._save_check(
        reference,
        etag=None,
        last_modified=None,
        checked_at=checked_text,
        http_status=None,
        state=state,
    )

    assert monitor.seconds_until_automatic_check(
        now=checked_at + timedelta(hours=5)
    ) == 3600
    assert monitor.seconds_until_automatic_check(
        now=checked_at + timedelta(hours=6)
    ) == 0


def test_automatic_check_has_no_schedule_without_approved_sources(tmp_path: Path) -> None:
    monitor = _monitor(tmp_path, tmp_path)

    assert monitor.seconds_until_automatic_check() is None


def test_automatic_check_fetches_only_sources_that_are_due(tmp_path: Path) -> None:
    monitor = _monitor(tmp_path, tmp_path)
    fresh_url = "https://openstax.org/books/biology-2e/pages/3-1-synthesis-of-biological-macromolecules"
    due_url = "https://openstax.org/books/biology-2e/pages/3-2-carbohydrates"
    _write_lesson(tmp_path, f"[Fresh source]({fresh_url})\n[Due source]({due_url})")
    references = {reference.url: reference for reference in monitor._references()[0]}
    now = datetime.now(timezone.utc)

    for url, age, state, digest in (
        (fresh_url, timedelta(hours=2), "unchanged", "fresh-digest"),
        (due_url, timedelta(hours=7), "network_error", None),
    ):
        checked_at = now - age
        checked_text = checked_at.isoformat().replace("+00:00", "Z")
        monitor._save_check(
            references[url],
            etag='"version-1"' if digest else None,
            last_modified=None,
            checked_at=checked_text,
            http_status=200 if digest else None,
            state=state,
            content_digest=digest,
            content_checked_at=checked_text if digest else None,
        )

    requested_urls: list[str] = []

    async def handler(request: httpx.Request) -> httpx.Response:
        requested_urls.append(str(request.url))
        return httpx.Response(
            200,
            headers={"content-type": "text/html; charset=utf-8"},
            text="<html><body><main><article><p>Updated approved source.</p></article></main></body></html>",
        )

    async def check() -> dict[str, object]:
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            return await monitor.check_sources(client, due_only=True)

    result = asyncio.run(check())

    assert requested_urls == [due_url]
    assert [item["url"] for item in result["checks"]] == [due_url]
    assert result["checked_count"] == 1
    assert result["supported_count"] == 2


def test_reference_scan_deduplicates_allowed_urls_and_ignores_untrusted_domains(
    tmp_path: Path,
) -> None:
    url = "https://openstax.org/books/college-physics-2e/pages/7-1-work-the-scientific-definition"
    _write_lesson(
        tmp_path,
        f"[OpenStax work page]({url}#section)\n"
        f"[Duplicate page]({url})\n"
        "[Untrusted](https://example.test/lesson)\n"
        "[Insecure](http://openstax.org/books/college-physics-2e/pages/7-1-work-the-scientific-definition)\n",
    )

    references, unsupported_count, omitted_count = _monitor(tmp_path, tmp_path)._references()

    assert len(references) == 1
    assert references[0].url == url
    assert references[0].title == "OpenStax work page"
    assert references[0].lesson_path == "02_Areas/Physics/lessons/source_test.md"
    assert unsupported_count == 2
    assert omitted_count == 0


def test_gene_expression_sources_use_rag_only_for_licensed_genome_glossary_pages(
    tmp_path: Path,
) -> None:
    urls = {
        "https://medlineplus.gov/genetics/understanding/howgeneswork/makingprotein/",
        "https://www.genome.gov/genetics-glossary/Gene-Expression",
        "https://www.genome.gov/genetics-glossary/Gene-Regulation",
        "https://www.genome.gov/genetics-glossary/Promoter",
    }
    rejected = "https://www.genome.gov/genetics-glossary/Other-Term"
    _write_lesson(
        tmp_path,
        "\n".join(f"[Official source]({url})" for url in sorted(urls | {rejected})),
    )
    monitor = _monitor(tmp_path, tmp_path)

    references, unsupported_count, omitted_count = monitor._references()

    assert {reference.url for reference in references} == urls
    assert unsupported_count == 1
    assert omitted_count == 0
    genome_urls = {url for url in urls if "genome.gov" in url}
    metadata_only_urls = urls - genome_urls
    assert all(monitor._rag_policy(url) is not None for url in genome_urls)
    assert all(monitor._rag_policy(url) is None for url in metadata_only_urls)
    assert all(not monitor._has_rag_snapshot(url) for url in urls)


def test_cell_cycle_source_rag_policy_respects_reuse_permissions(tmp_path: Path) -> None:
    urls = {
        "https://openstax.org/books/biology-2e/pages/10-2-the-cell-cycle",
        "https://www.genome.gov/genetics-glossary/Chromatid",
    }
    rejected = "https://www.genome.gov/genetics-glossary/Unapproved-Term"
    _write_lesson(
        tmp_path,
        "\n".join(f"[Official source]({url})" for url in sorted(urls | {rejected})),
    )
    monitor = _monitor(tmp_path, tmp_path)

    references, unsupported_count, omitted_count = monitor._references()

    assert {reference.url for reference in references} == urls
    assert unsupported_count == 1
    assert omitted_count == 0
    assert monitor._rag_policy("https://www.genome.gov/genetics-glossary/Chromatid") is not None
    assert monitor._rag_policy("https://openstax.org/books/biology-2e/pages/10-2-the-cell-cycle") is None
    assert all(not monitor._has_rag_snapshot(url) for url in urls)


def test_ncbi_sources_are_exact_path_monitored_metadata_only(tmp_path: Path) -> None:
    urls = {
        "https://www.ncbi.nlm.nih.gov/books/NBK26854/",
        "https://www.ncbi.nlm.nih.gov/books/NBK550206/",
        "https://www.ncbi.nlm.nih.gov/books/NBK9842/",
    }
    rejected = "https://www.ncbi.nlm.nih.gov/books/NBK999999/"
    _write_lesson(
        tmp_path,
        "\n".join(f"[Official source]({url})" for url in sorted(urls | {rejected})),
    )
    monitor = _monitor(tmp_path, tmp_path)

    references, unsupported_count, omitted_count = monitor._references()

    assert {reference.url for reference in references} == urls
    assert unsupported_count == 1
    assert omitted_count == 0
    assert all(monitor._rag_policy(url) is None for url in urls)
    assert all(not monitor._has_rag_snapshot(url) for url in urls)


def test_biology_replicate_sources_are_exact_path_monitored_metadata_only(
    tmp_path: Path,
) -> None:
    urls = {
        "https://online.stat.psu.edu/stat502/Lesson07",
    }
    rejected = {
        "https://online.stat.psu.edu/stat502/Lesson08",
    }
    _write_lesson(
        tmp_path,
        "\n".join(
            [f"[Official source]({url})" for url in sorted(urls)]
            + [f"[Unreviewed source]({url})" for url in sorted(rejected)]
        ),
    )
    monitor = _monitor(tmp_path, tmp_path)

    references, unsupported_count, omitted_count = monitor._references()

    assert {reference.url for reference in references} == urls
    assert unsupported_count == 1
    assert omitted_count == 0
    assert all(monitor._rag_policy(url) is None for url in urls)
    assert all(not monitor._has_rag_snapshot(url) for url in urls)


def test_current_murre_study_sources_are_exact_path_metadata_only(tmp_path: Path) -> None:
    publisher_url = "https://www.sciencedirect.com/science/article/pii/S1095643325000789"
    pubmed_url = "https://pubmed.ncbi.nlm.nih.gov/40393560/"
    rejected = [
        "https://www.sciencedirect.com/science/article/pii/S0000000000000000",
        "https://pubmed.ncbi.nlm.nih.gov/40393561/",
    ]
    _write_lesson(
        tmp_path,
        "\n".join([f"[Publisher]({publisher_url})", f"[PubMed]({pubmed_url})"] + rejected),
    )
    monitor = _monitor(tmp_path, tmp_path)

    references, unsupported_count, omitted_count = monitor._references()

    assert {reference.url for reference in references} == {publisher_url, pubmed_url}
    assert unsupported_count == 2
    assert omitted_count == 0
    assert all(monitor._rag_policy(url) is None for url in (publisher_url, pubmed_url))
    assert all(not monitor._has_rag_snapshot(url) for url in (publisher_url, pubmed_url))


def test_zoology_function_sources_are_monitored_metadata_only(tmp_path: Path) -> None:
    urls = {
        "https://openstax.org/books/biology-2e/pages/33-1-animal-form-and-function",
        "https://openstax.org/books/biology-2e/pages/34-1-digestive-systems",
        "https://openstax.org/books/biology-2e/pages/38-1-types-of-skeletal-systems",
        "https://openstax.org/books/biology-2e/pages/39-1-systems-of-gas-exchange",
        "https://openstax.org/books/biology-2e/pages/43-2-fertilization",
    }
    _write_lesson(tmp_path, "\n".join(f"[OpenStax]({url})" for url in sorted(urls)))
    monitor = _monitor(tmp_path, tmp_path)

    references, unsupported_count, omitted_count = monitor._references()

    assert {reference.url for reference in references} == urls
    assert unsupported_count == 0
    assert omitted_count == 0
    assert all(monitor._rag_policy(url) is None for url in urls)
    assert all(not monitor._has_rag_snapshot(url) for url in urls)


def test_approved_markdown_links_preserve_titles_and_reject_unapproved_urls() -> None:
    content = (
        "- OpenStax, [Active transport](https://openstax.org/books/biology-2e/pages/5-3-active-transport#pump)\n"
        "- Untrusted page: https://example.test/lesson\n"
    )

    assert TrustedSourceMonitor.approved_markdown_links(content) == [{
        "title": "Active transport",
        "url": "https://openstax.org/books/biology-2e/pages/5-3-active-transport",
    }]


def test_only_licensed_python_tutorial_text_is_cached_for_rag_and_refreshes(
    tmp_path: Path,
) -> None:
    url = "https://docs.python.org/3/tutorial/controlflow.html"
    _write_lesson(tmp_path, f"[Python control flow]({url})")
    monitor = _monitor(tmp_path, tmp_path)
    page_text = "Python control flow includes conditional statements. For loops iterate over items."
    version = 1

    async def handler(_request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            200,
            headers={"content-type": "text/html; charset=utf-8", "etag": f'"v{version}"'},
            text=(
                "<html><head><title>More Control Flow Tools</title></head><body>"
                f"<main><article><p>{page_text}</p></article></main></body></html>"
            ),
        )

    async def check() -> dict[str, object]:
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            return await monitor.check_sources(client)

    first = asyncio.run(check())
    found = monitor.search_rag_sources("Python control flow statements")
    assert first["checks"][0]["state"] == "available_untracked"
    assert len(found) == 1
    assert found[0]["source_type"] == "official_web"
    assert found[0]["license"] == "Python Software Foundation License Version 2"
    assert found[0]["license_url"] == "https://docs.python.org/3/license.html"
    assert "control flow" in found[0]["excerpt"].casefold()

    version = 2
    page_text = "Python control flow uses pattern matching and while loops."
    second = asyncio.run(check())
    refreshed = monitor.search_rag_sources("Python pattern matching")
    assert second["checks"][0]["state"] == "changed"
    assert len(refreshed) == 1
    assert "pattern matching" in refreshed[0]["excerpt"].casefold()
    assert monitor.inventory()["sources"][0]["rag_content_state"] == "cached"


def test_licensed_source_search_prioritizes_rare_query_terms_over_generic_overlap(
    tmp_path: Path,
) -> None:
    generic_url = "https://docs.python.org/3/library/bisect.html"
    specific_url = "https://docs.python.org/3/tutorial/controlflow.html"
    common_terms_url = "https://docs.python.org/3/library/sys.html"
    _write_lesson(
        tmp_path,
        "\n".join(
            (
                f"[Generic reference]({generic_url})",
                f"[Specific reference]({specific_url})",
                f"[Common terminology reference]({common_terms_url})",
            )
        ),
    )
    monitor = _monitor(tmp_path, tmp_path)
    pages = {
        generic_url: "Python list algorithm documentation covers common behavior.",
        specific_url: "The bisect module algorithm supports binary insertion points.",
        common_terms_url: "Python list algorithm reference describes common behavior.",
    }

    async def handler(request: httpx.Request) -> httpx.Response:
        page_text = pages[str(request.url)]
        return httpx.Response(
            200,
            headers={"content-type": "text/html; charset=utf-8", "etag": '"v1"'},
            text=(
                "<html><head><title>Python reference</title></head><body>"
                f"<main><article><p>{page_text}</p></article></main></body></html>"
            ),
        )

    async def check() -> None:
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            await monitor.check_sources(client)

    asyncio.run(check())

    results = monitor.search_rag_sources("Python list bisect module algorithm")

    assert results[0]["path"] == specific_url


def test_python_assert_reference_is_an_exact_approved_rag_path() -> None:
    url = "https://docs.python.org/3/reference/simple_stmts.html#the-assert-statement"
    assert TrustedSourceMonitor._canonical_url(url) == "https://docs.python.org/3/reference/simple_stmts.html"
    policy = TrustedSourceMonitor._rag_policy("https://docs.python.org/3/reference/simple_stmts.html")
    assert policy is not None
    assert policy["license"] == "Python Software Foundation License Version 2"
    assert TrustedSourceMonitor._canonical_url("https://docs.python.org/3/reference/expressions.html") is None


def test_python_while_language_reference_is_an_exact_approved_rag_path() -> None:
    url = "https://docs.python.org/3/reference/compound_stmts.html#the-while-statement"
    canonical = "https://docs.python.org/3/reference/compound_stmts.html"

    assert TrustedSourceMonitor._canonical_url(url) == canonical
    policy = TrustedSourceMonitor._rag_policy(canonical)
    assert policy is not None
    assert policy["license"] == "Python Software Foundation License Version 2"
    assert TrustedSourceMonitor._canonical_url("https://docs.python.org/3/reference/expressions.html") is None


def test_pro_git_recording_changes_reference_is_metadata_only() -> None:
    url = "https://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository"

    assert TrustedSourceMonitor._canonical_url(url) == url
    assert TrustedSourceMonitor._rag_policy(url) is None
    assert TrustedSourceMonitor._canonical_url("https://git-scm.com/book/en/v2/Git-Basics-Undoing-Things") is None


def test_git_branching_and_github_pull_request_references_are_exact_metadata_only_paths(
    tmp_path: Path,
) -> None:
    urls = {
        "https://git-scm.com/book/en/v2/Git-Branching-Branches-in-a-Nutshell",
        "https://git-scm.com/docs/git-switch",
        "https://git-scm.com/docs/git-push",
        "https://docs.github.com/en/pull-requests/how-tos/create-pull-requests/creating-a-pull-request",
        "https://docs.github.com/en/pull-requests/concepts/writing-code-for-a-project",
    }

    for url in urls:
        assert TrustedSourceMonitor._canonical_url(url) == url
        assert TrustedSourceMonitor._rag_policy(url) is None

    assert TrustedSourceMonitor._canonical_url("https://docs.github.com/en/actions") is None
    assert TrustedSourceMonitor._canonical_url("https://docs.github.com/en/pull-requests/concepts/unknown") is None
    assert TrustedSourceMonitor._canonical_url("https://git-scm.com/docs/git-merge") is None

    _write_lesson(tmp_path, "\n".join(f"[Official reference]({url})" for url in sorted(urls)))
    references, unsupported_count, omitted_count = _monitor(tmp_path, tmp_path)._references()
    assert {reference.url for reference in references} == urls
    assert unsupported_count == 0
    assert omitted_count == 0


def test_git_branching_lesson_references_reach_the_trusted_source_inventory(
    tmp_path: Path,
) -> None:
    expected_urls = {
        "https://git-scm.com/book/en/v2/Git-Branching-Branches-in-a-Nutshell",
        "https://git-scm.com/docs/git-switch",
        "https://git-scm.com/docs/git-push",
        "https://docs.github.com/en/pull-requests/how-tos/create-pull-requests/creating-a-pull-request",
        "https://docs.github.com/en/pull-requests/concepts/writing-code-for-a-project",
    }
    existing_urls = {
        "https://docs.python.org/3/tutorial/errors.html",
        "https://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository",
    }
    monitor = TrustedSourceMonitor(
        Path(__file__).resolve().parents[1], tmp_path / "git-lesson-sources.sqlite"
    )

    references, _, _ = monitor._references()

    lesson_sources = {
        reference.url
        for reference in references
        if reference.lesson_path == "02_Areas/Programming/lessons/debugging_tests_and_git.md"
    }
    assert lesson_sources == expected_urls | existing_urls
    assert all(monitor._rag_policy(url) is None for url in expected_urls)


def test_python_bisect_library_page_is_monitored_and_licensed_for_rag(tmp_path: Path) -> None:
    url = "https://docs.python.org/3/library/bisect.html"
    _write_lesson(tmp_path, f"[Python bisect reference]({url})")
    monitor = _monitor(tmp_path, tmp_path)

    assert monitor._canonical_url(url) == url
    policy = monitor._rag_policy(url)
    assert policy is not None
    assert policy["license"] == "Python Software Foundation License Version 2"
    assert monitor.inventory()["sources"][0]["rag_content_state"] == "license_approved_pending_check"


def test_current_python_input_and_value_error_references_are_exact_and_licensed() -> None:
    for page, anchor in (("functions", "input"), ("exceptions", "ValueError")):
        url = f"https://docs.python.org/3/builtins/{page}.html"
        assert TrustedSourceMonitor._canonical_url(f"{url}#{anchor}") == url
        policy = TrustedSourceMonitor._rag_policy(url)
        assert policy is not None
        assert policy["license"] == "Python Software Foundation License Version 2"


def test_current_python_builtin_sources_use_direct_nonredirecting_urls(
    tmp_path: Path,
) -> None:
    current_urls = {
        "https://docs.python.org/3/builtins/exceptions.html",
        "https://docs.python.org/3/builtins/functions.html",
        "https://docs.python.org/3/builtins/stdtypes.html",
        "https://docs.python.org/3/library/sys.html",
    }
    redirected_urls = {
        "https://docs.python.org/3.14/library/exceptions.html#ValueError",
        "https://docs.python.org/3.14/library/functions.html#input",
        "https://docs.python.org/3/library/stdtypes.html#truth-value-testing",
    }
    lesson_lines = [f"[Current Python docs]({url})" for url in sorted(current_urls)]
    lesson_lines.extend(
        f"[Redirecting legacy URL]({url})" for url in sorted(redirected_urls)
    )
    _write_lesson(tmp_path, "\n".join(lesson_lines))
    monitor = _monitor(tmp_path, tmp_path)

    references, unsupported_count, omitted_count = monitor._references()

    assert {reference.url for reference in references} == current_urls
    assert unsupported_count == len(redirected_urls)
    assert omitted_count == 0
    for url in current_urls:
        assert TrustedSourceMonitor._canonical_url(url) == url
        policy = monitor._rag_policy(url)
        assert policy is not None
        assert policy["license"] == "Python Software Foundation License Version 2"


def test_audited_official_references_are_monitored_without_broadening_hosts_or_rag(
    tmp_path: Path,
) -> None:
    metadata_only_urls = {
        "https://dictionary.cambridge.org/grammar/british-grammar/reporting-clauses",
        "https://www.ncbi.nlm.nih.gov/books/NBK26825/",
        "https://medlineplus.gov/about/using/usingcontent/",
        "https://openstax.org/terms-of-use",
        "https://www.nist.gov/copyrights-disclaimers",
    }
    genome_urls = {
        "https://www.genome.gov/genetics-glossary/Gene",
        "https://www.genome.gov/genetics-glossary/Phenotype",
        "https://www.genome.gov/genetics-glossary/genotype",
    }
    _write_lesson(
        tmp_path,
        "\n".join(
            f"[Official source]({url})" for url in sorted(metadata_only_urls | genome_urls)
        ),
    )
    monitor = _monitor(tmp_path, tmp_path)

    references, unsupported_count, omitted_count = monitor._references()

    assert {reference.url for reference in references} == metadata_only_urls | genome_urls
    assert unsupported_count == 0
    assert omitted_count == 0
    assert all(monitor._rag_policy(url) is None for url in metadata_only_urls)
    assert all(monitor._rag_policy(url) is not None for url in genome_urls)
    assert TrustedSourceMonitor._canonical_url(
        "https://www.genome.gov/genetics-glossary/Unreviewed-Term"
    ) is None
    assert TrustedSourceMonitor._canonical_url("https://example.org/lesson") is None


def test_sqlite_schema_query_planner_and_transaction_docs_are_exact_and_public_domain() -> None:
    urls = (
        "https://www.sqlite.org/lang_createtable.html",
        "https://www.sqlite.org/lang_select.html",
        "https://www.sqlite.org/queryplanner.html",
        "https://www.sqlite.org/lang_transaction.html",
    )

    for url in urls:
        assert TrustedSourceMonitor._canonical_url(url) == url
        policy = TrustedSourceMonitor._rag_policy(url)
        assert policy is not None
        assert policy["license"] == "SQLite documentation dedicated to the public domain"
        assert policy["license_url"] == "https://sqlite.org/copyright.html"

    assert TrustedSourceMonitor._canonical_url("https://www.sqlite.org/lang_update.html") is None
    copyright_url = "https://sqlite.org/copyright.html"
    assert TrustedSourceMonitor._canonical_url(copyright_url) == copyright_url
    assert TrustedSourceMonitor._rag_policy(copyright_url) is None


def test_approved_sqlite_query_planner_page_is_cached_for_rag(tmp_path: Path) -> None:
    url = "https://www.sqlite.org/queryplanner.html"
    _write_lesson(tmp_path, f"[SQLite query planner]({url})")
    monitor = _monitor(tmp_path, tmp_path)
    page_text = "SQLite indexes can help locate matching rows. The query planner chooses a search strategy."

    async def handler(_request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            200,
            headers={"content-type": "text/html; charset=utf-8", "etag": '"v1"'},
            text=(
                "<html><head><title>Query Planning</title></head><body>"
                f"<main><article><p>{page_text}</p></article></main></body></html>"
            ),
        )

    async def check() -> dict[str, object]:
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            return await monitor.check_sources(client)

    result = asyncio.run(check())
    found = monitor.search_rag_sources("SQLite indexes matching rows query planner strategy")

    assert result["checks"][0]["state"] == "available_untracked"
    assert len(found) == 1
    assert found[0]["license"] == "SQLite documentation dedicated to the public domain"
    assert found[0]["license_url"] == "https://sqlite.org/copyright.html"
    assert "query planner chooses a search strategy" in found[0]["excerpt"].casefold()


def test_public_domain_medlineplus_genetics_basics_are_cached_for_rag(tmp_path: Path) -> None:
    url = "https://medlineplus.gov/genetics/understanding/basics/gene/"
    _write_lesson(tmp_path, f"[What is a gene?]({url})")
    monitor = _monitor(tmp_path, tmp_path)
    page_text = (
        "Genes are made of DNA and can provide instructions for proteins. "
        "Some genes help regulate other genes. A gene variant may or may not change a trait."
    )

    async def handler(_request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            200,
            headers={"content-type": "text/html; charset=utf-8", "etag": '"v1"'},
            text=(
                "<html><head><title>What is a gene?</title></head><body>"
                f"<main><article><p>{page_text}</p></article></main></body></html>"
            ),
        )

    async def check() -> dict[str, object]:
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            return await monitor.check_sources(client)

    result = asyncio.run(check())
    found = monitor.search_rag_sources("genes DNA proteins regulate variant trait")

    assert result["checks"][0]["state"] == "available_untracked"
    assert len(found) == 1
    assert found[0]["source_type"] == "official_web"
    assert found[0]["license"] == (
        "U.S. federal government work; public-domain MedlinePlus Genetics summary"
    )
    assert found[0]["license_url"] == "https://medlineplus.gov/about/using/usingcontent/"
    assert "Source: MedlinePlus" in found[0]["attribution"]
    assert "genes are made of dna" in found[0]["excerpt"].casefold()


def test_exact_elife_xml_article_is_cached_with_cc_by_attribution(tmp_path: Path) -> None:
    url = (
        "https://raw.githubusercontent.com/elifesciences/elife-article-xml/master/"
        "articles/elife-81613-v1.xml"
    )
    _write_lesson(tmp_path, f"[eLife bilaterian evolution article]({url})")
    monitor = _monitor(tmp_path, tmp_path)
    xml = """<?xml version="1.0" encoding="UTF-8"?>
    <article><front><article-meta><title-group><article-title>Peripheral and central employment of acid-sensing ion channels during early bilaterian evolution</article-title></title-group></article-meta></front>
    <body><sec><title>Results</title><p>Protostomes include Spiralia and Ecdysozoa. Ecdysozoa includes nematodes and arthropods.</p></sec></body></article>"""

    async def handler(_request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            200,
            headers={"content-type": "text/plain; charset=utf-8", "etag": '"v1"'},
            text=xml,
        )

    async def check() -> dict[str, object]:
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            return await monitor.check_sources(client)

    result = asyncio.run(check())
    found = monitor.search_rag_sources("protostomes Spiralia Ecdysozoa nematodes arthropods")

    assert result["checks"][0]["state"] == "available_untracked"
    assert len(found) == 1
    assert found[0]["license"] == "Creative Commons Attribution 4.0 International (CC BY 4.0), eLife article"
    assert found[0]["license_url"] == "https://elifesciences.org/terms"
    assert "DOI 10.7554/eLife.81613" in found[0]["attribution"]
    assert "protostomes include spiralia and ecdysozoa" in found[0]["excerpt"].casefold()

    async def preview() -> dict[str, object]:
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            return await monitor.preview_source(url, client)

    preview_result = asyncio.run(preview())
    assert preview_result["page_title"] == (
        "Peripheral and central employment of acid-sensing ion channels during early bilaterian evolution"
    )
    assert "protostomes include spiralia" in str(preview_result["excerpt"]).casefold()


def test_elife_rag_allowlist_is_restricted_to_one_article_xml() -> None:
    approved = (
        "https://raw.githubusercontent.com/elifesciences/elife-article-xml/master/"
        "articles/elife-81613-v1.xml"
    )

    assert TrustedSourceMonitor._rag_policy(approved) is not None
    assert TrustedSourceMonitor._rag_policy(
        approved.replace("elife-81613-v1.xml", "elife-99999-v1.xml")
    ) is None
    assert TrustedSourceMonitor._rag_policy(
        approved.replace("raw.githubusercontent.com", "github.com")
    ) is None


def test_medlineplus_genetics_ingestion_is_restricted_to_public_domain_basics() -> None:
    assert TrustedSourceMonitor._rag_policy(
        "https://medlineplus.gov/genetics/understanding/basics/dna/"
    ) is not None
    assert TrustedSourceMonitor._rag_policy(
        "https://medlineplus.gov/genetics/understanding/basics/gene/"
    ) is not None
    assert TrustedSourceMonitor._rag_policy(
        "https://medlineplus.gov/genetics/condition/cystic-fibrosis/"
    ) is None
    assert TrustedSourceMonitor._canonical_url(
        "https://medlineplus.gov/genetics/understanding/basics/dna/?download=1"
    ) is None


def test_nhgri_glossary_rag_policy_is_exact_and_public_domain() -> None:
    approved = {
        "https://www.genome.gov/genetics-glossary/Gene-Expression",
        "https://www.genome.gov/genetics-glossary/Gene-Regulation",
        "https://www.genome.gov/genetics-glossary/Promoter",
        "https://www.genome.gov/genetics-glossary/Chromatid",
    }

    assert all(TrustedSourceMonitor._rag_policy(url) is not None for url in approved)
    assert TrustedSourceMonitor._rag_policy(
        "https://www.genome.gov/genetics-glossary/Other-Term"
    ) is None
    assert TrustedSourceMonitor._rag_policy(
        "https://www.genome.gov/genetics-glossary/Gene-Regulation?download=1"
    ) is None
    policy = TrustedSourceMonitor._rag_policy(
        "https://www.genome.gov/genetics-glossary/Gene-Regulation"
    )
    assert policy is not None
    assert "public domain" in policy["license"].casefold()
    assert policy["license_url"] == (
        "https://www.genome.gov/about-nhgri/Policies-Guidance/Copyright"
    )
    assert "NHGRI" in policy["attribution"]


def test_nhgri_gene_regulation_glossary_is_cached_for_rag_with_attribution(
    tmp_path: Path,
) -> None:
    url = "https://www.genome.gov/genetics-glossary/Gene-Regulation"
    _write_lesson(tmp_path, f"[NHGRI gene regulation glossary]({url})")
    monitor = _monitor(tmp_path, tmp_path)
    initial_item = monitor.inventory()["sources"][0]
    assert initial_item["rag_content_state"] == "license_approved_pending_check"
    assert "public domain" in str(initial_item["rag_license"]).casefold()
    page_text = (
        "Gene regulation controls when and where genes are expressed. "
        "Regulatory proteins and chemical DNA modifications help cells respond to change."
    )

    async def handler(_request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            200,
            headers={"content-type": "text/html; charset=utf-8", "etag": '"nhgri-v1"'},
            text=(
                "<html><head><title>Gene Regulation | NHGRI</title>"
                '<meta property="article:published_time" content="2025-09-12T08:15:00Z">'
                '<meta property="article:modified_time" content="2026-10-12T15:30:00+03:00">'
                "</head><body>"
                f"<main><article><h1>Gene Regulation</h1><p>{page_text}</p></article></main>"
                "</body></html>"
            ),
        )

    async def check() -> dict[str, object]:
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            return await monitor.check_sources(client)

    result = asyncio.run(check())
    found = monitor.search_rag_sources("gene regulation proteins DNA express response")

    assert result["checks"][0]["state"] == "available_untracked"
    assert len(found) == 1
    assert found[0]["source_type"] == "official_web"
    assert found[0]["path"] == url
    assert found[0]["license_url"] == (
        "https://www.genome.gov/about-nhgri/Policies-Guidance/Copyright"
    )
    assert "public domain" in found[0]["license"].casefold()
    assert "Courtesy: National Human Genome Research Institute" in found[0]["attribution"]
    assert found[0]["source_checked_at"] == result["checks"][0]["checked_at"]
    assert found[0]["page_published_at"] == "2025-09-12T08:15:00Z"
    assert found[0]["page_updated_at"] == "2026-10-12T15:30:00+03:00"
    assert found[0]["source_snapshot_fetched_at"] == result["checks"][0]["checked_at"]
    assert "gene regulation controls when and where" in found[0]["excerpt"].casefold()
    refreshed_item = monitor.inventory()["sources"][0]
    assert refreshed_item["rag_content_state"] == "cached"
    assert refreshed_item["rag_content_fetched_at"] == result["checks"][0]["checked_at"]


def test_rag_source_check_time_tracks_revalidation_separately_from_snapshot_fetch(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch,
) -> None:
    url = "https://docs.python.org/3/tutorial/controlflow.html"
    _write_lesson(tmp_path, f"[Python control flow]({url})")
    monitor = _monitor(tmp_path, tmp_path)
    current_time = [datetime(2026, 10, 12, 10, 0, tzinfo=timezone.utc)]
    real_datetime = datetime

    class FrozenDateTime(real_datetime):
        @classmethod
        def now(cls, tz=None):
            if tz is None:
                return current_time[0].replace(tzinfo=None)
            return current_time[0].astimezone(tz)

    monkeypatch.setattr(trusted_sources, "datetime", FrozenDateTime)

    async def handler(request: httpx.Request) -> httpx.Response:
        if request.headers.get("if-none-match") == '"v1"':
            return httpx.Response(304, headers={"etag": '"v1"'}, request=request)
        return httpx.Response(
            200,
            headers={"content-type": "text/html; charset=utf-8", "etag": '"v1"'},
            text=(
                "<html><body><main><article>Python control flow and loops.</article>"
                "</main></body></html>"
            ),
            request=request,
        )

    async def check() -> dict[str, object]:
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            return await monitor.check_sources(client)

    first = asyncio.run(check())
    current_time[0] = datetime(2026, 10, 16, 10, 0, tzinfo=timezone.utc)
    second = asyncio.run(check())
    found = monitor.search_rag_sources("Python control flow loops")

    assert first["checks"][0]["state"] == "available_untracked"
    assert second["checks"][0]["state"] == "unchanged"
    assert len(found) == 1
    assert found[0]["source_checked_at"] == second["checks"][0]["checked_at"]
    assert found[0]["source_snapshot_fetched_at"] == first["checks"][0]["checked_at"]


def test_openstax_sources_remain_metadata_only_until_book_specific_ai_rights_are_reviewed(
    tmp_path: Path,
) -> None:
    url = "https://openstax.org/books/college-physics-2e/pages/7-1-work-the-scientific-definition"
    _write_lesson(tmp_path, f"[OpenStax work page]({url})")
    monitor = _monitor(tmp_path, tmp_path)

    assert monitor._rag_policy(url) is None
    assert monitor.inventory()["sources"][0]["rag_content_state"] == "metadata_only_rights_review"
    assert monitor.inventory()["sources"][0]["rag_restriction_url"] == (
        "https://help.openstax.org/s/article/Licensing-information-of-OpenStax-textbooks"
    )


def test_nist_algorithm_glossary_is_monitored_but_not_cached_for_rag(tmp_path: Path) -> None:
    url = "https://csrc.nist.gov/glossary/term/algorithm"
    _write_lesson(tmp_path, f"[NIST algorithm definition]({url})")
    monitor = _monitor(tmp_path, tmp_path)

    assert monitor._canonical_url(url) == url
    assert monitor._rag_policy(url) is None
    assert monitor.inventory()["sources"][0]["rag_content_state"] == "metadata_only"


def test_british_council_daily_routine_is_monitored_metadata_only(tmp_path: Path) -> None:
    url = (
        "https://learnenglish.britishcouncil.org/free-resources/vocabulary/a1-a2/"
        "daily-routine-vocabulary-a1-beginner-english-vocabulary-lesson"
    )
    overview_url = "https://learnenglish.britishcouncil.org/free-resources/vocabulary/a1-a2"
    _write_lesson(tmp_path, f"[Daily routine vocabulary]({url})\n[A1-A2 vocabulary]({overview_url})")
    monitor = _monitor(tmp_path, tmp_path)

    assert monitor._canonical_url(url) == url
    assert monitor._canonical_url(overview_url) == overview_url
    assert monitor._rag_policy(url) is None
    assert all(item["rag_content_state"] == "metadata_only" for item in monitor.inventory()["sources"])


def test_english_foundations_sources_are_exactly_monitored_without_rag_reuse(tmp_path: Path) -> None:
    urls = [
        "https://learnenglish.britishcouncil.org/free-resources/grammar/a1-a2/present-simple-be",
        "https://learnenglish.britishcouncil.org/free-resources/grammar/english-grammar-reference/personal-pronouns",
    ]
    _write_lesson(tmp_path, "\n".join(f"[Official English grammar]({url})" for url in urls))
    monitor = _monitor(tmp_path, tmp_path)

    references, unsupported_count, omitted_count = monitor._references()

    assert {reference.url for reference in references} == set(urls)
    assert unsupported_count == 0
    assert omitted_count == 0
    assert all(monitor._rag_policy(url) is None for url in urls)
    assert all(item["rag_content_state"] == "metadata_only" for item in monitor.inventory()["sources"])


def test_british_council_reading_pages_are_monitored_metadata_only(tmp_path: Path) -> None:
    urls = [
        "https://learnenglish.britishcouncil.org/free-resources/reading/a1",
        "https://learnenglish.britishcouncil.org/level/improve-your-english-level/how-start-reading-english",
    ]
    _write_lesson(tmp_path, "\n".join(f"[Reading source]({url})" for url in urls))
    monitor = _monitor(tmp_path, tmp_path)

    assert {item["url"] for item in monitor.inventory()["sources"]} == set(urls)
    assert all(item["rag_content_state"] == "metadata_only" for item in monitor.inventory()["sources"])


def test_english_pronunciation_sources_are_monitored_metadata_only(tmp_path: Path) -> None:
    urls = [
        "https://learnenglish.britishcouncil.org/english-levels/improve-your-english-level/easy-way-work-out-how-pronounce-new-words",
        "https://dictionary.cambridge.org/dictionary/english/stress",
        "https://dictionary.cambridge.org/pronunciation/english/present",
        "https://dictionary.cambridge.org/pronunciation/english/record",
        "https://dictionary.cambridge.org/help/phonetics.html",
    ]
    _write_lesson(tmp_path, "\n".join(f"[Official pronunciation reference]({url})" for url in urls))
    monitor = _monitor(tmp_path, tmp_path)

    references, unsupported_count, omitted_count = monitor._references()

    assert {reference.url for reference in references} == set(urls)
    assert unsupported_count == 0
    assert omitted_count == 0
    assert all(monitor._rag_policy(url) is None for url in urls)
    assert all(item["rag_content_state"] == "metadata_only" for item in monitor.inventory()["sources"])


def test_nist_si_appendix_b9_is_cached_with_public_information_attribution(tmp_path: Path) -> None:
    url = (
        "https://www.nist.gov/pml/special-publication-811/"
        "nist-guide-si-appendix-b-conversion-factors/nist-guide-si-appendix-b9"
    )
    _write_lesson(tmp_path, f"[NIST standard gravity]({url})")
    monitor = _monitor(tmp_path, tmp_path)
    page_text = (
        "Acceleration of free fall, standard (g_n) is 9.80665 meter per second squared. "
        "This is an exact conventional value for standard gravity."
    )

    async def handler(_request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            200,
            headers={"content-type": "text/html; charset=utf-8", "etag": '"nist-v1"'},
            text=(
                "<html><head><title>NIST Guide to the SI, Appendix B.9</title></head><body>"
                f"<main><article><p>{page_text}</p></article></main></body></html>"
            ),
        )

    async def check() -> dict[str, object]:
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            return await monitor.check_sources(client)

    result = asyncio.run(check())
    found = monitor.search_rag_sources("standard acceleration gravity 9.80665")

    assert result["checks"][0]["state"] == "available_untracked"
    assert len(found) == 1
    assert found[0]["source_type"] == "official_web"
    assert found[0]["license"] == (
        "NIST public information; may be distributed or copied unless marked copyrighted"
    )
    assert found[0]["license_url"] == "https://www.nist.gov/copyrights-disclaimers"
    assert "NIST" in found[0]["attribution"]
    assert "9.80665" in found[0]["excerpt"]


def test_nist_rag_policy_only_allows_si_appendix_b9() -> None:
    assert TrustedSourceMonitor._rag_policy(
        "https://www.nist.gov/pml/special-publication-811/"
        "nist-guide-si-appendix-b-conversion-factors/nist-guide-si-appendix-b9"
    ) is not None
    assert TrustedSourceMonitor._rag_policy(
        "https://www.nist.gov/how-do-you-measure-it/how-do-you-measure-strength-gravity"
    ) is None


def test_nist_metric_prefixes_are_cached_with_public_information_attribution(tmp_path: Path) -> None:
    url = "https://www.nist.gov/pml/owm/metric-si-prefixes"
    _write_lesson(tmp_path, f"[NIST metric prefixes]({url})")
    monitor = _monitor(tmp_path, tmp_path)
    page_text = (
        "NIST Metric SI Prefixes. Kilo has the factor 10^3, or one thousand. "
        "Quetta has the factor 10^30. NIST updated this page on August 13, 2025."
    )

    async def handler(_request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            200,
            headers={"content-type": "text/html; charset=utf-8", "etag": '"nist-prefixes-v1"'},
            text=(
                "<html><head><title>Metric (SI) Prefixes | NIST</title></head><body>"
                f"<main><article><p>{page_text}</p></article></main></body></html>"
            ),
        )

    async def check() -> dict[str, object]:
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            return await monitor.check_sources(client)

    result = asyncio.run(check())
    found = monitor.search_rag_sources("NIST metric SI prefixes kilo thousand quetta")

    assert result["checks"][0]["state"] == "available_untracked"
    assert len(found) == 1
    assert found[0]["path"] == url
    assert found[0]["license"] == (
        "NIST public information; may be distributed or copied unless marked copyrighted"
    )
    assert found[0]["license_url"] == "https://www.nist.gov/copyrights-disclaimers"
    assert "NIST" in found[0]["attribution"]
    assert "10^30" in found[0]["excerpt"]


def test_nist_rag_policy_accepts_only_reviewed_si_pages() -> None:
    assert TrustedSourceMonitor._rag_policy(
        "https://www.nist.gov/pml/owm/metric-si-prefixes"
    ) is not None
    assert TrustedSourceMonitor._rag_policy(
        "https://www.nist.gov/pml/owm/metric-si/si-units"
    ) is None


def test_bundled_lesson_sources_fit_the_bounded_monitor_inventory(tmp_path: Path) -> None:
    project_root = Path(__file__).resolve().parent.parent
    monitor = TrustedSourceMonitor(project_root, tmp_path / "course-sources.sqlite3")

    references, _unsupported_count, omitted_count = monitor._references()

    assert references
    assert omitted_count == 0
    assert any(
        reference.url == "https://openstax.org/books/prealgebra-2e/pages/9-4-use-properties-of-rectangles-triangles-and-trapezoids"
        for reference in references
    )
    git_team_sources = {
        "https://git-scm.com/book/en/v2/Git-Branching-Branches-in-a-Nutshell",
        "https://git-scm.com/docs/git-switch",
        "https://git-scm.com/docs/git-push",
        "https://docs.github.com/en/pull-requests/how-tos/create-pull-requests/creating-a-pull-request",
        "https://docs.github.com/en/pull-requests/concepts/writing-code-for-a-project",
    }
    assert git_team_sources <= {reference.url for reference in references}


def test_inventory_exposes_bounded_publisher_declared_dates_separately_from_http_check(
    tmp_path: Path,
) -> None:
    url = "https://openstax.org/books/college-physics-2e/pages/7-1-work-the-scientific-definition"
    _write_lesson(tmp_path, f"[OpenStax work page]({url})")
    monitor = _monitor(tmp_path, tmp_path)

    async def handler(request: httpx.Request) -> httpx.Response:
        if request.headers.get("if-none-match") == '"source-v1"':
            return httpx.Response(
                304,
                headers={"etag": '"source-v1"'},
                request=request,
            )
        return httpx.Response(
            200,
            headers={
                "content-type": "text/html; charset=utf-8",
                "etag": '"source-v1"',
                "last-modified": "Mon, 12 Oct 2026 12:00:00 GMT",
            },
            text=(
                "<html><head><title>Work</title>"
                '<meta property="article:published_time" content="yesterday">'
                '<meta property="article:published_time" content="2025-09-12T08:15:00Z">'
                '<meta property="article:modified_time" content="2026-99-50">'
                '<meta property="article:modified_time" content="2026-10-12T15:30:00+03:00">'
                "<script>"
                '<meta property="article:modified_time" content="2026-10-13">'
                "</script></head><body><main><p>Work changes energy.</p></main></body></html>"
            ),
        )

    async def check() -> tuple[dict[str, object], dict[str, object], dict[str, object]]:
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            first = await monitor.check_sources(client)
            second = await monitor.check_sources(client)
            preview = await monitor.preview_source(url, client)
            return first, second, preview

    first, second, preview = asyncio.run(check())
    source = monitor.inventory()["sources"][0]

    assert first["checks"][0]["state"] == "available_untracked"
    assert second["checks"][0]["state"] == "unchanged"
    assert source["page_published_at"] == "2025-09-12T08:15:00Z"
    assert source["page_updated_at"] == "2026-10-12T15:30:00+03:00"
    assert source["last_modified"] == "Mon, 12 Oct 2026 12:00:00 GMT"
    assert source["last_checked_at"] == second["checks"][0]["checked_at"]
    assert preview["page_published_at"] == "2025-09-12T08:15:00Z"
    assert preview["page_updated_at"] == "2026-10-12T15:30:00+03:00"


@pytest.mark.parametrize(
    "url",
    [
        "http://openstax.org/books/biology-2e/pages/12-3-laws-of-inheritance",
        "https://openstax.org.attacker.test/books/biology-2e/pages/12-3-laws-of-inheritance",
        "https://openstax.org:8443/books/biology-2e/pages/12-3-laws-of-inheritance",
        "https://user:password@openstax.org/books/biology-2e/pages/12-3-laws-of-inheritance",
        "https://openstax.org/books/biology-2e/pages/12-3-laws-of-inheritance?download=1",
        "https://openstax.org/unapproved/path",
        "https://docs.python.org/3/library/os.html",
        "https://csrc.nist.gov/glossary/term/algorithm?download=1",
        "https://csrc.nist.gov/glossary/term/cryptographic_algorithm",
        "https://learnenglish.britishcouncil.org/free-resources/vocabulary/a1-a2/actions",
    ],
)
def test_reference_policy_rejects_noncanonical_or_unapproved_urls(url: str) -> None:
    assert TrustedSourceMonitor._canonical_url(url) is None


def test_reference_policy_accepts_official_british_council_b1_b2_lesson() -> None:
    url = "https://learnenglish.britishcouncil.org/free-resources/grammar/b1-b2/present-perfect-simple-continuous"

    assert TrustedSourceMonitor._canonical_url(url) == url


def test_reference_scan_reports_links_omitted_by_the_request_cap(tmp_path: Path) -> None:
    urls = [
        f"https://openstax.org/books/biology-2e/pages/chapter-{index}"
        for index in range(_MAX_SOURCES + 5)
    ]
    _write_lesson(tmp_path, "\n".join(f"[Source]({url})" for url in urls))

    references, unsupported_count, omitted_count = _monitor(tmp_path, tmp_path)._references()

    assert len(references) == _MAX_SOURCES
    assert omitted_count == 5
    assert unsupported_count == 0


def test_reference_scan_rotates_past_the_batch_cap_instead_of_starving_tail(
    tmp_path: Path,
) -> None:
    urls = {
        f"https://openstax.org/books/biology-2e/pages/chapter-{index}"
        for index in range(_MAX_SOURCES + 5)
    }
    _write_lesson(tmp_path, "\n".join(f"[Source]({url})" for url in sorted(urls)))
    monitor = _monitor(tmp_path, tmp_path)

    first_batch, _unsupported_count, first_omitted_count = monitor._references()
    first_urls = {reference.url for reference in first_batch}
    first_check_time = "2026-10-06T00:00:00Z"
    for reference in first_batch:
        monitor._save_check(
            reference,
            etag=None,
            last_modified=None,
            checked_at=first_check_time,
            http_status=200,
            state="unchanged",
        )

    second_batch, _unsupported_count, second_omitted_count = monitor._references()
    expected_tail = urls - first_urls
    assert first_omitted_count == second_omitted_count == 5
    assert {reference.url for reference in second_batch[:5]} == expected_tail
    assert monitor.seconds_until_automatic_check(
        now=datetime.fromisoformat("2026-10-06T00:02:00+00:00")
    ) == 0

    second_check_time = "2026-10-06T00:01:00Z"
    for reference in second_batch:
        monitor._save_check(
            reference,
            etag=None,
            last_modified=None,
            checked_at=second_check_time,
            http_status=200,
            state="unchanged",
        )

    third_batch, _unsupported_count, _omitted_count = monitor._references()
    remaining_from_first = first_urls - {reference.url for reference in second_batch}
    assert len(remaining_from_first) == 5
    assert {reference.url for reference in third_batch[:5]} == remaining_from_first


def test_inventory_exposes_only_approved_reference_metadata_and_saved_state(tmp_path: Path) -> None:
    url = "https://openstax.org/books/biology-2e/pages/12-3-laws-of-inheritance"
    _write_lesson(
        tmp_path,
        "---\nsubject: Physics\nsource_checked: 2026-10-02\n---\n"
        f"[OpenStax inheritance]({url})\n[Other](https://example.test/page)\n",
    )
    monitor = _monitor(tmp_path, tmp_path)

    unchecked = monitor.inventory(today=date(2026, 10, 5))

    assert unchecked["listed_count"] == 1
    assert unchecked["unsupported_count"] == 1
    assert unchecked["unchecked_count"] == 1
    assert unchecked["needs_attention_count"] == 0
    assert unchecked["editorial_review_unscheduled_count"] == 1
    assert unchecked["sources"] == [{
        "url": url,
        "title": "OpenStax inheritance",
        "lesson_path": "02_Areas/Physics/lessons/source_test.md",
        "lesson_paths": ["02_Areas/Physics/lessons/source_test.md"],
        "lesson_reviews": [{
            "lesson_path": "02_Areas/Physics/lessons/source_test.md",
            "lesson_reviewed_on": "2026-10-02",
            "editorial_review_interval_days": None,
            "editorial_review_due_on": None,
            "editorial_review_status": "review_unscheduled",
        }],
        "lesson_reviewed_on": "2026-10-02",
        "editorial_review_interval_days": None,
        "editorial_review_due_on": None,
        "editorial_review_status": "review_unscheduled",
        "state": "not_checked",
        "last_checked_at": None,
        "last_http_status": None,
        "last_modified": None,
        "has_etag": False,
        "page_title": None,
        "page_description": None,
        "page_published_at": None,
        "page_updated_at": None,
        "content_checked_at": None,
        "rag_content_state": "metadata_only_rights_review",
        "rag_content_fetched_at": None,
        "rag_license": None,
        "rag_license_url": None,
        "rag_restriction_url": "https://help.openstax.org/s/article/Licensing-information-of-OpenStax-textbooks",
    }]

    monitor._save_check(
        monitor._references()[0][0],
        etag='"version-1"',
        last_modified="Mon, 05 Oct 2026 00:00:00 GMT",
        checked_at="2026-10-05T01:00:00Z",
        http_status=200,
        state="changed",
    )
    checked = monitor.inventory(today=date(2026, 10, 5))

    assert checked["changed_count"] == 1
    assert checked["needs_attention_count"] == 1
    item = checked["sources"][0]
    assert item["state"] == "changed"
    assert item["last_http_status"] == 200
    assert item["last_modified"] == "Mon, 05 Oct 2026 00:00:00 GMT"
    assert item["has_etag"] is True
    assert "etag" not in item


def test_inventory_separates_due_scheduled_and_missing_editorial_reviews(tmp_path: Path) -> None:
    root = tmp_path / "project"
    lessons = root / "02_Areas"
    records = [
        (
            "Physics/due.md",
            "source_checked: 2026-10-02\nsource_review_interval_days: 3",
            "https://openstax.org/books/college-physics-2e/pages/7-1-work-the-scientific-definition",
        ),
        (
            "English/scheduled.md",
            "source_checked: 2026-10-04\nsource_review_interval_days: 10",
            "https://openstax.org/books/college-physics-2e/pages/7-2-work-and-energy",
        ),
        (
            "Biology/missing.md",
            "source_review_interval_days: 30",
            "https://openstax.org/books/biology-2e/pages/5-3-active-transport",
        ),
        (
            "Mathematics/unscheduled.md",
            "source_checked: 2026-10-01",
            "https://openstax.org/books/algebra-and-trigonometry-2e/pages/3-1-functions-and-function-notation",
        ),
    ]
    for relative_path, metadata, url in records:
        lesson = lessons / relative_path.split("/")[0] / "lessons" / relative_path.split("/")[1]
        lesson.parent.mkdir(parents=True, exist_ok=True)
        lesson.write_text(f"---\n{metadata}\n---\n[Official source]({url})\n", encoding="utf-8")

    inventory = _monitor(root, tmp_path / "state").inventory(today=date(2026, 10, 5))

    assert inventory["editorial_review_due_count"] == 1
    assert inventory["editorial_review_scheduled_count"] == 1
    assert inventory["editorial_review_missing_count"] == 1
    assert inventory["editorial_review_unscheduled_count"] == 1
    by_url = {item["url"]: item for item in inventory["sources"]}
    assert by_url[records[0][2]]["editorial_review_due_on"] == "2026-10-05"
    assert by_url[records[0][2]]["editorial_review_status"] == "review_due"
    assert by_url[records[1][2]]["editorial_review_due_on"] == "2026-10-14"
    assert by_url[records[1][2]]["editorial_review_status"] == "review_scheduled"
    assert by_url[records[2][2]]["editorial_review_status"] == "review_missing"
    assert by_url[records[3][2]]["editorial_review_status"] == "review_unscheduled"


def test_source_preview_is_bounded_plain_text_and_does_not_persist_page_content(
    tmp_path: Path,
) -> None:
    url = "https://openstax.org/books/college-physics-2e/pages/7-1-work-the-scientific-definition"
    _write_lesson(tmp_path, f"[OpenStax work page]({url})")
    monitor = _monitor(tmp_path, tmp_path)
    requested_urls: list[str] = []
    article = "Work is the transfer of energy." + (" useful physics text" * 700)
    html = (
        "<html><head><title>Work | OpenStax</title>"
        "<meta name='description' content='A lesson about work.'></head>"
        "<body><nav>navigation noise</nav><main><article><h1>Work</h1>"
        f"<p>{article}</p><script>do not show this</script></article></main>"
        "<footer>footer noise</footer></body></html>"
    )

    async def handler(request: httpx.Request) -> httpx.Response:
        requested_urls.append(str(request.url))
        return httpx.Response(200, headers={"content-type": "text/html; charset=utf-8"}, text=html)

    async def run() -> dict[str, object]:
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            return await monitor.preview_source(url, client)

    preview = asyncio.run(run())

    assert requested_urls == [url]
    assert preview["url"] == url
    assert preview["page_title"] == "Work | OpenStax"
    assert preview["page_description"] == "A lesson about work."
    assert preview["excerpt"].startswith("Work Work is the transfer of energy.")
    assert len(str(preview["excerpt"])) == 4_000
    assert preview["excerpt_truncated"] is True
    assert "navigation noise" not in str(preview["excerpt"])
    assert "footer noise" not in str(preview["excerpt"])
    assert "do not show this" not in str(preview["excerpt"])
    assert monitor.inventory()["sources"][0]["state"] == "not_checked"


def test_source_preview_rejects_urls_not_in_a_lesson_before_network_access(tmp_path: Path) -> None:
    monitor = _monitor(tmp_path, tmp_path)
    requests = 0

    async def handler(_request: httpx.Request) -> httpx.Response:
        nonlocal requests
        requests += 1
        return httpx.Response(200, text="must not be requested")

    async def run() -> None:
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            await monitor.preview_source("https://example.test/page", client)

    with pytest.raises(ValueError, match="approved lesson inventory"):
        asyncio.run(run())
    assert requests == 0


def test_source_preview_does_not_follow_redirects(tmp_path: Path) -> None:
    url = "https://openstax.org/books/college-physics-2e/pages/7-1-work-the-scientific-definition"
    _write_lesson(tmp_path, f"[OpenStax work page]({url})")
    monitor = _monitor(tmp_path, tmp_path)
    requested_hosts: list[str] = []

    async def handler(request: httpx.Request) -> httpx.Response:
        requested_hosts.append(request.url.host)
        return httpx.Response(302, headers={"location": "https://example.test/redirect"})

    async def run() -> None:
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            await monitor.preview_source(url, client)

    with pytest.raises(RuntimeError, match="HTTP 200"):
        asyncio.run(run())
    assert requested_hosts == ["openstax.org"]


def test_manual_editorial_review_rechecks_page_and_saves_digest_not_excerpt(tmp_path: Path) -> None:
    url = "https://openstax.org/books/college-physics-2e/pages/7-1-work-the-scientific-definition"
    _write_lesson(
        tmp_path,
        "---\nsource_checked: 2020-01-01\nsource_review_interval_days: 365\n---\n"
        f"[OpenStax work page]({url})",
    )
    monitor = _monitor(tmp_path, tmp_path)
    page = "<html><head><title>Work</title></head><body><main><article>Energy transfer.</article></main></body></html>"
    requested = 0

    async def handler(_request: httpx.Request) -> httpx.Response:
        nonlocal requested
        requested += 1
        return httpx.Response(
            200,
            headers={
                "content-type": "text/html; charset=utf-8",
                "etag": '"version-a"',
                "last-modified": "Tue, 06 Oct 2026 00:00:00 GMT",
            },
            text=page,
        )

    async def run() -> tuple[dict[str, object], dict[str, object]]:
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            preview = await monitor.preview_source(url, client)
            review = await monitor.review_source(
                url,
                "02_Areas/Physics/lessons/source_test.md",
                str(preview["content_digest"]),
                client,
            )
            return preview, review

    preview, result = asyncio.run(run())
    inventory = monitor.inventory()
    item = inventory["sources"][0]
    lesson_review = item["lesson_reviews"][0]

    assert requested == 2
    assert result["status"] == "ok"
    assert result["lesson_path"] == "02_Areas/Physics/lessons/source_test.md"
    assert result["reviewed_on"] == str(result["reviewed_at"])[:10]
    assert lesson_review["lesson_reviewed_on"] == result["reviewed_on"]
    assert lesson_review["editorial_review_interval_days"] == 365
    assert lesson_review["editorial_review_status"] == "review_scheduled"
    assert item["content_checked_at"] == result["reviewed_at"]
    assert item["last_modified"] == "Tue, 06 Oct 2026 00:00:00 GMT"

    connection = monitor._connect()
    try:
        saved = connection.execute(
            "SELECT url, lesson_path, reviewed_digest, reviewed_on, reviewed_at "
            "FROM trusted_source_editorial_reviews"
        ).fetchone()
        columns = {
            str(row["name"])
            for row in connection.execute("PRAGMA table_info(trusted_source_editorial_reviews)")
        }
    finally:
        connection.close()
    assert saved["reviewed_digest"] == preview["content_digest"]
    assert "excerpt" not in columns
    assert "Energy transfer." not in str(dict(saved))

    reference = monitor._references()[0][0]
    monitor._save_check(
        reference,
        etag='"version-b"',
        last_modified="Wed, 07 Oct 2026 00:00:00 GMT",
        checked_at="2026-10-07T00:00:00Z",
        http_status=200,
        state="changed",
        page_title="Work revised",
        content_digest="b" * 64,
        content_checked_at="2026-10-07T00:00:00Z",
    )
    invalidated = monitor.inventory()["sources"][0]["lesson_reviews"][0]
    assert invalidated["lesson_reviewed_on"] == "2020-01-01"


def test_manual_review_refuses_stale_preview_and_wrong_lesson_before_saving(tmp_path: Path) -> None:
    url = "https://openstax.org/books/college-physics-2e/pages/7-1-work-the-scientific-definition"
    _write_lesson(tmp_path, f"[OpenStax work page]({url})")
    monitor = _monitor(tmp_path, tmp_path)
    responses = [
        "<html><body><main><article>Old source text.</article></main></body></html>",
        "<html><body><main><article>Changed source text.</article></main></body></html>",
    ]

    async def handler(_request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            200,
            headers={"content-type": "text/html; charset=utf-8"},
            text=responses.pop(0),
        )

    async def run() -> None:
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            preview = await monitor.preview_source(url, client)
            with pytest.raises(ValueError, match="approved inventory"):
                await monitor.review_source(url, "02_Areas/Physics/lessons/other.md", str(preview["content_digest"]), client)
            with pytest.raises(SourceSnapshotChanged, match="changed after the displayed preview"):
                await monitor.review_source(
                    url,
                    "02_Areas/Physics/lessons/source_test.md",
                    str(preview["content_digest"]),
                    client,
                )

    from trusted_sources import SourceSnapshotChanged

    asyncio.run(run())
    inventory = monitor.inventory()
    assert inventory["sources"][0]["lesson_reviewed_on"] is None


def test_editorial_review_history_uses_newest_first_cursor_pages(tmp_path: Path) -> None:
    url = "https://openstax.org/books/college-physics-2e/pages/7-1-work-the-scientific-definition"
    lesson_path = "02_Areas/Physics/lessons/source_test.md"
    _write_lesson(tmp_path, f"[OpenStax work page]({url})")
    monitor = _monitor(tmp_path, tmp_path)
    for index in range(4):
        monitor._save_editorial_review(
            url,
            lesson_path,
            f"{index + 1:064x}",
            f"2026-10-0{index + 1}",
            f"2026-10-0{index + 1}T10:00:00Z",
        )

    first = monitor.editorial_review_history(url, limit=2)
    second = monitor.editorial_review_history(
        url,
        limit=2,
        before_review_id=int(first["next_before_review_id"]),
    )

    assert [item["review_id"] for item in first["reviews"]] == [4, 3]
    assert first["has_more"] is True
    assert first["next_before_review_id"] == 3
    assert [item["review_id"] for item in second["reviews"]] == [2, 1]
    assert second["has_more"] is False
    assert second["next_before_review_id"] is None

    with pytest.raises(ValueError):
        monitor.editorial_review_history("https://example.com/", limit=2)
    with pytest.raises(ValueError):
        monitor.editorial_review_history(url, limit=101)


def test_inventory_keeps_all_lesson_review_states_for_a_shared_source(tmp_path: Path) -> None:
    root = tmp_path / "project"
    url = "https://openstax.org/books/algebra-and-trigonometry-2e/pages/3-2-domain-and-range"
    lesson_inputs = [
        ("Mathematics/first.md", "source_checked: 2026-10-01\nsource_review_interval_days: 3"),
        ("Mathematics/second.md", "source_checked: 2026-10-04\nsource_review_interval_days: 30"),
    ]
    for relative_path, metadata in lesson_inputs:
        area, name = relative_path.split("/")
        lesson = root / "02_Areas" / area / "lessons" / name
        lesson.parent.mkdir(parents=True, exist_ok=True)
        lesson.write_text(f"---\n{metadata}\n---\n[Domain and range]({url})\n", encoding="utf-8")

    inventory = _monitor(root, tmp_path / "state").inventory(today=date(2026, 10, 5))

    assert inventory["listed_count"] == 1
    item = inventory["sources"][0]
    assert item["lesson_paths"] == [
        "02_Areas/Mathematics/lessons/first.md",
        "02_Areas/Mathematics/lessons/second.md",
    ]
    assert [review["editorial_review_status"] for review in item["lesson_reviews"]] == [
        "review_due",
        "review_scheduled",
    ]
    assert item["editorial_review_status"] == "review_due"
    assert item["editorial_review_due_on"] == "2026-10-04"
    assert inventory["editorial_review_due_count"] == 1


def test_lesson_review_date_must_be_a_single_valid_front_matter_date() -> None:
    reviewed = "---\nsource_checked: 2026-10-02\n---\nLesson body"
    invalid = "---\nsource_checked: 2026-02-30\n---\nLesson body"
    duplicate = "---\nsource_checked: 2026-10-02\nsource_checked: 2026-10-03\n---\nLesson body"
    body_only = "Lesson body\nsource_checked: 2026-10-02"

    assert TrustedSourceMonitor._lesson_reviewed_on(reviewed) == "2026-10-02"
    assert TrustedSourceMonitor._lesson_reviewed_on(invalid) is None
    assert TrustedSourceMonitor._lesson_reviewed_on(duplicate) is None
    assert TrustedSourceMonitor._lesson_reviewed_on(body_only) is None


def test_conditional_check_detects_unchanged_then_changed_versions(tmp_path: Path) -> None:
    url = "https://openstax.org/books/biology-2e/pages/12-3-laws-of-inheritance"
    _write_lesson(tmp_path, f"[Inheritance]({url})\n")
    monitor = _monitor(tmp_path, tmp_path)
    requests: list[httpx.Request] = []
    version = '"v1"'
    page_text = "Inheritance basics"
    force_full_response = False
    fail_next_response = False

    def respond(request: httpx.Request) -> httpx.Response:
        nonlocal version, page_text, force_full_response, fail_next_response
        requests.append(request)
        if fail_next_response:
            fail_next_response = False
            return httpx.Response(503, request=request)
        if (
            request.headers.get("if-none-match") == version
            and not force_full_response
        ):
            return httpx.Response(304, headers={"ETag": version}, request=request)
        return httpx.Response(
            200,
            headers={
                "ETag": version,
                "Last-Modified": "Mon, 05 Oct 2026 00:00:00 GMT",
                "Content-Type": "text/html; charset=utf-8",
            },
            content=f"<html><body><main><p>{page_text}</p></main></body></html>".encode(),
            request=request,
        )

    async def run_checks() -> tuple[
        dict[str, object], dict[str, object], dict[str, object],
        dict[str, object], dict[str, object], dict[str, object], dict[str, object],
        dict[str, object], dict[str, object],
    ]:
        nonlocal version, page_text, force_full_response, fail_next_response
        async with httpx.AsyncClient(
            transport=httpx.MockTransport(respond), follow_redirects=True
        ) as client:
            first = await monitor.check_sources(client)
            second = await monitor.check_sources(client)
            assert second["unchanged_count"] == 1
            page_text = "Inheritance and genetics"
            version = '"v2"'
            force_full_response = True
            third = await monitor.check_sources(client)
            force_full_response = False
            fourth = await monitor.check_sources(client)
            pending_after_not_modified = monitor.inventory()
            fail_next_response = True
            failed = await monitor.check_sources(client)
            pending_after_failure = monitor.inventory()
            force_full_response = True
            await monitor.check_sources(client)
            pending_after_same_body = monitor.inventory()
            preview = await monitor.preview_source(url, client)
            reviewed = await monitor.review_source(
                url,
                str(third["checks"][0]["lesson_path"]),
                str(preview["content_digest"]),
                client,
            )
        return (
            first, second, third, fourth, pending_after_not_modified,
            failed, pending_after_failure, pending_after_same_body, reviewed,
        )

    (
        first, second, third, fourth, pending_after_not_modified, failed,
        pending_after_failure, pending_after_same_body, reviewed,
    ) = asyncio.run(run_checks())

    assert first["available_untracked_count"] == 1
    assert third["changed_count"] == 1
    assert fourth["unchanged_count"] == 1
    assert requests[1].headers["if-none-match"] == '"v1"'
    assert requests[2].headers["if-none-match"] == '"v1"'
    assert third["checks"][0]["state"] == "changed"
    assert requests[3].headers["if-none-match"] == '"v2"'
    assert pending_after_not_modified["changed_count"] == 1
    assert pending_after_not_modified["sources"][0]["state"] == "changed"
    assert failed["checks"][0]["state"] == "unavailable"
    assert pending_after_failure["changed_count"] == 1
    assert pending_after_failure["sources"][0]["state"] == "changed"
    assert pending_after_same_body["changed_count"] == 1
    assert pending_after_same_body["sources"][0]["state"] == "changed"
    assert reviewed["status"] == "ok"
    assert monitor.inventory()["changed_count"] == 0


def test_shared_source_warning_waits_for_every_linked_lesson_review(tmp_path: Path) -> None:
    url = "https://openstax.org/books/biology-2e/pages/12-3-laws-of-inheritance"
    _write_lesson(tmp_path, f"[Inheritance]({url})\n")
    second_lesson = tmp_path / "02_Areas" / "Biology" / "lessons" / "inheritance.md"
    second_lesson.parent.mkdir(parents=True)
    second_lesson.write_text(f"[Inheritance source]({url})\n", encoding="utf-8")
    monitor = _monitor(tmp_path, tmp_path)
    reference = next(
        item for item in monitor._references()[0] if item.url == url
    )
    first_path, second_path = (lesson.lesson_path for lesson in reference.lesson_reviews)
    digest = "a" * 64

    monitor._save_check(
        reference,
        etag='"v2"',
        last_modified=None,
        checked_at="2026-10-11T00:00:00Z",
        http_status=200,
        state="changed",
        content_digest=digest,
        content_checked_at="2026-10-11T00:00:00Z",
    )
    monitor._save_editorial_review(
        url, first_path, digest, "2026-10-11", "2026-10-11T00:00:00Z"
    )
    monitor._clear_pending_review_if_complete(reference)
    assert monitor.inventory()["sources"][0]["state"] == "changed"

    monitor._save_editorial_review(
        url, second_path, digest, "2026-10-11", "2026-10-11T00:01:00Z"
    )
    monitor._clear_pending_review_if_complete(reference)
    inventory = monitor.inventory()
    assert inventory["sources"][0]["state"] == "unchanged"
    assert inventory["changed_count"] == 0


def test_last_modified_is_used_when_etag_is_missing(tmp_path: Path) -> None:
    url = "https://docs.python.org/3/tutorial/controlflow.html"
    _write_lesson(tmp_path, f"[Python]({url}#defining-functions)\n")
    monitor = _monitor(tmp_path, tmp_path)
    requests: list[httpx.Request] = []

    def respond(request: httpx.Request) -> httpx.Response:
        requests.append(request)
        if request.headers.get("if-modified-since"):
            return httpx.Response(
                304,
                headers={"Last-Modified": "Mon, 05 Oct 2026 00:00:00 GMT"},
                request=request,
            )
        return httpx.Response(
            200,
            headers={
                "Last-Modified": "Mon, 05 Oct 2026 00:00:00 GMT",
                "Content-Type": "text/html; charset=utf-8",
            },
            content=b"<html><body><main>Python control flow</main></body></html>",
            request=request,
        )

    async def run_check() -> dict[str, object]:
        async with httpx.AsyncClient(transport=httpx.MockTransport(respond)) as client:
            await monitor.check_sources(client)
            return await monitor.check_sources(client)

    result = asyncio.run(run_check())

    assert requests[1].headers["if-modified-since"] == "Mon, 05 Oct 2026 00:00:00 GMT"
    assert result["unchanged_count"] == 1


def test_redirect_is_not_followed_and_is_reported_for_review(tmp_path: Path) -> None:
    url = "https://animaldiversity.org/accounts/Norops_sagrei/"
    _write_lesson(tmp_path, f"[Anole]({url})\n")
    monitor = _monitor(tmp_path, tmp_path)
    requests: list[httpx.Request] = []

    def respond(request: httpx.Request) -> httpx.Response:
        requests.append(request)
        return httpx.Response(302, headers={"Location": "https://example.test/"}, request=request)

    async def run_check() -> dict[str, object]:
        async with httpx.AsyncClient(
            transport=httpx.MockTransport(respond), follow_redirects=True
        ) as client:
            return await monitor.check_sources(client)

    result = asyncio.run(run_check())

    assert result["needs_attention_count"] == 1
    assert result["checks"][0]["state"] == "redirect_review"
    assert len(requests) == 1


def test_bounded_page_check_saves_only_metadata_and_fingerprint(tmp_path: Path) -> None:
    url = "https://openstax.org/books/biology-2e/pages/12-3-laws-of-inheritance"
    _write_lesson(tmp_path, f"[Inheritance]({url})\n")
    monitor = _monitor(tmp_path, tmp_path)

    def respond(request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            200,
            headers={"ETag": '"v1"', "Content-Type": "text/html; charset=utf-8"},
            content=(
                "<html><head><title>Official inheritance guide</title>"
                "<meta name='description' content='A short official guide.'></head>"
                "<body><nav>Changing navigation</nav><main>Inheritance facts.</main>"
                "<script>ignored script data</script></body></html>"
            ).encode(),
            request=request,
        )

    async def run_check() -> dict[str, object]:
        async with httpx.AsyncClient(transport=httpx.MockTransport(respond)) as client:
            return await monitor.check_sources(client)

    result = asyncio.run(run_check())

    assert result["available_untracked_count"] == 1
    check = monitor._previous_check(url)
    assert check is not None
    assert check["page_title"] == "Official inheritance guide"
    assert check["page_description"] == "A short official guide."
    assert len(check["content_digest"]) == 64
    assert "Inheritance facts." not in repr(tuple(check))
    assert result["checks"][0]["content_checked_at"]


def test_network_errors_do_not_expose_exception_details_or_erase_validators(
    tmp_path: Path,
) -> None:
    url = "https://openstax.org/books/biology-2e/pages/12-3-laws-of-inheritance"
    _write_lesson(tmp_path, f"[Inheritance]({url})\n")
    monitor = _monitor(tmp_path, tmp_path)

    def available(request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            200,
            headers={"ETag": '"v1"', "Content-Type": "text/html"},
            content=b"<html><body><main>English grammar</main></body></html>",
            request=request,
        )

    def fail(request: httpx.Request) -> httpx.Response:
        raise httpx.ConnectError("secret proxy configuration", request=request)

    async def run_check() -> dict[str, object]:
        async with httpx.AsyncClient(transport=httpx.MockTransport(available)) as client:
            await monitor.check_sources(client)
        async with httpx.AsyncClient(transport=httpx.MockTransport(fail)) as client:
            return await monitor.check_sources(client)

    result = asyncio.run(run_check())

    assert result["checks"][0]["state"] == "network_error"
    assert result["checks"][0]["etag"] == '"v1"'
    assert "secret proxy configuration" not in repr(result)


def test_unexpected_304_without_a_saved_validator_needs_attention(tmp_path: Path) -> None:
    url = "https://openstax.org/books/biology-2e/pages/12-3-laws-of-inheritance"
    _write_lesson(tmp_path, f"[Inheritance]({url})\n")
    monitor = _monitor(tmp_path, tmp_path)

    def respond(request: httpx.Request) -> httpx.Response:
        return httpx.Response(304, request=request)

    async def run_check() -> dict[str, object]:
        async with httpx.AsyncClient(transport=httpx.MockTransport(respond)) as client:
            return await monitor.check_sources(client)

    result = asyncio.run(run_check())

    assert result["needs_attention_count"] == 1
    assert result["checks"][0]["state"] == "unexpected_not_modified"


def test_british_antarctic_survey_emperor_penguin_source_is_exact_metadata_only() -> None:
    url = "https://legacy.bas.ac.uk/about_antarctica/wildlife/birds/penguins/emperor.php"

    assert TrustedSourceMonitor._canonical_url(url) == url
    assert TrustedSourceMonitor._rag_policy(url) is None
    assert TrustedSourceMonitor._canonical_url(url + "/unreviewed-page") is None
