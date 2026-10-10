"""Local SQLite-backed spaced-repetition progress for ColiDev lessons."""

from __future__ import annotations

import json
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
                    assessment_json TEXT NOT NULL DEFAULT '',
                    assessment_count INTEGER NOT NULL DEFAULT 0,
                    updated_at TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS review_events (
                    event_id TEXT PRIMARY KEY,
                    lesson_id TEXT NOT NULL,
                    quality INTEGER NOT NULL CHECK (quality BETWEEN 0 AND 5),
                    reflection TEXT NOT NULL DEFAULT '',
                    complete_lesson INTEGER,
                    assessment_json TEXT NOT NULL DEFAULT '',
                    created_at TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS assessment_events (
                    event_id TEXT PRIMARY KEY,
                    lesson_id TEXT NOT NULL,
                    task_type TEXT NOT NULL,
                    assessment_json TEXT NOT NULL,
                    created_at TEXT NOT NULL
                );
                CREATE INDEX IF NOT EXISTS lesson_progress_due_idx
                    ON lesson_progress (due_at);
                CREATE INDEX IF NOT EXISTS assessment_events_lesson_idx
                    ON assessment_events (lesson_id, created_at);
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
            for column, declaration in (
                ("assessment_json", "TEXT NOT NULL DEFAULT ''"),
                ("assessment_count", "INTEGER NOT NULL DEFAULT 0"),
            ):
                if column not in progress_columns:
                    connection.execute(
                        f"ALTER TABLE lesson_progress ADD COLUMN {column} {declaration}"
                    )
            if "assessment_json" not in review_columns:
                connection.execute(
                    "ALTER TABLE review_events ADD COLUMN assessment_json TEXT NOT NULL DEFAULT ''"
                )

    @staticmethod
    def _row(row: sqlite3.Row) -> dict[str, Any]:
        assessment_json = str(row["assessment_json"] or "")
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
            "assessment": json.loads(assessment_json) if assessment_json else None,
            "assessment_count": int(row["assessment_count"]),
            "updated_at": row["updated_at"],
        }

    @staticmethod
    def _assessment(value: Any) -> tuple[dict[str, Any] | None, str]:
        if value is None:
            return None, ""
        if not isinstance(value, Mapping):
            raise ValueError(
                "assessment must be an object or null / "
                "параметр assessment должен быть объектом или null"
            )
        required_fields = {"task_type", "attempts", "first_try_correct", "hints_used"}
        if not required_fields.issubset(value) or set(value) - required_fields - {"error_categories"}:
            raise ValueError(
                "assessment must contain task_type, attempts, first_try_correct, and hints_used / "
                "в assessment должны быть поля task_type, attempts, first_try_correct и hints_used"
            )
        if value["task_type"] != "knowledge_check":
            raise ValueError(
                "assessment task_type must be knowledge_check / "
                "поле task_type должно иметь значение knowledge_check"
            )
        attempts = value["attempts"]
        hints_used = value["hints_used"]
        first_try_correct = value["first_try_correct"]
        if isinstance(attempts, bool) or not isinstance(attempts, int) or not 1 <= attempts <= 1_000:
            raise ValueError(
                "assessment attempts must be an integer between 1 and 1000 / "
                "attempts должен быть целым числом от 1 до 1000"
            )
        if isinstance(hints_used, bool) or not isinstance(hints_used, int) or not 0 <= hints_used <= 1_000:
            raise ValueError(
                "assessment hints_used must be an integer between 0 and 1000 / "
                "hints_used должен быть целым числом от 0 до 1000"
            )
        if not isinstance(first_try_correct, bool) or first_try_correct != (attempts == 1):
            raise ValueError(
                "assessment first_try_correct must match the successful attempt count / "
                "first_try_correct должен соответствовать числу попыток до правильного ответа"
            )
        error_categories = value.get("error_categories", [])
        supported_error_categories = {
            "understanding", "memory", "application", "attention", "logic", "foundation", "method"
        }
        if (
            not isinstance(error_categories, list)
            or len(error_categories) > attempts - 1
            or any(
                not isinstance(category, str) or category not in supported_error_categories
                for category in error_categories
            )
        ):
            raise ValueError(
                "assessment error_categories must contain supported self-reported categories "
                "for incorrect attempts / error_categories должны содержать допустимые категории "
                "самооценки для ошибочных попыток"
            )
        normalized = {
            "task_type": "knowledge_check",
            "attempts": attempts,
            "first_try_correct": first_try_correct,
            "hints_used": hints_used,
        }
        if error_categories:
            normalized["error_categories"] = error_categories
        encoded = json.dumps(normalized, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
        return normalized, encoded

    @staticmethod
    def _assessment_event(value: Any) -> tuple[dict[str, Any], str]:
        if not isinstance(value, Mapping):
            raise ValueError("assessment must be an object")
        task_type = value.get("task_type")
        if task_type == "interactive_prediction":
            if set(value) != {"task_type", "attempts", "first_try_correct", "hints_used"}:
                raise ValueError("assessment must contain exactly the supported evidence fields")
            attempts = value["attempts"]
            hints_used = value["hints_used"]
            first_try_correct = value["first_try_correct"]
            if isinstance(attempts, bool) or not isinstance(attempts, int) or not 1 <= attempts <= 1_000:
                raise ValueError("assessment attempts must be an integer between 1 and 1000")
            if isinstance(hints_used, bool) or not isinstance(hints_used, int) or not 0 <= hints_used <= 1_000:
                raise ValueError("assessment hints_used must be an integer between 0 and 1000")
            if not isinstance(first_try_correct, bool):
                raise ValueError("assessment first_try_correct must be a boolean")
            normalized = {
                "task_type": "interactive_prediction",
                "attempts": attempts,
                "first_try_correct": first_try_correct,
                "hints_used": hints_used,
            }
        elif task_type == "knowledge_check":
            required_fields = {"task_type", "passed"}
            if not required_fields.issubset(value) or set(value) - required_fields - {"error_categories"}:
                raise ValueError("knowledge-check event must include only task_type, passed, and error_categories")
            passed = value["passed"]
            error_categories = value.get("error_categories", [])
            supported_error_categories = {
                "understanding", "memory", "application", "attention", "logic", "foundation", "method"
            }
            if not isinstance(passed, bool):
                raise ValueError("knowledge-check event passed must be a boolean")
            if (
                not isinstance(error_categories, list)
                or len(error_categories) > 1
                or any(
                    not isinstance(category, str) or category not in supported_error_categories
                    for category in error_categories
                )
                or (passed and error_categories)
            ):
                raise ValueError("knowledge-check error_categories must describe at most one failed attempt")
            normalized = {"task_type": "knowledge_check", "passed": passed}
            if error_categories:
                normalized["error_categories"] = error_categories
        else:
            raise ValueError("assessment task_type must be interactive_prediction or knowledge_check")
        encoded = json.dumps(normalized, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
        return normalized, encoded

    @staticmethod
    def _assessment_event_row(row: sqlite3.Row) -> dict[str, Any]:
        return {
            "event_id": str(row["event_id"]),
            "lesson_id": str(row["lesson_id"]),
            "assessment": json.loads(str(row["assessment_json"])),
            "created_at": str(row["created_at"]),
        }

    def record_assessment_event(
        self, event_id: str, lesson_id: str, assessment: Mapping[str, Any]
    ) -> dict[str, Any]:
        """Store interactive evidence without changing lesson completion or review scheduling."""
        try:
            normalized_event_id = str(uuid.UUID(event_id))
        except (ValueError, TypeError, AttributeError):
            raise ValueError("event_id must be a UUID") from None
        if not isinstance(lesson_id, str) or not re.fullmatch(
            r"[A-Za-z0-9][A-Za-z0-9._:-]{0,119}", lesson_id
        ):
            raise ValueError("lesson_id must be a safe identifier between 1 and 120 characters")
        normalized_assessment, assessment_json = self._assessment_event(assessment)
        now_text = _timestamp(self._clock())

        with self._connect() as connection:
            connection.execute("BEGIN IMMEDIATE")
            prior = connection.execute(
                "SELECT * FROM assessment_events WHERE event_id = ?",
                (normalized_event_id,),
            ).fetchone()
            if prior is not None:
                if (
                    str(prior["lesson_id"]) != lesson_id
                    or str(prior["assessment_json"]) != assessment_json
                ):
                    raise ValueError("event_id was already used for a different assessment")
                return self._assessment_event_row(prior)

            connection.execute(
                "INSERT INTO assessment_events "
                "(event_id, lesson_id, task_type, assessment_json, created_at) "
                "VALUES (?, ?, ?, ?, ?)",
                (
                    normalized_event_id,
                    lesson_id,
                    normalized_assessment["task_type"],
                    assessment_json,
                    now_text,
                ),
            )
            row = connection.execute(
                "SELECT * FROM assessment_events WHERE event_id = ?",
                (normalized_event_id,),
            ).fetchone()
            return self._assessment_event_row(row)

    @staticmethod
    def _assessment_event_backup(record: Any) -> dict[str, Any]:
        if not isinstance(record, dict):
            raise ValueError("Each assessment backup entry must be an object")
        try:
            event_id = str(uuid.UUID(record.get("event_id")))
        except (ValueError, TypeError, AttributeError):
            raise ValueError("Assessment backup contains an invalid event_id") from None
        lesson_id = record.get("lesson_id")
        if not isinstance(lesson_id, str) or not re.fullmatch(
            r"[A-Za-z0-9][A-Za-z0-9._:-]{0,119}", lesson_id
        ):
            raise ValueError("Assessment backup contains an invalid lesson_id")
        assessment, assessment_json = StudyProgressStore._assessment_event(
            record.get("assessment")
        )
        created_at = record.get("created_at")
        if not isinstance(created_at, str):
            raise ValueError("Assessment backup contains an invalid created_at")
        try:
            parsed = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
        except ValueError:
            raise ValueError("Assessment backup contains an invalid created_at") from None
        if parsed.tzinfo is None:
            raise ValueError("Assessment backup contains an invalid created_at")
        return {
            "event_id": event_id,
            "lesson_id": lesson_id,
            "task_type": assessment["task_type"],
            "assessment_json": assessment_json,
            "created_at": _timestamp(parsed),
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
        assessment: Mapping[str, Any] | None = None,
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
        normalized_assessment, assessment_json = self._assessment(assessment)

        now = self._clock().astimezone(timezone.utc).replace(microsecond=0)
        now_text = _timestamp(now)
        with self._connect() as connection:
            connection.execute("BEGIN IMMEDIATE")
            prior_event = connection.execute(
                "SELECT lesson_id, quality, reflection, complete_lesson, assessment_json "
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
                    or str(prior_event["assessment_json"] or "") != assessment_json
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
                       review_count, last_quality, due_at, last_reviewed_at, reflection,
                       assessment_json, assessment_count, updated_at
                   ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
                       assessment_json = CASE WHEN excluded.assessment_json = ''
                           THEN lesson_progress.assessment_json ELSE excluded.assessment_json END,
                       assessment_count = lesson_progress.assessment_count +
                           CASE WHEN excluded.assessment_json = '' THEN 0 ELSE 1 END,
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
                    assessment_json,
                    int(normalized_assessment is not None),
                    now_text,
                ),
            )
            connection.execute(
                "INSERT INTO review_events "
                "(event_id, lesson_id, quality, reflection, complete_lesson, assessment_json, created_at) "
                "VALUES (?, ?, ?, ?, ?, ?, ?)",
                (
                    normalized_event_id,
                    lesson_id,
                    quality,
                    normalized_reflection,
                    None if complete_lesson is None else int(complete_lesson),
                    assessment_json,
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
            event_groups = connection.execute(
                """SELECT lesson_id, task_type, COUNT(*) AS task_count
                   FROM assessment_events GROUP BY lesson_id, task_type
                   ORDER BY lesson_id, task_type"""
            ).fetchall()
            passed_event_rows = connection.execute(
                "SELECT lesson_id, task_type, assessment_json FROM assessment_events "
                "WHERE task_type = 'knowledge_check'"
            ).fetchall()
            latest_events = {
                lesson_id: connection.execute(
                    "SELECT * FROM assessment_events WHERE lesson_id = ? "
                    "ORDER BY created_at DESC, rowid DESC LIMIT 1",
                    (lesson_id,),
                ).fetchone()
                for lesson_id in {str(row["lesson_id"]) for row in event_groups}
            }
        records = [self._row(row) for row in rows]
        task_counts: dict[str, dict[str, int]] = {}
        passed_task_counts: dict[str, dict[str, int]] = {}
        error_category_counts: dict[str, dict[str, int]] = {}
        totals: dict[str, int] = {}
        for row in event_groups:
            lesson_id = str(row["lesson_id"])
            task_type = str(row["task_type"])
            task_count = int(row["task_count"])
            task_counts.setdefault(lesson_id, {})[task_type] = task_count
            totals[lesson_id] = totals.get(lesson_id, 0) + task_count
        for row in passed_event_rows:
            lesson_id = str(row["lesson_id"])
            task_type = str(row["task_type"])
            assessment = json.loads(str(row["assessment_json"]))
            if assessment.get("passed") is True:
                passed_task_counts.setdefault(lesson_id, {})[task_type] = (
                    passed_task_counts.get(lesson_id, {}).get(task_type, 0) + 1
                )
            for category in assessment.get("error_categories", []):
                error_category_counts.setdefault(lesson_id, {})[category] = (
                    error_category_counts.get(lesson_id, {}).get(category, 0) + 1
                )
        assessment_evidence = [
            {
                "lesson_id": lesson_id,
                "assessment_count": totals[lesson_id],
                "task_type_counts": task_counts[lesson_id],
                "passed_task_type_counts": passed_task_counts.get(lesson_id, {}),
                "error_category_counts": error_category_counts.get(lesson_id, {}),
                "latest_assessment": self._assessment_event_row(latest_events[lesson_id])["assessment"],
                "latest_at": self._assessment_event_row(latest_events[lesson_id])["created_at"],
            }
            for lesson_id in sorted(latest_events)
        ]
        due = [record for record in records if record["due_at"] and _parse_timestamp(record["due_at"]) <= now]
        next_due = min((record["due_at"] for record in records if record["due_at"]), default=None)
        return {
            "records": records,
            "assessment_evidence": assessment_evidence,
            "due_count": len(due),
            "next_due_at": next_due,
            "generated_at": now_text,
        }

    def export_backup(self) -> dict[str, Any]:
        """Export portable lesson state and typed assessment evidence."""
        with self._connect() as connection:
            rows = connection.execute(
                "SELECT * FROM lesson_progress ORDER BY lesson_id"
            ).fetchall()
            assessment_rows = connection.execute(
                "SELECT * FROM assessment_events ORDER BY created_at, rowid"
            ).fetchall()
        return {
            "format": "colidev-learning-progress",
            "version": 2,
            "records": [self._row(row) for row in rows],
            "assessment_events": [self._assessment_event_row(row) for row in assessment_rows],
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
        assessment, assessment_json = StudyProgressStore._assessment(record.get("assessment"))
        assessment_count = integer("assessment_count") if "assessment_count" in record else 0
        if assessment is not None and assessment_count == 0:
            raise ValueError("Backup contains an invalid assessment_count")

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
            "assessment": assessment,
            "assessment_json": assessment_json,
            "assessment_count": assessment_count,
            "updated_at": timestamp("updated_at"),
        }

    def restore_backup(self, payload: Any) -> dict[str, int]:
        """Merge validated records, choosing the newer state for each lesson."""
        if not isinstance(payload, dict) or payload.get("format") != "colidev-learning-progress":
            raise ValueError("Unsupported learning progress backup")
        version = payload.get("version")
        if type(version) is not int or version not in {1, 2}:
            raise ValueError("Unsupported learning progress backup version")
        records = payload.get("records")
        if not isinstance(records, list) or len(records) > 500:
            raise ValueError("Backup must contain no more than 500 progress records")
        normalized = [self._backup_record(record) for record in records]
        lesson_ids = [record["lesson_id"] for record in normalized]
        if len(lesson_ids) != len(set(lesson_ids)):
            raise ValueError("Backup contains duplicate lesson identifiers")
        assessment_events_payload = payload.get("assessment_events", [])
        if version == 1 and assessment_events_payload:
            raise ValueError("Version 1 backup cannot contain assessment events")
        if not isinstance(assessment_events_payload, list) or len(assessment_events_payload) > 5_000:
            raise ValueError("Backup must contain no more than 5000 assessment events")
        normalized_assessment_events = [
            self._assessment_event_backup(record) for record in assessment_events_payload
        ]
        event_ids = [record["event_id"] for record in normalized_assessment_events]
        if len(event_ids) != len(set(event_ids)):
            raise ValueError("Backup contains duplicate assessment event identifiers")

        restored = 0
        unchanged = 0
        assessments_restored = 0
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
                           review_count, last_quality, due_at, last_reviewed_at, reflection,
                           assessment_json, assessment_count, updated_at
                       ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
                           assessment_json = excluded.assessment_json,
                           assessment_count = excluded.assessment_count,
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
                        record["assessment_json"],
                        record["assessment_count"],
                        record["updated_at"],
                    ),
                )
                restored += 1
            for event in normalized_assessment_events:
                existing = connection.execute(
                    "SELECT * FROM assessment_events WHERE event_id = ?",
                    (event["event_id"],),
                ).fetchone()
                if existing is not None:
                    if (
                        str(existing["lesson_id"]) != event["lesson_id"]
                        or str(existing["assessment_json"]) != event["assessment_json"]
                        or str(existing["created_at"]) != event["created_at"]
                    ):
                        raise ValueError("Assessment event ID conflicts with existing local evidence")
                    continue
                connection.execute(
                    "INSERT INTO assessment_events "
                    "(event_id, lesson_id, task_type, assessment_json, created_at) "
                    "VALUES (?, ?, ?, ?, ?)",
                    (
                        event["event_id"],
                        event["lesson_id"],
                        event["task_type"],
                        event["assessment_json"],
                        event["created_at"],
                    ),
                )
                assessments_restored += 1
        result = {"restored": restored, "unchanged": unchanged}
        if assessments_restored:
            result["assessments_restored"] = assessments_restored
        return result
