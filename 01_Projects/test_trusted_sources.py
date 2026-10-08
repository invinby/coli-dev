from __future__ import annotations

import asyncio
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

import httpx
import pytest

from trusted_sources import TrustedSourceMonitor, _MAX_SOURCES


def _write_lesson(root: Path, body: str) -> None:
    lesson = root / "02_Areas" / "Physics" / "lessons" / "source_test.md"
    lesson.parent.mkdir(parents=True)
    lesson.write_text(body, encoding="utf-8")


def _monitor(root: Path, tmp_path: Path) -> TrustedSourceMonitor:
    return TrustedSourceMonitor(root, tmp_path / "knowledge.sqlite3")


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


def test_gene_expression_sources_are_exact_path_monitored_metadata_only(tmp_path: Path) -> None:
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
    assert all(monitor._rag_policy(url) is None for url in urls)
    assert all(not monitor._has_rag_snapshot(url) for url in urls)


def test_cell_cycle_sources_are_monitored_metadata_only(tmp_path: Path) -> None:
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
    assert all(monitor._rag_policy(url) is None for url in urls)
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


def test_python_assert_reference_is_an_exact_approved_rag_path() -> None:
    url = "https://docs.python.org/3/reference/simple_stmts.html#the-assert-statement"
    assert TrustedSourceMonitor._canonical_url(url) == "https://docs.python.org/3/reference/simple_stmts.html"
    policy = TrustedSourceMonitor._rag_policy("https://docs.python.org/3/reference/simple_stmts.html")
    assert policy is not None
    assert policy["license"] == "Python Software Foundation License Version 2"
    assert TrustedSourceMonitor._canonical_url("https://docs.python.org/3/reference/expressions.html") is None


def test_python_bisect_library_page_is_monitored_and_licensed_for_rag(tmp_path: Path) -> None:
    url = "https://docs.python.org/3/library/bisect.html"
    _write_lesson(tmp_path, f"[Python bisect reference]({url})")
    monitor = _monitor(tmp_path, tmp_path)

    assert monitor._canonical_url(url) == url
    policy = monitor._rag_policy(url)
    assert policy is not None
    assert policy["license"] == "Python Software Foundation License Version 2"
    assert monitor.inventory()["sources"][0]["rag_content_state"] == "license_approved_pending_check"


def test_sqlite_transaction_reference_is_exact_and_metadata_only() -> None:
    url = "https://www.sqlite.org/lang_transaction.html"
    assert TrustedSourceMonitor._canonical_url(url) == url
    assert TrustedSourceMonitor._rag_policy(url) is None
    assert TrustedSourceMonitor._canonical_url("https://www.sqlite.org/lang_select.html") is None


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


def test_unlicensed_official_sources_remain_metadata_only_for_rag(tmp_path: Path) -> None:
    url = "https://openstax.org/books/college-physics-2e/pages/7-1-work-the-scientific-definition"
    _write_lesson(tmp_path, f"[OpenStax work page]({url})")
    monitor = _monitor(tmp_path, tmp_path)

    assert monitor._rag_policy(url) is None
    assert monitor.inventory()["sources"][0]["rag_content_state"] == "metadata_only_noncommercial"
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


def test_british_council_reading_pages_are_monitored_metadata_only(tmp_path: Path) -> None:
    urls = [
        "https://learnenglish.britishcouncil.org/free-resources/reading/a1",
        "https://learnenglish.britishcouncil.org/level/improve-your-english-level/how-start-reading-english",
    ]
    _write_lesson(tmp_path, "\n".join(f"[Reading source]({url})" for url in urls))
    monitor = _monitor(tmp_path, tmp_path)

    assert {item["url"] for item in monitor.inventory()["sources"]} == set(urls)
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
        "content_checked_at": None,
        "rag_content_state": "metadata_only_noncommercial",
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

    def respond(request: httpx.Request) -> httpx.Response:
        nonlocal version, page_text, force_full_response
        requests.append(request)
        if (
            request.headers.get("if-none-match") == version
            and version == '"v1"'
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

    async def run_checks() -> tuple[dict[str, object], dict[str, object], dict[str, object]]:
        nonlocal version, page_text, force_full_response
        async with httpx.AsyncClient(
            transport=httpx.MockTransport(respond), follow_redirects=True
        ) as client:
            first = await monitor.check_sources(client)
            second = await monitor.check_sources(client)
            page_text = "Inheritance and genetics"
            force_full_response = True
            third = await monitor.check_sources(client)
        return first, second, third

    first, second, third = asyncio.run(run_checks())

    assert first["available_untracked_count"] == 1
    assert second["unchanged_count"] == 1
    assert third["changed_count"] == 1
    assert requests[1].headers["if-none-match"] == '"v1"'
    assert requests[2].headers["if-none-match"] == '"v1"'
    assert third["checks"][0]["state"] == "changed"


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
