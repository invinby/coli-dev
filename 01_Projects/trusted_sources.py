"""Bounded freshness signals for official references in bundled lessons.

Only pages on a code-owned allowlist are fetched. A small HTML response is
processed in memory to extract public page metadata and a normalized text
fingerprint; the page body is never persisted or added to RAG. These signals
help editors decide what to review and do not verify lesson facts.
"""

from __future__ import annotations

import asyncio
import hashlib
from html.parser import HTMLParser
import os
import re
import sqlite3
import threading
from dataclasses import dataclass
from datetime import date, datetime, timedelta, timezone
from pathlib import Path
from urllib.parse import urlsplit, urlunsplit

import httpx
from lesson_metadata import (
    _source_checked_date,
    _source_review_interval_days,
    _source_review_schedule,
)

_URL_RE = re.compile(r"https?://[^\s<>)\]\"`]+", re.IGNORECASE)
_MARKDOWN_LINK_RE = re.compile(r"\[([^\]]{1,200})\]\(\s*(https://[^)\s]+)\s*\)", re.IGNORECASE)
_TRAILING_PUNCTUATION = ".,;:!?"
_MAX_LESSON_FILES = 200
_MAX_LESSON_FILE_BYTES = 256 * 1024
_MAX_SOURCES = 20
_MAX_CONCURRENT_REQUESTS = 5
_MAX_TITLE_LENGTH = 200
_MAX_PAGE_DESCRIPTION_LENGTH = 500
_MAX_VALIDATOR_LENGTH = 512
_MAX_SOURCE_PAGE_BYTES = 512 * 1024
_MAX_EXTRACTED_TEXT_CHARS = 200_000
_MAX_SOURCE_PREVIEW_CHARS = 4_000
_AUTO_CHECK_INTERVAL = timedelta(hours=24)
_AUTO_RETRY_INTERVAL = timedelta(hours=6)
_TRANSIENT_SOURCE_STATES = frozenset({"network_error", "unavailable"})
_TRUSTED_HOSTS = frozenset(
    {
        "animaldiversity.org",
        "docs.python.org",
        "learnenglish.britishcouncil.org",
        "openstax.org",
    }
)
_ALLOWED_PATHS = {
    "animaldiversity.org": re.compile(r"^/accounts/[A-Za-z0-9_.-]+/?$"),
    "docs.python.org": re.compile(r"^/3/tutorial/[A-Za-z0-9_.-]+\.html$"),
    "learnenglish.britishcouncil.org": re.compile(
        r"^/free-resources/grammar/(?:english-grammar-reference|b1-b2)/[A-Za-z0-9-]+/?$"
    ),
    "openstax.org": re.compile(r"^/books/[a-z0-9-]+/pages/[a-z0-9-]+/?$"),
}


@dataclass(frozen=True)
class SourceLessonReview:
    lesson_path: str
    reviewed_on: str | None
    interval_days: int | None


@dataclass(frozen=True)
class SourceReference:
    url: str
    title: str
    lesson_reviews: tuple[SourceLessonReview, ...]

    @property
    def lesson_path(self) -> str:
        """Keep the original single-lesson field for the check-result API."""
        return self.lesson_reviews[0].lesson_path


class _SourcePageParser(HTMLParser):
    """Extract bounded, human-readable metadata and visible text from HTML."""

    _SKIPPED_TAGS = frozenset({
        "script", "style", "noscript", "svg", "nav", "header", "footer", "aside", "form", "button",
    })
    _SEMANTIC_TAGS = frozenset({"main", "article"})
    _VOID_TAGS = frozenset({
        "area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta",
        "param", "source", "track", "wbr",
    })

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.title_parts: list[str] = []
        self.description: str | None = None
        self.fallback_parts: list[str] = []
        self.semantic_parts: list[str] = []
        self.in_title = False
        self.in_body = False
        self.semantic_depth = 0
        self.skip_depth = 0
        self.text_size = 0

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        tag = tag.casefold()
        attributes = {key.casefold(): value for key, value in attrs}
        if tag in self._SKIPPED_TAGS:
            self.skip_depth += 1
            return
        if self.skip_depth:
            if tag not in self._VOID_TAGS:
                self.skip_depth += 1
            return
        if tag == "title":
            self.in_title = True
        elif tag == "body":
            self.in_body = True
        elif tag in self._SEMANTIC_TAGS:
            self.semantic_depth += 1
        elif tag == "meta":
            name = (attributes.get("name") or "").casefold()
            prop = (attributes.get("property") or "").casefold()
            content = " ".join((attributes.get("content") or "").split())
            if (
                content
                and len(content) <= _MAX_PAGE_DESCRIPTION_LENGTH * 3
                and (name == "description" or prop == "og:description")
                and self.description is None
            ):
                self.description = content[:_MAX_PAGE_DESCRIPTION_LENGTH]

    def handle_endtag(self, tag: str) -> None:
        tag = tag.casefold()
        if self.skip_depth:
            self.skip_depth -= 1
            return
        if tag == "title":
            self.in_title = False
        elif tag == "body":
            self.in_body = False
        elif tag in self._SEMANTIC_TAGS and self.semantic_depth:
            self.semantic_depth -= 1

    def handle_data(self, data: str) -> None:
        if not data.strip() or self.skip_depth:
            return
        if self.in_title:
            self.title_parts.append(data)
            return
        if not self.in_body:
            return
        remaining = _MAX_EXTRACTED_TEXT_CHARS - self.text_size
        if remaining <= 0:
            return
        value = data[:remaining]
        self.text_size += len(value)
        self.fallback_parts.append(value)
        if self.semantic_depth:
            self.semantic_parts.append(value)

    @staticmethod
    def _normalize(parts: list[str]) -> str:
        return " ".join(" ".join(parts).split())

    def visible_text(self) -> str:
        return self._normalize(self.semantic_parts or self.fallback_parts)

    def result(self) -> tuple[str | None, str | None, str | None]:
        title = self._normalize(self.title_parts)[:_MAX_TITLE_LENGTH] or None
        description = self.description
        visible_text = self.visible_text()
        if not visible_text:
            return title, description, None
        digest = hashlib.sha256(visible_text.encode("utf-8")).hexdigest()
        return title, description, digest


class TrustedSourceMonitor:
    """Check only fixed-domain links authored in bundled course lessons."""

    def __init__(self, project_root: Path, database_path: Path) -> None:
        self.project_root = project_root.resolve()
        self.database_path = database_path.expanduser()
        self._db_lock = threading.RLock()

    @staticmethod
    def _canonical_url(value: str) -> str | None:
        value = value.strip().rstrip(_TRAILING_PUNCTUATION)
        try:
            parsed = urlsplit(value)
            port = parsed.port
        except ValueError:
            return None
        host = (parsed.hostname or "").casefold()
        if (
            parsed.scheme.casefold() != "https"
            or host not in _TRUSTED_HOSTS
            or parsed.username is not None
            or parsed.password is not None
            or port not in {None, 443}
            or parsed.query
            or len(value) > 2048
            or not _ALLOWED_PATHS[host].fullmatch(parsed.path)
        ):
            return None
        return urlunsplit(("https", host, parsed.path, "", ""))

    @classmethod
    def approved_markdown_links(
        cls, content: str, *, limit: int | None = 20
    ) -> list[dict[str, str]]:
        """Extract bounded titles and canonical URLs from approved official sources."""
        if limit is not None:
            limit = max(0, limit)
            if limit == 0:
                return []
        references: dict[str, dict[str, str]] = {}
        for line in content.splitlines():
            labels = {
                canonical: match.group(1).strip()
                for match in _MARKDOWN_LINK_RE.finditer(line)
                if (canonical := cls._canonical_url(match.group(2))) is not None
            }
            for match in _URL_RE.finditer(line):
                canonical = cls._canonical_url(match.group(0).rstrip(_TRAILING_PUNCTUATION))
                if canonical is None:
                    continue
                title = labels.get(canonical)
                if not title:
                    title = re.sub(r"[*_`]+", "", line[:match.start()]).strip(" \t-*•:;.,<>")
                if not title:
                    title = urlsplit(canonical).hostname or canonical
                references.setdefault(canonical, {
                    "title": title[:_MAX_TITLE_LENGTH],
                    "url": canonical,
                })
                if limit is not None and len(references) >= limit:
                    break
            if limit is not None and len(references) >= limit:
                break
        return [references[url] for url in sorted(references)]

    def _lesson_files(self) -> list[Path]:
        root = self.project_root / "02_Areas"
        if root.is_symlink() or not root.is_dir():
            return []
        files: list[Path] = []
        for current_root, directory_names, file_names in os.walk(root, followlinks=False):
            current = Path(current_root)
            directory_names.sort()
            directory_names[:] = [
                name for name in directory_names if not (current / name).is_symlink()
            ]
            if current.name.casefold() != "lessons":
                continue
            for file_name in sorted(file_names):
                path = current / file_name
                if path.suffix.casefold() == ".md" and not path.is_symlink():
                    files.append(path)
                    if len(files) >= _MAX_LESSON_FILES:
                        return sorted(files)
        return sorted(files)

    @staticmethod
    def _lesson_reviewed_on(content: str) -> str | None:
        """Read one valid source_checked date from the lesson's YAML front matter."""
        return _source_checked_date(content)

    def _references(self) -> tuple[list[SourceReference], int, int]:
        titles: dict[str, str] = {}
        lesson_reviews: dict[str, dict[str, SourceLessonReview]] = {}
        unsupported_urls: set[str] = set()
        for path in self._lesson_files():
            try:
                if path.stat().st_size > _MAX_LESSON_FILE_BYTES:
                    continue
                content = path.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue

            relative_path = path.relative_to(self.project_root).as_posix()
            lesson_review = SourceLessonReview(
                lesson_path=relative_path,
                reviewed_on=self._lesson_reviewed_on(content),
                interval_days=_source_review_interval_days(content),
            )
            for source in self.approved_markdown_links(content, limit=None):
                canonical = source["url"]
                titles.setdefault(canonical, source["title"])
                lesson_reviews.setdefault(canonical, {})[relative_path] = lesson_review
            for line in content.splitlines():
                for match in _URL_RE.finditer(line):
                    raw_url = match.group(0).rstrip(_TRAILING_PUNCTUATION)
                    canonical = self._canonical_url(raw_url)
                    if canonical is None:
                        if raw_url.casefold().startswith(("https://", "http://")):
                            unsupported_urls.add(raw_url[:2048])
                        continue
        ordered_refs = [
            SourceReference(
                url=url,
                title=titles[url],
                lesson_reviews=tuple(
                    lesson_reviews[url][path] for path in sorted(lesson_reviews[url])
                ),
            )
            for url in sorted(titles)
        ]
        omitted_count = max(0, len(ordered_refs) - _MAX_SOURCES)
        return ordered_refs[:_MAX_SOURCES], len(unsupported_urls), omitted_count

    def _connect(self) -> sqlite3.Connection:
        self.database_path.parent.mkdir(parents=True, exist_ok=True)
        connection = sqlite3.connect(self.database_path, timeout=10)
        connection.row_factory = sqlite3.Row
        connection.execute("PRAGMA busy_timeout = 10000")
        connection.execute(
            """CREATE TABLE IF NOT EXISTS trusted_source_checks (
                url TEXT PRIMARY KEY,
                etag TEXT,
                last_modified TEXT,
                last_checked_at TEXT NOT NULL,
                last_http_status INTEGER,
                state TEXT NOT NULL
            )"""
        )
        columns = {
            str(row["name"])
            for row in connection.execute("PRAGMA table_info(trusted_source_checks)").fetchall()
        }
        for column, declaration in (
            ("page_title", "TEXT"),
            ("page_description", "TEXT"),
            ("content_digest", "TEXT"),
            ("content_checked_at", "TEXT"),
        ):
            if column not in columns:
                connection.execute(
                    f"ALTER TABLE trusted_source_checks ADD COLUMN {column} {declaration}"
                )
        return connection

    def inventory(self, *, today: date | None = None) -> dict[str, object]:
        """Return the approved source registry and saved check metadata without network access."""
        references, unsupported_count, omitted_count = self._references()
        with self._db_lock, self._connect() as connection:
            previous_checks = {
                str(row["url"]): row
                for row in connection.execute(
                    "SELECT url, etag, last_modified, last_checked_at, last_http_status, state, "
                    "page_title, page_description, content_checked_at "
                    "FROM trusted_source_checks"
                ).fetchall()
            }

        items: list[dict[str, object]] = []
        for reference in references:
            previous = previous_checks.get(reference.url)
            lesson_review_items: list[dict[str, object]] = []
            for lesson_review in reference.lesson_reviews:
                due_on, schedule_status = _source_review_schedule(
                    lesson_review.reviewed_on,
                    lesson_review.interval_days,
                    today,
                )
                if lesson_review.reviewed_on is None:
                    editorial_status = "review_missing"
                elif schedule_status is None:
                    editorial_status = "review_unscheduled"
                else:
                    editorial_status = f"review_{schedule_status}"
                lesson_review_items.append({
                    "lesson_path": lesson_review.lesson_path,
                    "lesson_reviewed_on": lesson_review.reviewed_on,
                    "editorial_review_interval_days": lesson_review.interval_days,
                    "editorial_review_due_on": due_on,
                    "editorial_review_status": editorial_status,
                })
            lesson_review_statuses = [
                str(item["editorial_review_status"]) for item in lesson_review_items
            ]
            editorial_review_status = next(
                (
                    status for status in (
                        "review_due", "review_missing", "review_unscheduled", "review_scheduled"
                    ) if status in lesson_review_statuses
                ),
                "review_missing",
            )
            due_dates = [
                str(item["editorial_review_due_on"])
                for item in lesson_review_items
                if item["editorial_review_due_on"] is not None
            ]
            first_review = reference.lesson_reviews[0]
            items.append({
                "url": reference.url,
                "title": reference.title[:_MAX_TITLE_LENGTH],
                "lesson_path": reference.lesson_path,
                "lesson_paths": [item.lesson_path for item in reference.lesson_reviews],
                "lesson_reviews": lesson_review_items,
                "lesson_reviewed_on": first_review.reviewed_on,
                "editorial_review_interval_days": first_review.interval_days,
                "editorial_review_due_on": min(due_dates) if due_dates else None,
                "editorial_review_status": editorial_review_status,
                "state": str(previous["state"]) if previous is not None else "not_checked",
                "last_checked_at": str(previous["last_checked_at"]) if previous is not None else None,
                "last_http_status": int(previous["last_http_status"])
                    if previous is not None and previous["last_http_status"] is not None else None,
                "last_modified": str(previous["last_modified"])
                    if previous is not None and previous["last_modified"] else None,
                "has_etag": bool(previous["etag"]) if previous is not None else False,
                "page_title": str(previous["page_title"])
                    if previous is not None and previous["page_title"] else None,
                "page_description": str(previous["page_description"])
                    if previous is not None and previous["page_description"] else None,
                "content_checked_at": str(previous["content_checked_at"])
                    if previous is not None and previous["content_checked_at"] else None,
            })

        states = [str(item["state"]) for item in items]
        attention_states = {
            "changed", "content_baseline", "content_unavailable", "content_too_large",
            "unsupported_content_type", "redirect_review", "unexpected_not_modified",
            "unavailable", "network_error",
        }
        editorial_states = [str(item["editorial_review_status"]) for item in items]
        return {
            "status": "ok",
            "supported_count": len(references) + omitted_count,
            "listed_count": len(references),
            "unchecked_count": states.count("not_checked"),
            "changed_count": states.count("changed"),
            "needs_attention_count": sum(state in attention_states for state in states),
            "editorial_review_due_count": editorial_states.count("review_due"),
            "editorial_review_scheduled_count": editorial_states.count("review_scheduled"),
            "editorial_review_missing_count": editorial_states.count("review_missing"),
            "editorial_review_unscheduled_count": editorial_states.count("review_unscheduled"),
            "unsupported_count": unsupported_count,
            "omitted_count": omitted_count,
            "sources": items,
        }

    def seconds_until_automatic_check(self, *, now: datetime | None = None) -> float | None:
        """Return delay until the next bounded check, retrying transient failures sooner."""
        references, _, _ = self._references()
        if not references:
            return None
        current = now or datetime.now(timezone.utc)
        if current.tzinfo is None:
            current = current.replace(tzinfo=timezone.utc)
        with self._db_lock, self._connect() as connection:
            previous_checks = {
                str(row["url"]): row
                for row in connection.execute(
                    "SELECT url, last_checked_at, state FROM trusted_source_checks"
                ).fetchall()
            }

        delays: list[float] = []
        for reference in references:
            previous = previous_checks.get(reference.url)
            if previous is None:
                return 0.0
            try:
                checked_at = datetime.fromisoformat(
                    str(previous["last_checked_at"]).replace("Z", "+00:00")
                )
            except (TypeError, ValueError):
                return 0.0
            if checked_at.tzinfo is None:
                checked_at = checked_at.replace(tzinfo=timezone.utc)
            interval = (
                _AUTO_RETRY_INTERVAL
                if str(previous["state"]) in _TRANSIENT_SOURCE_STATES
                else _AUTO_CHECK_INTERVAL
            )
            delays.append((checked_at + interval - current).total_seconds())
        return max(0.0, min(delays))

    def _previous_check(self, url: str) -> sqlite3.Row | None:
        with self._db_lock, self._connect() as connection:
            return connection.execute(
                "SELECT * FROM trusted_source_checks WHERE url = ?", (url,)
            ).fetchone()

    def _save_check(
        self,
        reference: SourceReference,
        *,
        etag: str | None,
        last_modified: str | None,
        checked_at: str,
        http_status: int | None,
        state: str,
        page_title: str | None = None,
        page_description: str | None = None,
        content_digest: str | None = None,
        content_checked_at: str | None = None,
        preserve_content_metadata: bool = False,
    ) -> None:
        with self._db_lock, self._connect() as connection:
            connection.execute(
                """INSERT INTO trusted_source_checks(
                    url, etag, last_modified, last_checked_at, last_http_status, state,
                    page_title, page_description, content_digest, content_checked_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(url) DO UPDATE SET
                    etag = excluded.etag,
                    last_modified = excluded.last_modified,
                    last_checked_at = excluded.last_checked_at,
                    last_http_status = excluded.last_http_status,
                    state = excluded.state,
                    page_title = CASE WHEN ? THEN trusted_source_checks.page_title ELSE excluded.page_title END,
                    page_description = CASE WHEN ? THEN trusted_source_checks.page_description ELSE excluded.page_description END,
                    content_digest = CASE WHEN ? THEN trusted_source_checks.content_digest ELSE excluded.content_digest END,
                    content_checked_at = CASE WHEN ? THEN trusted_source_checks.content_checked_at ELSE excluded.content_checked_at END""",
                (
                    reference.url, etag, last_modified, checked_at, http_status, state,
                    page_title, page_description, content_digest, content_checked_at,
                    preserve_content_metadata, preserve_content_metadata,
                    preserve_content_metadata, preserve_content_metadata,
                ),
            )

    @staticmethod
    def _bounded_header(value: str | None) -> str | None:
        if value is None:
            return None
        cleaned = " ".join(value.split())
        return cleaned[:_MAX_VALIDATOR_LENGTH] or None

    @staticmethod
    async def _read_bounded_html(response: httpx.Response) -> tuple[bytes | None, bool]:
        """Read at most a fixed number of decoded response bytes into memory."""
        content_length = response.headers.get("content-length")
        if content_length:
            try:
                if int(content_length) > _MAX_SOURCE_PAGE_BYTES:
                    return None, True
            except ValueError:
                pass

        body = bytearray()
        async for chunk in response.aiter_bytes(chunk_size=16 * 1024):
            if len(body) + len(chunk) > _MAX_SOURCE_PAGE_BYTES:
                return None, True
            body.extend(chunk)
        return bytes(body), False

    @staticmethod
    def _parse_source_page(body: bytes, encoding: str | None) -> tuple[str | None, str | None, str | None]:
        try:
            decoded = body.decode(encoding or "utf-8", errors="replace")
        except LookupError:
            decoded = body.decode("utf-8", errors="replace")
        parser = _SourcePageParser()
        parser.feed(decoded)
        parser.close()
        return parser.result()

    @staticmethod
    def _parse_source_page_preview(
        body: bytes, encoding: str | None
    ) -> tuple[str | None, str | None, str | None, str]:
        try:
            decoded = body.decode(encoding or "utf-8", errors="replace")
        except LookupError:
            decoded = body.decode("utf-8", errors="replace")
        parser = _SourcePageParser()
        parser.feed(decoded)
        parser.close()
        title, description, digest = parser.result()
        return title, description, digest, parser.visible_text()

    @staticmethod
    def _validator_changed(
        previous: sqlite3.Row | None, etag: str | None, last_modified: str | None
    ) -> bool | None:
        if previous is None:
            return None
        comparisons: list[bool] = []
        for name, current in (("etag", etag), ("last_modified", last_modified)):
            old = previous[name]
            if old and current:
                comparisons.append(old != current)
        if not comparisons:
            return None
        return any(comparisons)

    async def _check_one(
        self,
        client: httpx.AsyncClient,
        reference: SourceReference,
        semaphore: asyncio.Semaphore,
    ) -> dict[str, object]:
        previous = self._previous_check(reference.url)
        headers = {
            "Accept": "text/html,application/xhtml+xml;q=0.9",
            "Accept-Encoding": "identity",
            "User-Agent": "ColiDev-Reference-Check/1.0",
        }
        # Legacy rows have HTTP validators but no content fingerprint. Fetch a
        # bounded page once to establish a content baseline before using 304.
        if previous is not None and previous["content_digest"]:
            if previous["etag"]:
                headers["If-None-Match"] = str(previous["etag"])
            elif previous["last_modified"]:
                headers["If-Modified-Since"] = str(previous["last_modified"])

        checked_at = datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")
        page_title = str(previous["page_title"]) if previous is not None and previous["page_title"] else None
        page_description = (
            str(previous["page_description"])
            if previous is not None and previous["page_description"] else None
        )
        content_digest = (
            str(previous["content_digest"])
            if previous is not None and previous["content_digest"] else None
        )
        content_checked_at = (
            str(previous["content_checked_at"])
            if previous is not None and previous["content_checked_at"] else None
        )
        preserve_content_metadata = True
        async with semaphore:
            try:
                async with client.stream(
                    "GET", reference.url, headers=headers, follow_redirects=False
                ) as response:
                    http_status = response.status_code
                    etag = self._bounded_header(response.headers.get("etag"))
                    last_modified = self._bounded_header(response.headers.get("last-modified"))
                    if http_status == 304 and previous is not None and previous["content_digest"]:
                        state = "unchanged"
                        etag = etag or previous["etag"]
                        last_modified = last_modified or previous["last_modified"]
                        content_checked_at = checked_at
                        preserve_content_metadata = False
                    elif 200 <= http_status < 300:
                        content_type = (
                            response.headers.get("content-type", "")
                            .split(";", 1)[0]
                            .strip()
                            .casefold()
                        )
                        if http_status != 200:
                            state = "content_unavailable"
                        elif content_type not in {"text/html", "application/xhtml+xml"}:
                            state = "unsupported_content_type"
                        else:
                            body, too_large = await self._read_bounded_html(response)
                            if too_large:
                                state = "content_too_large"
                            elif not body:
                                state = "content_unavailable"
                            else:
                                parsed_title, parsed_description, parsed_digest = self._parse_source_page(
                                    body, response.encoding
                                )
                                if parsed_digest is None:
                                    state = "content_unavailable"
                                else:
                                    metadata_changed = previous is not None and (
                                        parsed_title != previous["page_title"]
                                        or parsed_description != previous["page_description"]
                                    )
                                    page_title = parsed_title
                                    page_description = parsed_description
                                    content_digest = parsed_digest
                                    content_checked_at = checked_at
                                    preserve_content_metadata = False
                                    validator_changed = self._validator_changed(
                                        previous, etag, last_modified
                                    )
                                    if previous is None:
                                        state = "available_untracked"
                                    elif previous["content_digest"] is None:
                                        state = "content_baseline"
                                    elif (
                                        parsed_digest != previous["content_digest"]
                                        or validator_changed is True
                                        or metadata_changed
                                    ):
                                        state = "changed"
                                    else:
                                        state = "unchanged"
                    elif http_status == 304:
                        state = "unexpected_not_modified"
                    elif 300 <= http_status < 400:
                        state = "redirect_review"
                    else:
                        state = "unavailable"
            except httpx.HTTPError:
                state = "network_error"
                etag = previous["etag"] if previous is not None else None
                last_modified = previous["last_modified"] if previous is not None else None
                http_status = None
                preserve_content_metadata = True

            if state in {
                "unsupported_content_type", "content_too_large", "content_unavailable",
                "unexpected_not_modified", "redirect_review", "unavailable", "network_error",
            }:
                etag = previous["etag"] if previous is not None else None
                last_modified = previous["last_modified"] if previous is not None else None
                preserve_content_metadata = True

            self._save_check(
                reference,
                etag=etag,
                last_modified=last_modified,
                checked_at=checked_at,
                http_status=http_status,
                state=state,
                page_title=page_title,
                page_description=page_description,
                content_digest=content_digest,
                content_checked_at=content_checked_at,
                preserve_content_metadata=preserve_content_metadata,
            )
        return {
            "url": reference.url,
            "title": reference.title[:_MAX_TITLE_LENGTH],
            "lesson_path": reference.lesson_path,
            "state": state,
            "http_status": http_status,
            "etag": etag,
            "last_modified": last_modified,
            "checked_at": checked_at,
            "page_title": page_title,
            "page_description": page_description,
            "content_checked_at": content_checked_at,
        }

    async def check_sources(
        self, client: httpx.AsyncClient | None = None
    ) -> dict[str, object]:
        references, unsupported_count, omitted_count = self._references()
        semaphore = asyncio.Semaphore(_MAX_CONCURRENT_REQUESTS)
        if client is None:
            async with httpx.AsyncClient(
                timeout=httpx.Timeout(connect=3.0, read=6.0, write=3.0, pool=3.0),
                limits=httpx.Limits(max_connections=_MAX_CONCURRENT_REQUESTS),
                follow_redirects=False,
                trust_env=False,
            ) as owned_client:
                results = await asyncio.gather(
                    *(self._check_one(owned_client, ref, semaphore) for ref in references)
                )
        else:
            results = await asyncio.gather(
                *(self._check_one(client, ref, semaphore) for ref in references)
            )

        counts = {state: sum(item["state"] == state for item in results) for state in (
            "available_untracked", "content_baseline", "changed", "unchanged",
            "content_unavailable", "content_too_large", "unsupported_content_type",
            "redirect_review", "unexpected_not_modified", "unavailable", "network_error",
        )}
        return {
            "status": "ok",
            "supported_count": len(references) + omitted_count,
            "checked_count": (
                counts["available_untracked"] + counts["content_baseline"]
                + counts["changed"] + counts["unchanged"]
            ),
            "changed_count": counts["changed"],
            "unchanged_count": counts["unchanged"],
            "available_untracked_count": counts["available_untracked"],
            "needs_attention_count": (
                counts["content_baseline"] + counts["content_unavailable"]
                + counts["content_too_large"] + counts["unsupported_content_type"]
                + counts["redirect_review"] + counts["unexpected_not_modified"]
                + counts["unavailable"] + counts["network_error"]
            ),
            "unsupported_count": unsupported_count,
            "omitted_count": omitted_count,
            "checks": results,
        }

    async def preview_source(
        self, url: str, client: httpx.AsyncClient | None = None
    ) -> dict[str, object]:
        """Fetch a short, non-persistent preview for one exact approved lesson URL."""
        canonical = self._canonical_url(url)
        references, _, _ = self._references()
        reference = next((item for item in references if item.url == canonical), None)
        if reference is None:
            raise ValueError("Source is not in the approved lesson inventory")

        headers = {
            "Accept": "text/html,application/xhtml+xml;q=0.9",
            "Accept-Encoding": "identity",
            "User-Agent": "ColiDev-Reference-Preview/1.0",
        }

        async def fetch(active_client: httpx.AsyncClient) -> dict[str, object]:
            async with active_client.stream(
                "GET", reference.url, headers=headers, follow_redirects=False
            ) as response:
                if response.status_code != 200:
                    raise RuntimeError("Approved source did not return HTTP 200")
                content_type = (
                    response.headers.get("content-type", "")
                    .split(";", 1)[0]
                    .strip()
                    .casefold()
                )
                if content_type not in {"text/html", "application/xhtml+xml"}:
                    raise RuntimeError("Approved source did not return HTML")
                body, too_large = await self._read_bounded_html(response)
                if too_large or not body:
                    raise RuntimeError("Approved source preview is unavailable")
                encoding = response.encoding

            title, description, digest, visible_text = self._parse_source_page_preview(
                body, encoding
            )
            if digest is None:
                raise RuntimeError("Approved source has no readable text")
            return {
                "url": reference.url,
                "title": reference.title,
                "lesson_paths": [review.lesson_path for review in reference.lesson_reviews],
                "page_title": title,
                "page_description": description,
                "excerpt": visible_text[:_MAX_SOURCE_PREVIEW_CHARS],
                "excerpt_truncated": len(visible_text) > _MAX_SOURCE_PREVIEW_CHARS,
                "content_digest": digest,
                "fetched_at": datetime.now(timezone.utc).isoformat(timespec="seconds").replace(
                    "+00:00", "Z"
                ),
            }

        if client is not None:
            return await fetch(client)
        async with httpx.AsyncClient(
            timeout=httpx.Timeout(connect=3.0, read=6.0, write=3.0, pool=3.0),
            follow_redirects=False,
            trust_env=False,
        ) as owned_client:
            return await fetch(owned_client)
