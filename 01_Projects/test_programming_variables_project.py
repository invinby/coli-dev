from __future__ import annotations

import os
import re
import subprocess
import sys
from pathlib import Path

PROJECTS = Path(__file__).resolve().parent
sys.path.insert(0, str(PROJECTS))

from python_practice import execute_python_practice


LESSON = (
    Path(__file__).resolve().parents[1]
    / "02_Areas"
    / "Programming"
    / "lessons"
    / "variables_and_types.md"
)


def _project_code(language: str) -> str:
    markdown = LESSON.read_text(encoding="utf-8")
    if language == "ru":
        start_heading = "### Мини-проект: учёт минут практики"
        end_heading = "### Вопрос"
    elif language == "en":
        start_heading = "### Mini-project: practice minute total"
        end_heading = "### Question"
    else:
        raise AssertionError(f"Unsupported language: {language}")

    section = markdown.split(start_heading, 1)[1].split(end_heading, 1)[0]
    blocks = re.findall(r"```python\s*\n(.*?)\n```", section, re.DOTALL)
    return next((block for block in blocks if "input(" in block), "")


def _runner_code(language: str) -> str:
    markdown = LESSON.read_text(encoding="utf-8")
    if language == "ru":
        start_heading = "### Мини-проект: учёт минут практики"
        end_heading = "### Вопрос"
    elif language == "en":
        start_heading = "### Mini-project: practice minute total"
        end_heading = "### Question"
    else:
        raise AssertionError(f"Unsupported language: {language}")

    section = markdown.split(start_heading, 1)[1].split(end_heading, 1)[0]
    blocks = re.findall(r"```python\s*\n(.*?)\n```", section, re.DOTALL)
    return next((block for block in blocks if "def solve(values):" in block), "")


def _run_project(language: str, entered: str) -> str:
    result = subprocess.run(
        [sys.executable, "-c", _project_code(language)],
        input=entered,
        capture_output=True,
        encoding="utf-8",
        env={**os.environ, "PYTHONIOENCODING": "utf-8"},
        check=True,
        timeout=5,
    )
    return result.stdout.strip()


def test_bilingual_python_mini_project_adds_numeric_inputs_and_handles_bad_text() -> None:
    assert _run_project("ru", "12\n8\n").endswith("Всего: 20 мин")
    assert _run_project("ru", "twelve\n8\n").endswith(
        "Введи целые числа, например 0 или 15."
    )
    assert _run_project("ru", "12\ntwelve\n").endswith(
        "Введи целые числа, например 0 или 15."
    )
    assert _run_project("ru", "-12\n8\n").endswith("Всего: -4 мин")
    assert _run_project("en", "12\n8\n").endswith("Total: 20 minutes")
    assert _run_project("en", "twelve\n8\n").endswith(
        "Enter whole numbers, for example 0 or 15."
    )
    assert _run_project("en", "12\ntwelve\n").endswith(
        "Enter whole numbers, for example 0 or 15."
    )
    assert _run_project("en", "-12\n8\n").endswith("Total: -4 minutes")


def test_bilingual_python_mini_project_runs_in_the_bounded_local_interpreter() -> None:
    for language in ("ru", "en"):
        code = _runner_code(language)
        assert code
        assert execute_python_practice(code, {"values": [12, 8]}) == {
            "status": "ok",
            "result": 20,
        }
        assert execute_python_practice(code, {"values": [0, 0]}) == {
            "status": "ok",
            "result": 0,
        }


def test_bilingual_python_mini_project_states_its_limits_and_next_test_cases() -> None:
    markdown = LESSON.read_text(encoding="utf-8")
    russian = markdown.split("### Мини-проект: учёт минут практики", 1)[1].split(
        "### Вопрос", 1
    )[0]
    english = markdown.split("### Mini-project: practice minute total", 1)[1].split(
        "### Question", 1
    )[0]

    assert "не запускает произвольные скрипты" in russian.lower()
    assert "the code is not sent to an ai model" in english.lower()
    assert "не запрещает отрицательное количество минут" in russian.lower()
    assert "does not reject negative minutes yet" in english.lower()
    assert "локальном Python" in russian
    assert "local Python" in english
    assert "-12" in russian and "-12" in english
