from __future__ import annotations

import asyncio
from pathlib import Path

import httpx
import pytest

from trusted_sources import TrustedSourceMonitor


def _write_lesson(root: Path, body: str) -> None:
    lesson = root / "02_Areas" / "Physics" / "lessons" / "source_test.md"
    lesson.parent.mkdir(parents=True)
    lesson.write_text(body, encoding="utf-8")


def _monitor(root: Path, tmp_path: Path) -> TrustedSourceMonitor:
    return TrustedSourceMonitor(root, tmp_path / "knowledge.sqlite3")


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


def test_approved_markdown_links_preserve_titles_and_reject_unapproved_urls() -> None:
    content = (
        "- OpenStax, [Active transport](https://openstax.org/books/biology-2e/pages/5-3-active-transport#pump)\n"
        "- Untrusted page: https://example.test/lesson\n"
    )

    assert TrustedSourceMonitor.approved_markdown_links(content) == [{
        "title": "Active transport",
        "url": "https://openstax.org/books/biology-2e/pages/5-3-active-transport",
    }]


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
        for index in range(25)
    ]
    _write_lesson(tmp_path, "\n".join(f"[Source]({url})" for url in urls))

    references, unsupported_count, omitted_count = _monitor(tmp_path, tmp_path)._references()

    assert len(references) == 20
    assert omitted_count == 5
    assert unsupported_count == 0


def test_inventory_exposes_only_approved_reference_metadata_and_saved_state(tmp_path: Path) -> None:
    url = "https://openstax.org/books/biology-2e/pages/12-3-laws-of-inheritance"
    _write_lesson(
        tmp_path,
        "---\nsubject: Physics\nsource_checked: 2026-10-02\n---\n"
        f"[OpenStax inheritance]({url})\n[Other](https://example.test/page)\n",
    )
    monitor = _monitor(tmp_path, tmp_path)

    unchecked = monitor.inventory()

    assert unchecked["listed_count"] == 1
    assert unchecked["unsupported_count"] == 1
    assert unchecked["unchecked_count"] == 1
    assert unchecked["needs_attention_count"] == 0
    assert unchecked["sources"] == [{
        "url": url,
        "title": "OpenStax inheritance",
        "lesson_path": "02_Areas/Physics/lessons/source_test.md",
        "lesson_reviewed_on": "2026-10-02",
        "state": "not_checked",
        "last_checked_at": None,
        "last_http_status": None,
        "last_modified": None,
        "has_etag": False,
    }]

    monitor._save_check(
        monitor._references()[0][0],
        etag='"version-1"',
        last_modified="Mon, 05 Oct 2026 00:00:00 GMT",
        checked_at="2026-10-05T01:00:00Z",
        http_status=200,
        state="changed",
    )
    checked = monitor.inventory()

    assert checked["changed_count"] == 1
    assert checked["needs_attention_count"] == 1
    item = checked["sources"][0]
    assert item["state"] == "changed"
    assert item["last_http_status"] == 200
    assert item["last_modified"] == "Mon, 05 Oct 2026 00:00:00 GMT"
    assert item["has_etag"] is True
    assert "etag" not in item


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

    def respond(request: httpx.Request) -> httpx.Response:
        nonlocal version
        requests.append(request)
        if request.headers.get("if-none-match") == version and version == '"v1"':
            return httpx.Response(304, headers={"ETag": version}, request=request)
        return httpx.Response(
            200,
            headers={"ETag": version, "Last-Modified": "Mon, 05 Oct 2026 00:00:00 GMT"},
            content=b"Page body must not be used as lesson content",
            request=request,
        )

    async def run_checks() -> tuple[dict[str, object], dict[str, object], dict[str, object]]:
        nonlocal version
        async with httpx.AsyncClient(
            transport=httpx.MockTransport(respond), follow_redirects=True
        ) as client:
            first = await monitor.check_sources(client)
            second = await monitor.check_sources(client)
            version = '"v2"'
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
            headers={"Last-Modified": "Mon, 05 Oct 2026 00:00:00 GMT"},
            content=b"",
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


def test_page_body_is_not_read_or_cached(tmp_path: Path) -> None:
    url = "https://openstax.org/books/biology-2e/pages/12-3-laws-of-inheritance"
    _write_lesson(tmp_path, f"[Inheritance]({url})\n")
    monitor = _monitor(tmp_path, tmp_path)

    class UnreadableBody(httpx.AsyncByteStream):
        async def __aiter__(self):
            raise AssertionError("source monitor must stop after response headers")
            yield b""  # pragma: no cover

        async def aclose(self) -> None:
            return None

    def respond(request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            200,
            headers={"ETag": '"v1"'},
            stream=UnreadableBody(),
            request=request,
        )

    async def run_check() -> dict[str, object]:
        async with httpx.AsyncClient(transport=httpx.MockTransport(respond)) as client:
            return await monitor.check_sources(client)

    result = asyncio.run(run_check())

    assert result["available_untracked_count"] == 1


def test_network_errors_do_not_expose_exception_details_or_erase_validators(
    tmp_path: Path,
) -> None:
    url = "https://openstax.org/books/biology-2e/pages/12-3-laws-of-inheritance"
    _write_lesson(tmp_path, f"[Inheritance]({url})\n")
    monitor = _monitor(tmp_path, tmp_path)

    def available(request: httpx.Request) -> httpx.Response:
        return httpx.Response(200, headers={"ETag": '"v1"'}, request=request)

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
