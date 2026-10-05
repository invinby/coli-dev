"""Domain-specific review instructions shared by local and cloud tutor roles."""

from __future__ import annotations

SUBJECT_RUBRICS: dict[str, dict[str, str]] = {
    "mathematics": {
        "ru": (
            "Проверяй определения и допустимые условия, не пропускай шаги преобразования, "
            "объясняй применимость правила и проверяй результат подстановкой или граничным случаем. "
            "Не округляй раньше времени."
        ),
        "en": (
            "Check definitions and domain conditions, show valid transformation steps, explain why a rule "
            "applies, and verify results by substitution or boundary cases. Avoid premature rounding."
        ),
    },
    "english": {
        "ru": (
            "Различай грамматику, значение и регистр; проверяй естественность примеров в контексте, "
            "показывай важные исключения и объясняй исправления, а не только называй правильную форму."
        ),
        "en": (
            "Distinguish grammar, meaning, and register; check examples in context, note important exceptions, "
            "and explain corrections instead of merely supplying a preferred form."
        ),
    },
    "physics": {
        "ru": (
            "Явно называй систему и допущения, следи за единицами, направлениями и знаками, "
            "проверяй размерность формул и отделяй идеализированную модель от реального процесса."
        ),
        "en": (
            "State the system and assumptions, track units, directions, and signs, check dimensional "
            "consistency, and distinguish an idealized model from a real process."
        ),
    },
    "biology": {
        "ru": (
            "Различай наблюдение, механизм, генотип и фенотип, а также вероятность и гарантированный "
            "результат. Называй условия модели и не превращай учебное объяснение в медицинский вывод."
        ),
        "en": (
            "Distinguish observation, mechanism, genotype, and phenotype, as well as probability from "
            "certainty. State model assumptions and do not turn educational explanation into medical advice."
        ),
    },
    "zoology": {
        "ru": (
            "Различай поведение отдельного животного, индивидуальное приспособление и наследуемую "
            "адаптацию популяции по поколениям. Учитывай экологический контекст и не обобщай один вид "
            "на всех животных."
        ),
        "en": (
            "Distinguish an individual's behavior, individual acclimation, and heritable population "
            "adaptation across generations. Include ecological context and avoid generalizing from one species."
        ),
    },
    "programming": {
        "ru": (
            "Уточняй или объявляй версию языка, объясняй входы и выходы, проверяй граничные случаи "
            "и безопасность. Не утверждай, что код запускался или проверен тестами, если этого не было."
        ),
        "en": (
            "Ask for or state the language version, explain inputs and outputs, check edge cases and safety, "
            "and never claim code was run or tested when it was not."
        ),
    },
}


def add_subject_rubric(system_prompt: str, subject: str | None, language: str) -> str:
    """Append the fixed rubric for a validated subject, preserving legacy requests."""
    if subject not in SUBJECT_RUBRICS:
        return system_prompt
    language_key = language if language in {"ru", "en"} else "ru"
    rubric = SUBJECT_RUBRICS[subject][language_key]
    header = "Предметная проверка" if language_key == "ru" else "Subject-specific review"
    return f"{system_prompt.rstrip()}\n\n{header}: {rubric}"
