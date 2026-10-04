"""Small offline keyword index for curated ColiDev course materials.

Only Markdown under 02_Areas and Markdown/text cheat sheets under
03_Resources/Cheatsheets are indexed. Prompts, plans, dotfiles, symlinks,
and files outside those roots are intentionally excluded.
"""
from __future__ import annotations

import hashlib
import logging
import math
import os
import re
import sqlite3
import sys
import threading
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

logger = logging.getLogger("colidev.knowledge")

_CHUNK_CHARS = 1200
_MAX_FILE_BYTES = 512 * 1024
_MAX_DOCUMENTS = 2000
_MAX_TOTAL_BYTES = 64 * 1024 * 1024
_MAX_RESULTS_PER_DOCUMENT = 2
_IGNORED_DIRS = {
    ".git", ".obsidian", "__pycache__", "build", "dist", "node_modules", "vendor",
}
_HEADING_RE = re.compile(r"^\s{0,3}#{1,6}\s+(.+?)\s*#*\s*$")
_TOKEN_RE = re.compile(r"[^\W_]+", re.UNICODE)
_STOP_WORDS = {
    "a", "an", "and", "are", "as", "at", "be", "by", "for", "from", "how",
    "in", "into", "is", "it", "of", "on", "or", "that", "the", "this", "to",
    "was", "what", "when", "where", "which", "with", "you",
    "в", "во", "для", "до", "же", "за", "и", "из", "или", "как", "к", "на",
    "над", "не", "но", "о", "об", "от", "по", "под", "при", "про", "с", "со",
    "то", "у", "что", "это",
}


def default_database_path() -> Path:
    """Return a per-user writable database path on macOS, Windows, or Linux."""
    if sys.platform == "darwin":
        base = Path.home() / "Library" / "Application Support" / "coli-dev"
    elif os.name == "nt":
        base = Path(os.environ.get("LOCALAPPDATA", Path.home() / "AppData" / "Local")) / "ColiDev"
    else:
        base = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share")) / "coli-dev"
    return base / "knowledge.sqlite3"


def _utc_timestamp(timestamp: float) -> str:
    return datetime.fromtimestamp(timestamp, tz=timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")


def _tokens(text: str) -> list[str]:
    return [token for token in _TOKEN_RE.findall(text.casefold()) if len(token) >= 2 and token not in _STOP_WORDS]


def _expanded_tokens(tokens: Iterable[str]) -> list[str]:
    result: list[str] = []
    for token in tokens:
        result.append(token)
        # A lightweight prefix match helps RU/EN inflected forms without
        # pretending this keyword index is a full morphological search engine.
        if len(token) >= 6:
            result.append(token[:5])
    return result


def _split_markdown(text: str, fallback_heading: str) -> list[tuple[int, int, str, str]]:
    """Split Markdown into bounded heading-aware chunks with source line spans."""
    lines = text.splitlines()
    chunks: list[tuple[int, int, str, str]] = []
    heading = fallback_heading
    buffer: list[str] = []
    buffer_chars = 0
    start_line = 1
    end_line = 1

    def flush() -> None:
        nonlocal buffer, buffer_chars
        value = "\n".join(buffer).strip()
        if value:
            chunks.append((start_line, end_line, heading, value))
        buffer = []
        buffer_chars = 0

    for line_number, line in enumerate(lines, start=1):
        heading_match = _HEADING_RE.match(line)
        if heading_match:
            flush()
            heading = heading_match.group(1).strip()[:200] or fallback_heading
            start_line = line_number
            end_line = line_number
            continue

        # Keep a single unusually long line within the same safety bound.
        pieces = [line[index:index + _CHUNK_CHARS] for index in range(0, len(line), _CHUNK_CHARS)] or [""]
        for piece in pieces:
            added = len(piece) + (1 if buffer else 0)
            if buffer and buffer_chars + added > _CHUNK_CHARS:
                flush()
                start_line = line_number
            if not buffer:
                start_line = line_number
            buffer.append(piece)
            buffer_chars += len(piece) + (1 if len(buffer) > 1 else 0)
            end_line = line_number

    flush()
    if not chunks and text.strip():
        chunks.append((1, max(1, len(lines)), fallback_heading, text[:_CHUNK_CHARS].strip()))
    return chunks


class KnowledgeIndex:
    """Incremental SQLite index for approved local learning materials."""

    _SOURCE_ROOTS = (
        (Path("02_Areas"), frozenset({".md"})),
        (Path("03_Resources") / "Cheatsheets", frozenset({".md", ".txt"})),
    )

    def __init__(self, project_root: Path, database_path: Path | None = None) -> None:
        self.project_root = project_root.resolve()
        self.database_path = (database_path or default_database_path()).expanduser()
        self._lock = threading.RLock()

    def _connect(self) -> sqlite3.Connection:
        self.database_path.parent.mkdir(parents=True, exist_ok=True)
        connection = sqlite3.connect(self.database_path, timeout=10)
        connection.row_factory = sqlite3.Row
        connection.execute("PRAGMA foreign_keys = ON")
        connection.execute("PRAGMA busy_timeout = 10000")
        return connection

    @staticmethod
    def _ensure_schema(connection: sqlite3.Connection) -> None:
        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS documents (
                path TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                digest TEXT NOT NULL,
                modified_ns INTEGER NOT NULL,
                size_bytes INTEGER NOT NULL,
                modified_at TEXT NOT NULL
            )
            """
        )
        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS chunks (
                path TEXT NOT NULL REFERENCES documents(path) ON DELETE CASCADE,
                chunk_index INTEGER NOT NULL,
                heading TEXT NOT NULL,
                start_line INTEGER NOT NULL,
                end_line INTEGER NOT NULL,
                text TEXT NOT NULL,
                PRIMARY KEY (path, chunk_index)
            )
            """
        )
        connection.execute(
            "CREATE TABLE IF NOT EXISTS index_meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)"
        )

    def _scan_documents(self) -> tuple[list[Path], bool]:
        documents: list[Path] = []
        complete = True
        total_bytes = 0

        for relative_root, extensions in self._SOURCE_ROOTS:
            source_root = self.project_root / relative_root
            if source_root.is_symlink():
                logger.warning("Skipping symlink knowledge root", extra={"path": str(relative_root)})
                continue
            if not source_root.is_dir():
                continue

            errors: list[OSError] = []

            def record_walk_error(error: OSError) -> None:
                errors.append(error)

            for current_root, directory_names, file_names in os.walk(
                source_root, topdown=True, followlinks=False, onerror=record_walk_error
            ):
                current_path = Path(current_root)
                directory_names[:] = [
                    name for name in directory_names
                    if not name.startswith(".")
                    and name not in _IGNORED_DIRS
                    and not (current_path / name).is_symlink()
                ]
                for name in sorted(file_names, key=str.casefold):
                    if name.startswith("."):
                        continue
                    path = current_path / name
                    if path.is_symlink() or path.suffix.casefold() not in extensions:
                        continue
                    try:
                        path.resolve(strict=True).relative_to(self.project_root)
                    except (OSError, ValueError):
                        continue
                    documents.append(path)
                    if len(documents) >= _MAX_DOCUMENTS:
                        complete = False
                        break
                if len(documents) >= _MAX_DOCUMENTS:
                    break

            if errors:
                complete = False
                logger.warning("Knowledge scan was incomplete", extra={"root": str(relative_root)})

            if len(documents) >= _MAX_DOCUMENTS:
                break

        documents.sort(key=lambda path: path.relative_to(self.project_root).as_posix().casefold())
        bounded: list[Path] = []
        for path in documents:
            try:
                size = path.stat().st_size
            except OSError:
                complete = False
                continue
            if total_bytes + size > _MAX_TOTAL_BYTES:
                complete = False
                break
            bounded.append(path)
            total_bytes += size
        return bounded, complete

    @staticmethod
    def _document_title(relative_path: str, content: str) -> str:
        for line in content.splitlines():
            match = _HEADING_RE.match(line)
            if match:
                return match.group(1).strip()[:200] or Path(relative_path).stem
        return Path(relative_path).stem.replace("_", " ").replace("-", " ")

    def refresh_and_search(self, query: str, limit: int = 4) -> list[dict[str, str]]:
        """Refresh changed files and return relevant excerpts for an offline RAG prompt."""
        normalized_query = query.strip()[:500]
        if not normalized_query or limit <= 0:
            return []

        with self._lock:
            connection = self._connect()
            try:
                self._ensure_schema(connection)
                paths, scan_complete = self._scan_documents()
                seen_paths: set[str] = set()
                accepted_bytes = 0

                with connection:
                    for path in paths:
                        relative_path = path.relative_to(self.project_root).as_posix()
                        seen_paths.add(relative_path)
                        try:
                            before = path.stat()
                            if before.st_size > _MAX_FILE_BYTES:
                                connection.execute("DELETE FROM documents WHERE path = ?", (relative_path,))
                                continue
                            if accepted_bytes + before.st_size > _MAX_TOTAL_BYTES:
                                scan_complete = False
                                break

                            raw = path.read_bytes()
                            after = path.stat()
                        except OSError:
                            scan_complete = False
                            continue

                        if (
                            before.st_size != after.st_size
                            or before.st_mtime_ns != after.st_mtime_ns
                            or len(raw) != after.st_size
                        ):
                            # A file was being edited as it was read. Keep its cached
                            # version and retry on the next request.
                            scan_complete = False
                            continue

                        accepted_bytes += len(raw)
                        digest = hashlib.sha256(raw).hexdigest()
                        modified_at = _utc_timestamp(after.st_mtime)
                        current = connection.execute(
                            "SELECT digest, title FROM documents WHERE path = ?",
                            (relative_path,),
                        ).fetchone()
                        if current and current["digest"] == digest:
                            connection.execute(
                                "UPDATE documents SET modified_ns = ?, size_bytes = ?, modified_at = ? WHERE path = ?",
                                (after.st_mtime_ns, after.st_size, modified_at, relative_path),
                            )
                            continue

                        content = raw.decode("utf-8", errors="replace")
                        title = self._document_title(relative_path, content)
                        connection.execute("DELETE FROM documents WHERE path = ?", (relative_path,))
                        connection.execute(
                            """
                            INSERT INTO documents(path, title, digest, modified_ns, size_bytes, modified_at)
                            VALUES (?, ?, ?, ?, ?, ?)
                            """,
                            (relative_path, title, digest, after.st_mtime_ns, after.st_size, modified_at),
                        )
                        chunks = _split_markdown(content, title)
                        connection.executemany(
                            """
                            INSERT INTO chunks(path, chunk_index, heading, start_line, end_line, text)
                            VALUES (?, ?, ?, ?, ?, ?)
                            """,
                            [
                                (relative_path, index, heading, start, end, chunk)
                                for index, (start, end, heading, chunk) in enumerate(chunks)
                            ],
                        )

                    if scan_complete:
                        connection.executemany(
                            "DELETE FROM documents WHERE path = ?",
                            [
                                (row["path"],)
                                for row in connection.execute("SELECT path FROM documents").fetchall()
                                if row["path"] not in seen_paths
                            ],
                        )
                    checked_at = datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")
                    connection.execute(
                        """
                        INSERT INTO index_meta(key, value) VALUES ('last_checked_at', ?)
                        ON CONFLICT(key) DO UPDATE SET value = excluded.value
                        """,
                        (checked_at,),
                    )

                return self._search(connection, normalized_query, max(1, min(limit, 8)))
            finally:
                connection.close()

    def _search(
        self, connection: sqlite3.Connection, query: str, limit: int
    ) -> list[dict[str, str]]:
        rows = connection.execute(
            """
            SELECT c.path, d.title, d.modified_at, c.heading, c.start_line,
                   c.end_line, c.text, c.chunk_index
            FROM chunks AS c
            JOIN documents AS d ON d.path = c.path
            """
        ).fetchall()
        if not rows:
            return []

        query_terms = set(_expanded_tokens(_tokens(query)))
        if not query_terms:
            return []

        parsed: list[tuple[sqlite3.Row, list[str], Counter[str], set[str], set[str], set[str]]] = []
        document_frequency: Counter[str] = Counter()
        total_length = 0
        for row in rows:
            body_tokens = _expanded_tokens(_tokens(row["text"]))
            heading_tokens = set(_expanded_tokens(_tokens(row["heading"])))
            title_tokens = set(_expanded_tokens(_tokens(row["title"])))
            path_tokens = set(_expanded_tokens(_tokens(row["path"].replace("/", " "))))
            frequencies = Counter(body_tokens + list(heading_tokens) + list(title_tokens) + list(path_tokens))
            terms = set(frequencies)
            document_frequency.update(terms)
            total_length += max(1, len(body_tokens))
            parsed.append((row, body_tokens, frequencies, heading_tokens, title_tokens, path_tokens))

        count = len(parsed)
        average_length = max(1.0, total_length / count)
        ranked: list[tuple[float, sqlite3.Row]] = []
        for row, body_tokens, frequencies, heading_tokens, title_tokens, path_tokens in parsed:
            length = max(1, len(body_tokens))
            score = 0.0
            for term in query_terms:
                term_frequency = frequencies[term]
                if not term_frequency:
                    continue
                inverse_frequency = math.log(1 + (count - document_frequency[term] + 0.5) / (document_frequency[term] + 0.5))
                denominator = term_frequency + 1.2 * (0.25 + 0.75 * length / average_length)
                score += inverse_frequency * (term_frequency * 2.2 / denominator)
                if term in heading_tokens:
                    score += inverse_frequency * 1.25
                if term in title_tokens:
                    score += inverse_frequency * 1.5
                if term in path_tokens:
                    score += inverse_frequency * 0.5
            if score > 0:
                ranked.append((score, row))

        ranked.sort(key=lambda pair: (-pair[0], pair[1]["path"].casefold(), pair[1]["chunk_index"]))
        retrieved_at = datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")
        results: list[dict[str, str]] = []
        per_document: Counter[str] = Counter()
        for _, row in ranked:
            if per_document[row["path"]] >= _MAX_RESULTS_PER_DOCUMENT:
                continue
            per_document[row["path"]] += 1
            excerpt = row["text"].strip()[:_CHUNK_CHARS]
            if row["heading"] and row["heading"].casefold() not in excerpt.casefold():
                excerpt = f"{row['heading']}\n{excerpt}"[:_CHUNK_CHARS + 200]
            results.append(
                {
                    "title": row["title"],
                    "excerpt": excerpt,
                    "retrieved_at": retrieved_at,
                    "modified_at": row["modified_at"],
                    "path": row["path"],
                    "location": f"{row['start_line']}-{row['end_line']}",
                    "source_type": "course",
                }
            )
            if len(results) >= limit:
                break
        return results

    def status(self) -> dict[str, str | int | None]:
        """Return persisted index metadata without triggering a rescan."""
        if not self.database_path.exists():
            return {"document_count": 0, "last_checked_at": None}
        with self._lock:
            connection = sqlite3.connect(self.database_path, timeout=2)
            try:
                count = connection.execute("SELECT COUNT(*) FROM documents").fetchone()[0]
                checked = connection.execute(
                    "SELECT value FROM index_meta WHERE key = 'last_checked_at'"
                ).fetchone()
                return {
                    "document_count": int(count),
                    "last_checked_at": checked[0] if checked else None,
                }
            except sqlite3.Error:
                return {"document_count": 0, "last_checked_at": None}
            finally:
                connection.close()
