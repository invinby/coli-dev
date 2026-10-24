from __future__ import annotations

import re
import sqlite3
from pathlib import Path

import pytest


LESSON = (
    Path(__file__).resolve().parents[1]
    / "02_Areas"
    / "Programming"
    / "lessons"
    / "sql_transactions.md"
)


def test_bilingual_sql_schema_query_and_index_examples_work_in_sqlite() -> None:
    markdown = LESSON.read_text(encoding="utf-8")
    sql_blocks = re.findall(r"```sql\s*\n(.*?)\n```", markdown, re.DOTALL)
    schema = next(block for block in sql_blocks if block.lstrip().startswith("CREATE TABLE study_sessions"))
    query = next(block for block in sql_blocks if block.lstrip().startswith("SELECT topic, minutes"))
    index = next(block for block in sql_blocks if block.lstrip().startswith("CREATE INDEX idx_study_sessions_minutes"))
    assert markdown.count(schema) == 2
    assert markdown.count(query) == 2
    assert markdown.count(index) == 2

    connection = sqlite3.connect(":memory:")
    try:
        connection.executescript(schema)
        connection.executemany(
            "INSERT INTO study_sessions (id, topic, minutes) VALUES (?, ?, ?)",
            [(1, "algorithms", 15), (2, "while", 35), (3, "SQLite", 50), (4, "Git", 20)],
        )
        before_index = connection.execute(query).fetchall()
        assert before_index == [("SQLite", 50), ("while", 35)]

        with pytest.raises(sqlite3.IntegrityError):
            connection.execute(
                "INSERT INTO study_sessions (id, topic, minutes) VALUES (?, ?, ?)",
                (5, "negative", -1),
            )
        with pytest.raises(sqlite3.IntegrityError):
            connection.execute(
                "INSERT INTO study_sessions (id, topic, minutes) VALUES (?, ?, ?)",
                (6, None, 10),
            )

        connection.execute(index)
        after_index = connection.execute(query).fetchall()
        assert after_index == before_index
        indexes = connection.execute(
            "SELECT name FROM sqlite_master WHERE type = 'index' AND name = ?",
            ("idx_study_sessions_minutes",),
        ).fetchall()
        assert indexes == [("idx_study_sessions_minutes",)]
    finally:
        connection.close()
