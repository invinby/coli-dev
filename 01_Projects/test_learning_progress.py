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
    assert first["last_quality"] == 4
    assert first["due_at"] == "2026-10-06T12:00:00Z"

    now[0] += timedelta(days=1)
    second = store.record_review("f47ac10b-58cc-4372-a567-0e02b2c3d480", "intro.physics", 5)
    assert second["repetitions"] == 2
    assert second["interval_days"] == 6
    assert second["last_quality"] == 5
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


def test_explicit_completion_is_independent_of_recall_quality(tmp_path: Path) -> None:
    store = StudyProgressStore(tmp_path / "progress.sqlite3")
    store.initialize()

    completed = store.record_review(
        "f47ac10b-58cc-4372-a567-0e02b2c3d481",
        "physics.motion",
        2,
        complete_lesson=True,
    )
    not_completed = store.record_review(
        "f47ac10b-58cc-4372-a567-0e02b2c3d482",
        "biology.osmosis",
        5,
        complete_lesson=False,
    )

    assert completed["completed"] is True
    assert completed["repetitions"] == 0
    assert completed["interval_days"] == 1
    assert not_completed["completed"] is False
    assert not_completed["repetitions"] == 1
    assert not_completed["interval_days"] == 1


def test_explicit_completion_intent_is_part_of_idempotent_event_payload(
    tmp_path: Path,
) -> None:
    store = StudyProgressStore(tmp_path / "progress.sqlite3")
    store.initialize()
    event_id = "f47ac10b-58cc-4372-a567-0e02b2c3d483"

    original = store.record_review(
        event_id, "physics.motion", 2, complete_lesson=True
    )
    assert store.record_review(
        event_id, "physics.motion", 2, complete_lesson=True
    ) == original
    with pytest.raises(ValueError, match="different review"):
        store.record_review(event_id, "physics.motion", 2, complete_lesson=False)


def test_assessment_evidence_persists_attempts_and_is_part_of_idempotent_review(
    tmp_path: Path,
) -> None:
    store = StudyProgressStore(tmp_path / "progress.sqlite3")
    store.initialize()
    event_id = "f47ac10b-58cc-4372-a567-0e02b2c3d486"
    evidence = {
        "task_type": "knowledge_check",
        "attempts": 2,
        "first_try_correct": False,
        "hints_used": 0,
    }

    recorded = store.record_review(
        event_id, "mathematics.quadratics", 4, assessment=evidence
    )
    assert recorded["assessment"] == evidence
    assert recorded["assessment_count"] == 1
    assert store.record_review(
        event_id, "mathematics.quadratics", 4, assessment=evidence
    ) == recorded

    with pytest.raises(ValueError, match="different review"):
        store.record_review(
            event_id,
            "mathematics.quadratics",
            4,
            assessment={**evidence, "attempts": 1, "first_try_correct": True},
        )

    second = store.record_review(
        "f47ac10b-58cc-4372-a567-0e02b2c3d487",
        "mathematics.quadratics",
        5,
        assessment={**evidence, "attempts": 1, "first_try_correct": True},
    )
    assert second["assessment"]["attempts"] == 1
    assert second["assessment"]["first_try_correct"] is True
    assert second["assessment_count"] == 2
    assert StudyProgressStore(store.path).get_progress()["records"][0] == second


def test_interactive_assessments_are_idempotent_and_do_not_change_review_schedule(
    tmp_path: Path,
) -> None:
    now = [datetime(2026, 10, 8, 12, tzinfo=timezone.utc)]
    store = StudyProgressStore(tmp_path / "progress.sqlite3", clock=lambda: now[0])
    store.initialize()
    lesson_id = "zoology.comparative_thermoregulation_and_heat_stress"
    review = store.record_review(
        "f47ac10b-58cc-4372-a567-0e02b2c3d491", lesson_id, 5
    )
    evidence = {
        "task_type": "interactive_prediction",
        "attempts": 2,
        "first_try_correct": False,
        "hints_used": 0,
    }

    saved = store.record_assessment_event(
        "f47ac10b-58cc-4372-a567-0e02b2c3d492", lesson_id, evidence
    )
    assert saved["assessment"] == evidence
    assert store.record_assessment_event(
        "f47ac10b-58cc-4372-a567-0e02b2c3d492", lesson_id, evidence
    ) == saved
    now[0] += timedelta(minutes=1)
    second_evidence = {**evidence, "attempts": 3}
    store.record_assessment_event(
        "f47ac10b-58cc-4372-a567-0e02b2c3d496", lesson_id, second_evidence
    )
    with pytest.raises(ValueError, match="different assessment"):
        store.record_assessment_event(
            "f47ac10b-58cc-4372-a567-0e02b2c3d492",
            lesson_id,
            {**evidence, "attempts": 3},
        )

    progress = store.get_progress()
    assert progress["records"] == [review]
    assert progress["assessment_evidence"] == [{
        "lesson_id": lesson_id,
        "assessment_count": 2,
        "task_type_counts": {"interactive_prediction": 2},
        "latest_assessment": second_evidence,
        "latest_at": "2026-10-08T12:01:00Z",
    }]
    now[0] += timedelta(days=1)
    assert store.get_progress()["records"][0] == review


def test_interactive_assessment_can_record_an_incorrect_first_attempt(tmp_path: Path) -> None:
    store = StudyProgressStore(tmp_path / "progress.sqlite3")
    store.initialize()

    saved = store.record_assessment_event(
        "f47ac10b-58cc-4372-a567-0e02b2c3d493",
        "biology.photosynthesis_energy_and_carbon",
        {
            "task_type": "interactive_prediction",
            "attempts": 1,
            "first_try_correct": False,
            "hints_used": 0,
        },
    )

    assert saved["assessment"]["first_try_correct"] is False
    assert store.get_progress()["records"] == []


def test_learning_backup_round_trips_interactive_assessment_events(tmp_path: Path) -> None:
    original = StudyProgressStore(tmp_path / "original.sqlite3")
    original.initialize()
    original.record_assessment_event(
        "f47ac10b-58cc-4372-a567-0e02b2c3d494",
        "zoology.thermoregulation",
        {
            "task_type": "interactive_prediction",
            "attempts": 1,
            "first_try_correct": True,
            "hints_used": 0,
        },
    )

    backup = original.export_backup()
    assert backup["version"] == 2
    assert len(backup["assessment_events"]) == 1

    restored = StudyProgressStore(tmp_path / "restored.sqlite3")
    restored.initialize()
    assert restored.restore_backup(backup) == {"restored": 0, "unchanged": 0, "assessments_restored": 1}
    assert restored.get_progress()["assessment_evidence"] == original.get_progress()["assessment_evidence"]


@pytest.mark.parametrize(
    "assessment",
    [
        {"task_type": "guessing", "attempts": 1, "first_try_correct": True, "hints_used": 0},
        {"task_type": "knowledge_check", "attempts": True, "first_try_correct": True, "hints_used": 0},
        {"task_type": "knowledge_check", "attempts": 1_001, "first_try_correct": False, "hints_used": 0},
        {"task_type": "knowledge_check", "attempts": 1, "first_try_correct": False, "hints_used": 0},
        {"task_type": "knowledge_check", "attempts": 1, "first_try_correct": True, "hints_used": -1},
    ],
)
def test_invalid_assessment_evidence_is_rejected(tmp_path: Path, assessment: dict[str, object]) -> None:
    store = StudyProgressStore(tmp_path / "progress.sqlite3")
    store.initialize()

    with pytest.raises(ValueError, match="assessment"):
        store.record_review(
            "f47ac10b-58cc-4372-a567-0e02b2c3d489",
            "mathematics.quadratics",
            4,
            assessment=assessment,
        )
    assert store.get_progress()["records"] == []


def test_explicit_completion_intent_must_be_a_boolean_or_null(tmp_path: Path) -> None:
    store = StudyProgressStore(tmp_path / "progress.sqlite3")
    store.initialize()

    with pytest.raises(ValueError, match="boolean or null"):
        store.record_review(
            "f47ac10b-58cc-4372-a567-0e02b2c3d485",
            "physics.motion",
            4,
            complete_lesson=1,
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
            INSERT INTO review_events (event_id, lesson_id, quality, created_at)
            VALUES (
                'f47ac10b-58cc-4372-a567-0e02b2c3d484',
                'intro.math', 4, '2026-10-05T00:00:00Z'
            );
            """
        )

    store = StudyProgressStore(database)
    store.initialize()

    assert store.get_progress()["records"][0]["reflection"] == ""
    assert store.get_progress()["records"][0]["last_quality"] is None
    assert store.get_progress()["records"][0]["assessment"] is None
    assert store.get_progress()["records"][0]["assessment_count"] == 0
    assert store.record_review(
        "f47ac10b-58cc-4372-a567-0e02b2c3d484", "intro.math", 4
    )["review_count"] == 0
    saved = store.record_review(
        "f47ac10b-58cc-4372-a567-0e02b2c3d479", "intro.math", 4, "Понял область значений"
    )
    assert saved["reflection"] == "Понял область значений"


def test_progress_backup_roundtrips_current_state_and_keeps_newer_local_records(
    tmp_path: Path,
) -> None:
    original_time = datetime(2026, 10, 1, tzinfo=timezone.utc)
    original = StudyProgressStore(tmp_path / "original.sqlite3", clock=lambda: original_time)
    original.initialize()
    original.record_review(
        "f47ac10b-58cc-4372-a567-0e02b2c3d479",
        "physics.motion",
        4,
        "I understand acceleration",
        assessment={
            "task_type": "knowledge_check",
            "attempts": 1,
            "first_try_correct": True,
            "hints_used": 0,
        },
    )
    backup = original.export_backup()
    assert backup["format"] == "colidev-learning-progress"
    assert backup["version"] == 2
    assert backup["assessment_events"] == []
    assert len(backup["records"]) == 1
    assert backup["records"][0]["assessment"]["first_try_correct"] is True
    assert backup["records"][0]["assessment_count"] == 1

    restored_time = [original_time]
    restored = StudyProgressStore(
        tmp_path / "restored.sqlite3", clock=lambda: restored_time[0]
    )
    restored.initialize()
    assert restored.restore_backup(backup) == {"restored": 1, "unchanged": 0}
    assert restored.export_backup() == backup
    assert restored.restore_backup(backup) == {"restored": 0, "unchanged": 1}

    restored_time[0] = datetime(2026, 10, 4, tzinfo=timezone.utc)
    restored.record_review(
        "f47ac10b-58cc-4372-a567-0e02b2c3d480", "physics.motion", 5, "I can solve examples"
    )
    newer = restored.export_backup()
    assert newer["records"][0]["updated_at"] > backup["records"][0]["updated_at"]
    assert newer["records"][0]["assessment"] == backup["records"][0]["assessment"]
    assert newer["records"][0]["assessment_count"] == 1
    assert original.restore_backup(newer) == {"restored": 1, "unchanged": 0}
    assert original.export_backup() == newer


def test_progress_backup_validation_is_atomic_and_rejects_duplicates(tmp_path: Path) -> None:
    store = StudyProgressStore(tmp_path / "progress.sqlite3")
    store.initialize()
    valid = {
        "lesson_id": "biology.osmosis",
        "completed": True,
        "repetitions": 1,
        "interval_days": 1,
        "ease_factor": 2.5,
        "review_count": 1,
        "last_quality": 4,
        "due_at": "2026-10-07T00:00:00Z",
        "last_reviewed_at": "2026-10-06T00:00:00Z",
        "reflection": "I understand osmosis",
        "updated_at": "2026-10-06T00:00:00Z",
    }
    with pytest.raises(ValueError, match="invalid lesson identifier"):
        store.restore_backup({
            "format": "colidev-learning-progress",
            "version": 1,
            "records": [valid, {**valid, "lesson_id": "../outside"}],
        })
    with pytest.raises(ValueError, match="duplicate"):
        store.restore_backup({
            "format": "colidev-learning-progress",
            "version": 1,
            "records": [valid, valid],
        })
    with pytest.raises(ValueError, match="last_quality"):
        store.restore_backup({
            "format": "colidev-learning-progress",
            "version": 1,
            "records": [{**valid, "last_quality": 6}],
        })
    assert store.get_progress()["records"] == []


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
