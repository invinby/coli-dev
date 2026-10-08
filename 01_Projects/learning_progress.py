"""Local SQLite-backed spaced-repetition progress for ColiDev lessons."""

from __future__ import annotations

import math
import os
import re
import sqlite3
import sys
import uuid
from collections.abc import Mapping
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Callable, Any

from app_paths import app_data_dir


def default_database_path(
    *,
    platform: str | None = None,
    environ: Mapping[str, str] | None = None,
    home: Path | None = None,
) -> Path:
    """Return the shared per-user database path, preserving an existing legacy DB."""
    current_platform = sys.platform if platform is None else platform
    env = os.environ if environ is None else environ
    home_dir = Path.home() if home is None else Path(home)
    configured = env.get("COLIDEV_DATA_DIR", "").strip()
    if configured:
        return Path(configured).expanduser() / "learning-progress.sqlite3"

    current = app_data_dir(platform=current_platform, environ=env, home=home_dir) / "learning-progress.sqlite3"
    if current.exists():
        return current

    if current_platform == "darwin":
        legacy = home_dir / "Library" / "Application Support" / "ColiDev" / "learning-progress.sqlite3"
    elif current_platform == "win32":
        # The previous Windows path already matches app_data_dir().
        legacy = current
    else:
        legacy_data = env.get("XDG_DATA_HOME") or str(home_dir / ".local" / "share")
        legacy = Path(legacy_data).expanduser() / "colidev" / "learning-progress.sqlite3"
    return legacy if legacy != current and legacy.is_file() else current


def _timestamp(value: datetime) -> str:
    normalized = value.astimezone(timezone.utc).replace(microsecond=0)
    return normalized.isoformat().replace("+00:00", "Z")


def _parse_timestamp(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


class StudyProgressStore:
    """Persist lesson reviews and calculate SM-2-style next review dates."""

    def __init__(self, path: Path, clock: Callable[[], datetime] | None = None) -> None:
        self.path = Path(path)
        self._clock = clock or (lambda: datetime.now(timezone.utc))

    def _connect(self) -> sqlite3.Connection:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        connection = sqlite3.connect(self.path, timeout=5)
        connection.row_factory = sqlite3.Row
        connection.execute("PRAGMA foreign_keys = ON")
        return connection

    def initialize(self) -> None:
        with self._connect() as connection:
            connection.execute("PRAGMA journal_mode = WAL")
            connection.executescript(
                """
                CREATE TABLE IF NOT EXISTS lesson_progress (
                    lesson_id TEXT PRIMARY KEY,
                    completed INTEGER NOT NULL DEFAULT 0,
                    repetitions INTEGER NOT NULL DEFAULT 0,
                    interval_days INTEGER NOT NULL DEFAULT 0,
                    ease_factor REAL NOT NULL DEFAULT 2.5,
                    review_count INTEGER NOT NULL DEFAULT 0,
                    last_quality INTEGER CHECK (last_quality BETWEEN 0 AND 5),
                    due_at TEXT,
                    last_reviewed_at TEXT,
                    reflection TEXT NOT NULL DEFAULT '',
                    updated_at TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS review_events (
                    event_id TEXT PRIMARY KEY,
                    lesson_id TEXT NOT NULL,
                    quality INTEGER NOT NULL CHECK (quality BETWEEN 0 AND 5),
                    reflection TEXT NOT NULL DEFAULT '',
                    complete_lesson INTEGER,
                    created_at TEXT NOT NULL
                );
                CREATE INDEX IF NOT EXISTS lesson_progress_due_idx
                    ON lesson_progress (due_at);
                """
            )
            for table in ("lesson_progress", "review_events"):
                columns = {
                    str(row["name"])
                    for row in connection.execute(f"PRAGMA table_info({table})").fetchall()
                }
                if "reflection" not in columns:
                    connection.execute(
                        f"ALTER TABLE {table} ADD COLUMN reflection TEXT NOT NULL DEFAULT ''"
                    )
            progress_columns = {
                str(row["name"])
                for row in connection.execute("PRAGMA table_info(lesson_progress)").fetchall()
            }
            if "last_quality" not in progress_columns:
                connection.execute("ALTER TABLE lesson_progress ADD COLUMN last_quality INTEGER")
            review_columns = {
                str(row["name"])
                for row in connection.execute("PRAGMA table_info(review_events)").fetchall()
            }
            if "complete_lesson" not in review_columns:
                connection.execute(
                    "ALTER TABLE review_events ADD COLUMN complete_lesson INTEGER"
                )

    @staticmethod
    def _row(row: sqlite3.Row) -> dict[str, Any]:
        return {
            "lesson_id": row["lesson_id"],
            "completed": bool(row["completed"]),
            "repetitions": int(row["repetitions"]),
            "interval_days": int(row["interval_days"]),
            "ease_factor": round(float(row["ease_factor"]), 2),
            "review_count": int(row["review_count"]),
            "last_quality": row["last_quality"],
            "due_at": row["due_at"],
            "last_reviewed_at": row["last_reviewed_at"],
            "reflection": str(row["reflection"] or ""),
            "updated_at": row["updated_at"],
        }

    @staticmethod
    def _calculate_schedule(
        repetitions: int,
        interval_days: int,
        ease_factor: float,
        quality: int,
    ) -> tuple[int, int, float]:
        # SM-2 grades below 3 mean the learner could not recall the material.
        if quality < 3:
            repetitions = 0
            interval_days = 1
        elif repetitions == 0:
            interval_days = 1
            repetitions = 1
        elif repetitions == 1:
            interval_days = 6
            repetitions = 2
        else:
            interval_days = max(1, round(interval_days * ease_factor))
            repetitions += 1

        penalty = 5 - quality
        ease_factor = max(
            1.3,
            ease_factor + 0.1 - penalty * (0.08 + penalty * 0.02),
        )
        return repetitions, interval_days, ease_factor

    def record_review(
        self,
        event_id: str,
        lesson_id: str,
        quality: int,
        reflection: str = "",
        complete_lesson: bool | None = None,
    ) -> dict[str, Any]:
        try:
            normalized_event_id = str(uuid.UUID(event_id))
        except (ValueError, TypeError, AttributeError):
            raise ValueError("event_id must be a UUID") from None
        if not isinstance(lesson_id, str) or not lesson_id.strip() or len(lesson_id) > 120:
            raise ValueError("lesson_id must contain between 1 and 120 characters")
        if isinstance(quality, bool) or not isinstance(quality, int) or not 0 <= quality <= 5:
            raise ValueError("quality must be an integer between 0 and 5")
        if not isinstance(reflection, str) or len(reflection) > 500:
            raise ValueError("reflection must be text no longer than 500 characters")
        if complete_lesson is not None and not isinstance(complete_lesson, bool):
            raise ValueError("complete_lesson must be a boolean or null")
        normalized_reflection = " ".join(reflection.split())

        now = self._clock().astimezone(timezone.utc).replace(microsecond=0)
        now_text = _timestamp(now)
        with self._connect() as connection:
            connection.execute("BEGIN IMMEDIATE")
            prior_event = connection.execute(
                "SELECT lesson_id, quality, reflection, complete_lesson "
                "FROM review_events WHERE event_id = ?",
                (normalized_event_id,),
            ).fetchone()
            if prior_event is not None:
                if (
                    prior_event["lesson_id"] != lesson_id
                    or int(prior_event["quality"]) != quality
                    or str(prior_event["reflection"] or "") != normalized_reflection
                    or (
                        bool(prior_event["complete_lesson"])
                        if prior_event["complete_lesson"] is not None
                        else None
                    )
                    != complete_lesson
                ):
                    raise ValueError("event_id was already used for a different review")
                row = connection.execute(
                    "SELECT * FROM lesson_progress WHERE lesson_id = ?", (lesson_id,)
                ).fetchone()
                if row is None:
                    raise RuntimeError("review event exists without lesson progress")
                return self._row(row)

            previous = connection.execute(
                "SELECT * FROM lesson_progress WHERE lesson_id = ?", (lesson_id,)
            ).fetchone()
            repetitions = int(previous["repetitions"]) if previous else 0
            interval_days = int(previous["interval_days"]) if previous else 0
            ease_factor = float(previous["ease_factor"]) if previous else 2.5
            review_count = int(previous["review_count"]) if previous else 0
            was_completed = bool(previous["completed"]) if previous else False

            repetitions, interval_days, ease_factor = self._calculate_schedule(
                repetitions, interval_days, ease_factor, quality
            )
            due_text = _timestamp(now + timedelta(days=interval_days))
            completion_requested = (
                quality >= 3 if complete_lesson is None else complete_lesson
            )
            completed = was_completed or completion_requested
            connection.execute(
                """INSERT INTO lesson_progress (
                       lesson_id, completed, repetitions, interval_days, ease_factor,
                       review_count, last_quality, due_at, last_reviewed_at, reflection, updated_at
                   ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                   ON CONFLICT(lesson_id) DO UPDATE SET
                       completed = excluded.completed,
                       repetitions = excluded.repetitions,
                       interval_days = excluded.interval_days,
                       ease_factor = excluded.ease_factor,
                       review_count = excluded.review_count,
                       last_quality = excluded.last_quality,
                       due_at = excluded.due_at,
                       last_reviewed_at = excluded.last_reviewed_at,
                       reflection = excluded.reflection,
                       updated_at = excluded.updated_at""",
                (
                    lesson_id,
                    int(completed),
                    repetitions,
                    interval_days,
                    ease_factor,
                    review_count + 1,
                    quality,
                    due_text,
                    now_text,
                    normalized_reflection,
                    now_text,
                ),
            )
            connection.execute(
                "INSERT INTO review_events "
                "(event_id, lesson_id, quality, reflection, complete_lesson, created_at) "
                "VALUES (?, ?, ?, ?, ?, ?)",
                (
                    normalized_event_id,
                    lesson_id,
                    quality,
                    normalized_reflection,
                    None if complete_lesson is None else int(complete_lesson),
                    now_text,
                ),
            )
            row = connection.execute(
                "SELECT * FROM lesson_progress WHERE lesson_id = ?", (lesson_id,)
            ).fetchone()
            return self._row(row)

    def get_progress(self) -> dict[str, Any]:
        now = self._clock().astimezone(timezone.utc).replace(microsecond=0)
        now_text = _timestamp(now)
        with self._connect() as connection:
            rows = connection.execute(
                "SELECT * FROM lesson_progress ORDER BY due_at IS NULL, due_at, lesson_id"
            ).fetchall()
        records = [self._row(row) for row in rows]
        due = [record for record in records if record["due_at"] and _parse_timestamp(record["due_at"]) <= now]
        next_due = min((record["due_at"] for record in records if record["due_at"]), default=None)
        return {
            "records": records,
            "due_count": len(due),
            "next_due_at": next_due,
            "generated_at": now_text,
        }

    def export_backup(self) -> dict[str, Any]:
        """Export portable current lesson state without private review-event history."""
        with self._connect() as connection:
            rows = connection.execute(
                "SELECT * FROM lesson_progress ORDER BY lesson_id"
            ).fetchall()
        return {
            "format": "colidev-learning-progress",
            "version": 1,
            "records": [self._row(row) for row in rows],
        }

    @staticmethod
    def _backup_record(record: Any) -> dict[str, Any]:
        if not isinstance(record, dict):
            raise ValueError("Each backup record must be an object")
        lesson_id = record.get("lesson_id")
        if not isinstance(lesson_id, str) or not re.fullmatch(
            r"[A-Za-z0-9][A-Za-z0-9._:-]{0,119}", lesson_id
        ):
            raise ValueError("Backup contains an invalid lesson identifier")

        def integer(name: str, maximum: int = 1_000_000) -> int:
            value = record.get(name)
            if isinstance(value, bool) or not isinstance(value, int) or not 0 <= value <= maximum:
                raise ValueError(f"Backup contains an invalid {name}")
            return value

        def timestamp(name: str, optional: bool = False) -> str | None:
            value = record.get(name)
            if value is None and optional:
                return None
            if not isinstance(value, str):
                raise ValueError(f"Backup contains an invalid {name}")
            try:
                parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
            except ValueError:
                raise ValueError(f"Backup contains an invalid {name}") from None
            if parsed.tzinfo is None:
                raise ValueError(f"Backup contains an invalid {name}")
            return _timestamp(parsed)

        completed = record.get("completed")
        if not isinstance(completed, bool):
            raise ValueError("Backup contains an invalid completed flag")
        ease_factor = record.get("ease_factor")
        if (
            isinstance(ease_factor, bool)
            or not isinstance(ease_factor, (int, float))
            or not math.isfinite(ease_factor)
            or not 1.3 <= ease_factor <= 10
        ):
            raise ValueError("Backup contains an invalid ease_factor")
        reflection = record.get("reflection", "")
        if not isinstance(reflection, str) or len(reflection) > 500:
            raise ValueError("Backup contains an invalid reflection")
        last_quality = record.get("last_quality")
        if last_quality is not None and (
            isinstance(last_quality, bool)
            or not isinstance(last_quality, int)
            or not 0 <= last_quality <= 5
        ):
            raise ValueError("Backup contains an invalid last_quality")

        return {
            "lesson_id": lesson_id,
            "completed": completed,
            "repetitions": integer("repetitions"),
            "interval_days": integer("interval_days"),
            "ease_factor": round(float(ease_factor), 2),
            "review_count": integer("review_count"),
            "last_quality": last_quality,
            "due_at": timestamp("due_at", optional=True),
            "last_reviewed_at": timestamp("last_reviewed_at", optional=True),
            "reflection": " ".join(reflection.split()),
            "updated_at": timestamp("updated_at"),
        }

    def restore_backup(self, payload: Any) -> dict[str, int]:
        """Merge validated records, choosing the newer state for each lesson."""
        if not isinstance(payload, dict) or payload.get("format") != "colidev-learning-progress":
            raise ValueError("Unsupported learning progress backup")
        if type(payload.get("version")) is not int or payload["version"] != 1:
            raise ValueError("Unsupported learning progress backup version")
        records = payload.get("records")
        if not isinstance(records, list) or len(records) > 500:
            raise ValueError("Backup must contain no more than 500 progress records")
        normalized = [self._backup_record(record) for record in records]
        lesson_ids = [record["lesson_id"] for record in normalized]
        if len(lesson_ids) != len(set(lesson_ids)):
            raise ValueError("Backup contains duplicate lesson identifiers")

        restored = 0
        unchanged = 0
        with self._connect() as connection:
            connection.execute("BEGIN IMMEDIATE")
            for record in normalized:
                existing = connection.execute(
                    "SELECT updated_at FROM lesson_progress WHERE lesson_id = ?",
                    (record["lesson_id"],),
                ).fetchone()
                if existing is not None and existing["updated_at"] >= record["updated_at"]:
                    unchanged += 1
                    continue
                connection.execute(
                    """INSERT INTO lesson_progress (
                           lesson_id, completed, repetitions, interval_days, ease_factor,
                           review_count, last_quality, due_at, last_reviewed_at, reflection, updated_at
                       ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                       ON CONFLICT(lesson_id) DO UPDATE SET
                           completed = excluded.completed,
                           repetitions = excluded.repetitions,
                           interval_days = excluded.interval_days,
                           ease_factor = excluded.ease_factor,
                           review_count = excluded.review_count,
                           last_quality = excluded.last_quality,
                           due_at = excluded.due_at,
                           last_reviewed_at = excluded.last_reviewed_at,
                           reflection = excluded.reflection,
                           updated_at = excluded.updated_at""",
                    (
                        record["lesson_id"],
                        int(record["completed"]),
                        record["repetitions"],
                        record["interval_days"],
                        record["ease_factor"],
                        record["review_count"],
                        record["last_quality"],
                        record["due_at"],
                        record["last_reviewed_at"],
                        record["reflection"],
                        record["updated_at"],
                    ),
                )
                restored += 1
        return {"restored": restored, "unchanged": unchanged}
