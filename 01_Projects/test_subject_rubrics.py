from __future__ import annotations

import pytest
from pydantic import ValidationError

from subject_rubrics import SUBJECT_RUBRICS, add_subject_rubric


@pytest.mark.parametrize("subject", sorted(SUBJECT_RUBRICS))
@pytest.mark.parametrize("language", ["ru", "en"])
def test_each_supported_subject_has_a_bilingual_rubric(subject: str, language: str) -> None:
    prompt = add_subject_rubric("lesson context", subject, language)

    expected_header = "Предметная проверка" if language == "ru" else "Subject-specific review"
    assert prompt.startswith(f"lesson context\n\n{expected_header}:")
    assert SUBJECT_RUBRICS[subject][language] in prompt


def test_legacy_or_unknown_subject_keeps_the_original_prompt() -> None:
    prompt = "lesson context"

    assert add_subject_rubric(prompt, None, "ru") == prompt
    assert add_subject_rubric(prompt, "medicine", "en") == prompt


def test_invalid_subject_is_rejected_by_the_chat_request_schema() -> None:
    import orchestrator

    with pytest.raises(ValidationError):
        orchestrator.ChatRequest(message="test", subject="medicine")


@pytest.mark.parametrize("subject", sorted(SUBJECT_RUBRICS))
def test_chat_request_accepts_only_supported_subject_codes(subject: str) -> None:
    import orchestrator

    request = orchestrator.ChatRequest(message="test", subject=subject)

    assert request.subject == subject
