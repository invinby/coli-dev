"""Bounded availability checks for references in bundled course lessons.

This module does not read, store, or index page content. It records only HTTP
validators from a small, code-owned list of trusted educational domains so the
editorial team can notice references that changed or stopped resolving.
"""

from __future__ import annotations

import asyncio
import os
import re
import sqlite3
import threading
from dataclasses import dataclass
from datetime import date, datetime, timezone
from pathlib import Path
from urllib.parse import urlsplit, urlunsplit

import httpx

_URL_RE = re.compile(r"https?://[^\s<>)\]\"`]+", re.IGNORECASE)
_MARKDOWN_LINK_RE = re.compile(r"\[([^\]]{1,200})\]\(\s*(https://[^)\s]+)\s*\)", re.IGNORECASE)
_SOURCE_CHECKED_RE = re.compile(r"^source_checked:\s*(\d{4}-\d{2}-\d{2})\s*$", re.MULTILINE)
_TRAILING_PUNCTUATION = ".,;:!?"
_MAX_LESSON_FILES = 200
_MAX_LESSON_FILE_BYTES = 256 * 1024
_MAX_SOURCES = 20
_MAX_CONCURRENT_REQUESTS = 5
_MAX_TITLE_LENGTH = 200
_MAX_VALIDATOR_LENGTH = 512
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
class SourceReference:
    url: str
    title: str
    lesson_path: str
    lesson_reviewed_on: str | None


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
        lines = content.splitlines()
        if not lines or lines[0].strip() != "---":
            return None
        try:
            closing = lines.index("---", 1)
        except ValueError:
            return None
        matches = _SOURCE_CHECKED_RE.findall("\n".join(lines[1:closing]))
        if len(matches) != 1:
            return None
        try:
            return date.fromisoformat(matches[0]).isoformat()
        except ValueError:
            return None

    def _references(self) -> tuple[list[SourceReference], int, int]:
        refs: dict[str, SourceReference] = {}
        unsupported_urls: set[str] = set()
        for path in self._lesson_files():
            try:
                if path.stat().st_size > _MAX_LESSON_FILE_BYTES:
                    continue
                content = path.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue

            relative_path = path.relative_to(self.project_root).as_posix()
            lesson_reviewed_on = self._lesson_reviewed_on(content)
            for line in content.splitlines():
                labels = {
                    self._canonical_url(match.group(2)): match.group(1).strip()
                    for match in _MARKDOWN_LINK_RE.finditer(line)
                    if self._canonical_url(match.group(2)) is not None
                }
                for match in _URL_RE.finditer(line):
                    raw_url = match.group(0).rstrip(_TRAILING_PUNCTUATION)
                    canonical = self._canonical_url(raw_url)
                    if canonical is None:
                        if raw_url.casefold().startswith(("https://", "http://")):
                            unsupported_urls.add(raw_url[:2048])
                        continue
                    refs.setdefault(
                        canonical,
                        SourceReference(
                            url=canonical,
                            title=labels.get(canonical, canonical.split("/", 3)[2]),
                            lesson_path=relative_path,
                            lesson_reviewed_on=lesson_reviewed_on,
                        ),
                    )
        ordered_refs = [refs[url] for url in sorted(refs)]
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
        return connection

    def inventory(self) -> dict[str, object]:
        """Return the approved source registry and saved check metadata without network access."""
        references, unsupported_count, omitted_count = self._references()
        with self._db_lock, self._connect() as connection:
            previous_checks = {
                str(row["url"]): row
                for row in connection.execute(
                    "SELECT url, etag, last_modified, last_checked_at, last_http_status, state "
                    "FROM trusted_source_checks"
                ).fetchall()
            }

        items: list[dict[str, object]] = []
        for reference in references:
            previous = previous_checks.get(reference.url)
            items.append({
                "url": reference.url,
                "title": reference.title[:_MAX_TITLE_LENGTH],
                "lesson_path": reference.lesson_path,
                "lesson_reviewed_on": reference.lesson_reviewed_on,
                "state": str(previous["state"]) if previous is not None else "not_checked",
                "last_checked_at": str(previous["last_checked_at"]) if previous is not None else None,
                "last_http_status": int(previous["last_http_status"])
                    if previous is not None and previous["last_http_status"] is not None else None,
                "last_modified": str(previous["last_modified"])
                    if previous is not None and previous["last_modified"] else None,
                "has_etag": bool(previous["etag"]) if previous is not None else False,
            })

        states = [str(item["state"]) for item in items]
        attention_states = {
            "changed", "redirect_review", "unexpected_not_modified", "unavailable", "network_error"
        }
        return {
            "status": "ok",
            "supported_count": len(references) + omitted_count,
            "listed_count": len(references),
            "unchecked_count": states.count("not_checked"),
            "changed_count": states.count("changed"),
            "needs_attention_count": sum(state in attention_states for state in states),
            "unsupported_count": unsupported_count,
            "omitted_count": omitted_count,
            "sources": items,
        }

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
    ) -> None:
        with self._db_lock, self._connect() as connection:
            connection.execute(
                """INSERT INTO trusted_source_checks(
                    url, etag, last_modified, last_checked_at, last_http_status, state
                ) VALUES (?, ?, ?, ?, ?, ?)
                ON CONFLICT(url) DO UPDATE SET
                    etag = excluded.etag,
                    last_modified = excluded.last_modified,
                    last_checked_at = excluded.last_checked_at,
                    last_http_status = excluded.last_http_status,
                    state = excluded.state""",
                (reference.url, etag, last_modified, checked_at, http_status, state),
            )

    @staticmethod
    def _bounded_header(value: str | None) -> str | None:
        if value is None:
            return None
        cleaned = " ".join(value.split())
        return cleaned[:_MAX_VALIDATOR_LENGTH] or None

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
            "Accept": "text/html,application/xhtml+xml;q=0.9,*/*;q=0.1",
            "User-Agent": "ColiDev-Reference-Check/1.0",
        }
        if previous is not None:
            if previous["etag"]:
                headers["If-None-Match"] = str(previous["etag"])
            elif previous["last_modified"]:
                headers["If-Modified-Since"] = str(previous["last_modified"])

        checked_at = datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")
        async with semaphore:
            try:
                async with client.stream(
                    "GET", reference.url, headers=headers, follow_redirects=False
                ) as response:
                    http_status = response.status_code
                    etag = self._bounded_header(response.headers.get("etag"))
                    last_modified = self._bounded_header(response.headers.get("last-modified"))
            except httpx.HTTPError:
                state = "network_error"
                etag = previous["etag"] if previous is not None else None
                last_modified = previous["last_modified"] if previous is not None else None
                http_status = None
            else:
                if http_status == 304 and previous is not None:
                    state = "unchanged"
                    etag = etag or previous["etag"]
                    last_modified = last_modified or previous["last_modified"]
                elif 200 <= http_status < 300:
                    changed = self._validator_changed(previous, etag, last_modified)
                    state = "changed" if changed is True else "unchanged" if changed is False else "available_untracked"
                elif http_status == 304:
                    state = "unexpected_not_modified"
                    etag = previous["etag"] if previous is not None else None
                    last_modified = previous["last_modified"] if previous is not None else None
                elif 300 <= http_status < 400:
                    state = "redirect_review"
                    etag = previous["etag"] if previous is not None else None
                    last_modified = previous["last_modified"] if previous is not None else None
                else:
                    state = "unavailable"
                    etag = previous["etag"] if previous is not None else None
                    last_modified = previous["last_modified"] if previous is not None else None

            self._save_check(
                reference,
                etag=etag,
                last_modified=last_modified,
                checked_at=checked_at,
                http_status=http_status,
                state=state,
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
            "available_untracked", "changed", "unchanged", "redirect_review", "unexpected_not_modified",
            "unavailable", "network_error",
        )}
        return {
            "status": "ok",
            "supported_count": len(references) + omitted_count,
            "checked_count": counts["available_untracked"] + counts["changed"] + counts["unchanged"],
            "changed_count": counts["changed"],
            "unchanged_count": counts["unchanged"],
            "available_untracked_count": counts["available_untracked"],
            "needs_attention_count": (
                counts["redirect_review"] + counts["unexpected_not_modified"]
                + counts["unavailable"] + counts["network_error"]
            ),
            "unsupported_count": unsupported_count,
            "omitted_count": omitted_count,
            "checks": results,
        }
