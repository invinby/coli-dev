from __future__ import annotations

from datetime import datetime, timedelta, timezone
from pathlib import Path

import pytest

from learning_progress import StudyProgressStore, default_database_path


def test_review_schedule_follows_quality_and_persists_across_instances(tmp_path: Path) -> None:
    now = [datetime(2026, 10, 5, 12, tzinfo=timezone.utc)]
    database = tmp_path / "user-data" / "learning.sqlite3"
    store = StudyProgressStore(database, clock=lambda: now[0])
    store.initialize()

    first = store.record_review("f47ac10b-58cc-4372-a567-0e02b2c3d479", "intro.physics", 4)
    assert first["completed"] is True
    assert first["repetitions"] == 1
    assert first["interval_days"] == 1
    assert first["due_at"] == "2026-10-06T12:00:00Z"

    now[0] += timedelta(days=1)
    second = store.record_review("f47ac10b-58cc-4372-a567-0e02b2c3d480", "intro.physics", 5)
    assert second["repetitions"] == 2
    assert second["interval_days"] == 6
    assert second["due_at"] == "2026-10-12T12:00:00Z"

    restored = StudyProgressStore(database, clock=lambda: now[0])
    progress = restored.get_progress()
    assert progress["records"] == [second]
    assert progress["due_count"] == 0
    assert progress["next_due_at"] == second["due_at"]

    now[0] += timedelta(days=6)
    assert restored.get_progress()["due_count"] == 1


def test_failed_recall_resets_repetitions_and_reduces_ease_factor(tmp_path: Path) -> None:
    now = [datetime(2026, 10, 5, tzinfo=timezone.utc)]
    store = StudyProgressStore(tmp_path / "progress.sqlite3", clock=lambda: now[0])
    store.initialize()
    store.record_review("f47ac10b-58cc-4372-a567-0e02b2c3d479", "intro.math", 5)
    now[0] += timedelta(days=1)
    result = store.record_review("f47ac10b-58cc-4372-a567-0e02b2c3d480", "intro.math", 1)

    assert result["completed"] is True
    assert result["repetitions"] == 0
    assert result["interval_days"] == 1
    assert result["ease_factor"] == 2.06
    assert result["due_at"] == "2026-10-07T00:00:00Z"


def test_review_event_replay_is_idempotent_and_payload_conflicts_are_rejected(tmp_path: Path) -> None:
    now = [datetime(2026, 10, 5, tzinfo=timezone.utc)]
    store = StudyProgressStore(tmp_path / "progress.sqlite3", clock=lambda: now[0])
    store.initialize()
    event_id = "f47ac10b-58cc-4372-a567-0e02b2c3d479"
    original = store.record_review(event_id, "intro.english", 4)
    now[0] += timedelta(hours=2)

    replay = store.record_review(event_id, "intro.english", 4)
    assert replay == original
    assert store.get_progress()["records"][0]["review_count"] == 1
    with pytest.raises(ValueError, match="different review"):
        store.record_review(event_id, "intro.physics", 4)
    with pytest.raises(ValueError, match="different review"):
        store.record_review(event_id, "intro.english", 3)


def test_learning_reflection_is_normalized_persisted_and_bound_to_idempotent_event(
    tmp_path: Path,
) -> None:
    database = tmp_path / "progress.sqlite3"
    store = StudyProgressStore(database)
    store.initialize()
    event_id = "f47ac10b-58cc-4372-a567-0e02b2c3d479"

    recorded = store.record_review(
        event_id, "physics.motion", 4, "  Acceleration changes velocity.\nI can explain the sign.  "
    )
    assert recorded["reflection"] == "Acceleration changes velocity. I can explain the sign."
    assert store.record_review(
        event_id, "physics.motion", 4, "Acceleration changes velocity. I can explain the sign."
    ) == recorded
    assert StudyProgressStore(database).get_progress()["records"][0]["reflection"] == recorded["reflection"]

    with pytest.raises(ValueError, match="different review"):
        store.record_review(event_id, "physics.motion", 4, "A different reflection")
    with pytest.raises(ValueError, match="500 characters"):
        store.record_review(
            "f47ac10b-58cc-4372-a567-0e02b2c3d480", "physics.motion", 4, "x" * 501
        )


def test_reflection_columns_migrate_existing_progress_database(tmp_path: Path) -> None:
    import sqlite3

    database = tmp_path / "legacy-progress.sqlite3"
    with sqlite3.connect(database) as connection:
        connection.executescript(
            """
            CREATE TABLE lesson_progress (
                lesson_id TEXT PRIMARY KEY, completed INTEGER NOT NULL DEFAULT 0,
                repetitions INTEGER NOT NULL DEFAULT 0, interval_days INTEGER NOT NULL DEFAULT 0,
                ease_factor REAL NOT NULL DEFAULT 2.5, review_count INTEGER NOT NULL DEFAULT 0,
                due_at TEXT, last_reviewed_at TEXT, updated_at TEXT NOT NULL
            );
            CREATE TABLE review_events (
                event_id TEXT PRIMARY KEY, lesson_id TEXT NOT NULL,
                quality INTEGER NOT NULL CHECK (quality BETWEEN 0 AND 5), created_at TEXT NOT NULL
            );
            INSERT INTO lesson_progress (lesson_id, completed, updated_at)
            VALUES ('intro.math', 1, '2026-10-05T00:00:00Z');
            """
        )

    store = StudyProgressStore(database)
    store.initialize()

    assert store.get_progress()["records"][0]["reflection"] == ""
    saved = store.record_review(
        "f47ac10b-58cc-4372-a567-0e02b2c3d479", "intro.math", 4, "Понял область значений"
    )
    assert saved["reflection"] == "Понял область значений"


@pytest.mark.parametrize(
    ("event_id", "lesson_id", "quality"),
    [
        ("not-a-uuid", "intro.physics", 4),
        ("f47ac10b-58cc-4372-a567-0e02b2c3d479", "", 4),
        ("f47ac10b-58cc-4372-a567-0e02b2c3d479", "intro.physics", True),
        ("f47ac10b-58cc-4372-a567-0e02b2c3d479", "intro.physics", 6),
    ],
)
def test_invalid_review_inputs_are_rejected(
    tmp_path: Path, event_id: str, lesson_id: str, quality: int
) -> None:
    store = StudyProgressStore(tmp_path / "progress.sqlite3")
    store.initialize()
    with pytest.raises(ValueError):
        store.record_review(event_id, lesson_id, quality)


def test_database_path_respects_user_data_directory_and_stays_out_of_repository(
    monkeypatch: pytest.MonkeyPatch, tmp_path: Path
) -> None:
    monkeypatch.setenv("COLIDEV_DATA_DIR", str(tmp_path / "private-data"))
    path = default_database_path()
    assert path == tmp_path / "private-data" / "learning-progress.sqlite3"
    assert ".git" not in path.parts


def test_database_path_uses_shared_app_data_and_preserves_existing_legacy_store(tmp_path: Path) -> None:
    new_path = tmp_path / "Library" / "Application Support" / "coli-dev" / "learning-progress.sqlite3"
    legacy_path = tmp_path / "Library" / "Application Support" / "ColiDev" / "learning-progress.sqlite3"

    assert default_database_path(platform="darwin", environ={}, home=tmp_path) == new_path

    legacy_path.parent.mkdir(parents=True)
    legacy_path.write_bytes(b"existing learner progress")
    assert default_database_path(platform="darwin", environ={}, home=tmp_path) == legacy_path
