from pathlib import Path

from curriculum_routes import _section_body, audit_curriculum_routes


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]


def test_all_published_curriculum_routes_resolve_in_the_repository():
    audit = audit_curriculum_routes(REPOSITORY_ROOT / "02_Areas")

    assert audit.errors == (), "\n".join(audit.errors)
    assert audit.subject_count == 6
    assert audit.routed_lesson_count >= 49


def test_english_foundations_route_the_bilingual_subject_pronouns_and_be_lesson():
    curriculum = (REPOSITORY_ROOT / "02_Areas/English/curriculum.md").read_text(encoding="utf-8")
    foundations = curriculum.split("## База / Foundations", maxsplit=1)[1].split(
        "## Углубление / Intermediate", maxsplit=1
    )[0]
    assert "lesson:subject_pronouns_and_be" in foundations
    assert foundations.index("lesson:subject_pronouns_and_be") < foundations.index(
        "lesson:sounds_stress_rhythm"
    )

    audit = audit_curriculum_routes(REPOSITORY_ROOT / "02_Areas", subjects=("English",))
    assert audit.errors == (), "\n".join(audit.errors)

    lesson = (
        REPOSITORY_ROOT / "02_Areas/English/lessons/subject_pronouns_and_be.md"
    ).read_text(encoding="utf-8")
    assert "lesson_id: english.subject_pronouns_and_be" in lesson
    assert "https://learnenglish.britishcouncil.org/free-resources/grammar/a1-a2/present-simple-be" in lesson
    assert "https://learnenglish.britishcouncil.org/free-resources/grammar/english-grammar-reference/personal-pronouns" in lesson

    for language, options_heading, answer_heading in (
        ("Русский", "Варианты", "Ответ"),
        ("English", "Options", "Answer"),
    ):
        options = _section_body(lesson, language, options_heading)
        answer = _section_body(lesson, language, answer_heading)
        assert options is not None
        assert answer is not None
        choices = [line[2:].strip() for line in options.splitlines() if line.strip().startswith("- ")]
        answer_index = int(answer.strip())
        assert 1 <= answer_index <= len(choices)


def test_programming_intro_has_a_reproducible_bilingual_branching_example():
    lesson = (
        REPOSITORY_ROOT / "02_Areas/Programming/lessons/intro.md"
    ).read_text(encoding="utf-8")
    example = (
        "```python\n"
        "temperature = -2\n"
        "if temperature < 0:\n"
        '    state = "ice"\n'
        "elif temperature < 20:\n"
        '    state = "cool"\n'
        "else:\n"
        '    state = "warm"\n'
        "print(state)\n"
        "```"
    )

    assert lesson.count(example) == 2
    assert '`-2 → "ice"` («лёд»), `8 → "cool"` («прохладно»), `25 → "warm"` («тепло»).' in lesson
    assert '`-2 → "ice", 8 → "cool", 25 → "warm"`' in lesson
    assert "Это короткий ознакомительный пример" in lesson
    assert "This is a short preview" in lesson


def test_advanced_math_optimization_route_has_a_complete_lesson():
    curriculum = (REPOSITORY_ROOT / "02_Areas/Mathematics/curriculum.md").read_text(encoding="utf-8")
    advanced = curriculum.split("## Продвинутый уровень / Advanced", maxsplit=1)[1]

    assert "lesson:constrained_optimization_and_lagrange_multipliers" in advanced

    audit = audit_curriculum_routes(REPOSITORY_ROOT / "02_Areas", subjects=("Mathematics",))
    assert audit.errors == (), "\n".join(audit.errors)


def test_full_catalog_audit_requires_bundled_intro_route_manifest(tmp_path):
    areas = tmp_path / "02_Areas"
    for subject in ("Mathematics", "English", "Physics", "Biology", "Zoology", "Programming"):
        subject_dir = areas / subject
        subject_dir.mkdir(parents=True)
        (subject_dir / "curriculum.md").write_text(
            "## Foundations\n\n## Intermediate\n\n## Advanced\n",
            encoding="utf-8",
        )

    audit = audit_curriculum_routes(areas)

    assert any("intro_lesson_routes.json" in issue for issue in audit.errors)


def test_trigonometry_answer_keys_match_the_explained_sine_sign():
    lesson = (
        REPOSITORY_ROOT
        / "02_Areas/Mathematics/lessons/trigonometry_and_periodic_functions.md"
    ).read_text(encoding="utf-8")

    for language, options_heading, answer_heading, expected in (
        ("Русский", "Варианты", "Ответ", "Положительный"),
        ("English", "Options", "Answer", "Positive"),
    ):
        options = _section_body(lesson, language, options_heading)
        answer = _section_body(lesson, language, answer_heading)
        assert options is not None
        assert answer is not None
        choices = [
            line[2:].strip()
            for line in options.splitlines()
            if line.strip().startswith("- ")
        ]

        answer_index = int(answer.strip())
        assert 1 <= answer_index <= len(choices)
        assert choices[answer_index - 1] == expected


def test_domain_and_range_answer_keys_match_the_explained_inequality():
    lesson = (
        REPOSITORY_ROOT
        / "02_Areas/Mathematics/lessons/domain_and_range.md"
    ).read_text(encoding="utf-8")

    for language, options_heading, answer_heading, expected in (
        ("Русский", "Варианты", "Ответ", "x ≤ 8"),
        ("English", "Options", "Answer", "x ≤ 8"),
    ):
        options = _section_body(lesson, language, options_heading)
        answer = _section_body(lesson, language, answer_heading)
        assert options is not None
        assert answer is not None
        choices = [
            line[2:].strip()
            for line in options.splitlines()
            if line.strip().startswith("- ")
        ]

        answer_index = int(answer.strip())
        assert 1 <= answer_index <= len(choices)
        assert choices[answer_index - 1] == expected


def test_rational_expression_answer_keys_preserve_the_excluded_input():
    lesson = (
        REPOSITORY_ROOT
        / "02_Areas/Mathematics/lessons/rational_expressions_and_restrictions.md"
    ).read_text(encoding="utf-8")

    for language, options_heading, answer_heading, expected in (
        (
            "Русский",
            "Варианты",
            "Ответ",
            "`f(x) = x + 3` при `x ≠ 3`; значение исходной функции при 3 не определено.",
        ),
        (
            "English",
            "Options",
            "Answer",
            "`f(x) = x + 3` for `x ≠ 3`; the original function is undefined at 3.",
        ),
    ):
        options = _section_body(lesson, language, options_heading)
        answer = _section_body(lesson, language, answer_heading)
        assert options is not None
        assert answer is not None
        choices = [
            line[2:].strip()
            for line in options.splitlines()
            if line.strip().startswith("- ")
        ]

        answer_index = int(answer.strip())
        assert 1 <= answer_index <= len(choices)
        assert choices[answer_index - 1] == expected


def test_missing_lesson_file_is_reported(tmp_path):
    areas = tmp_path / "02_Areas"
    subject = areas / "Biology"
    subject.mkdir(parents=True)
    (subject / "curriculum.md").write_text(
        "## База / Foundations\n\n"
        "| Модуль / Module | Результат / Outcome | Урок / Lesson |\n"
        "|---|---|---|\n"
        "| Тест / Test | Проверить / Check | lesson:missing_lesson |\n\n"
        "## Углубление / Intermediate\n\n"
        "| Модуль / Module | Результат / Outcome | Урок / Lesson |\n"
        "|---|---|---|\n"
        "| Тест / Test | Проверить / Check | |\n\n"
        "## Продвинутый уровень / Advanced\n\n"
        "| Модуль / Module | Результат / Outcome |\n"
        "|---|---|\n"
        "| Тест / Test | Проверить / Check |\n",
        encoding="utf-8",
    )

    audit = audit_curriculum_routes(areas, subjects=("Biology",))

    assert any("Biology/missing_lesson.md" in issue for issue in audit.errors)


def test_missing_bilingual_explanation_is_reported(tmp_path):
    areas = tmp_path / "02_Areas"
    subject = areas / "Biology"
    lessons = subject / "lessons"
    lessons.mkdir(parents=True)
    (subject / "curriculum.md").write_text(
        "## База / Foundations\n\n"
        "| Модуль / Module | Результат / Outcome | Урок / Lesson |\n"
        "|---|---|---|\n"
        "| Тест / Test | Проверить / Check | lesson:sample |\n\n"
        "## Углубление / Intermediate\n\n"
        "| Модуль / Module | Результат / Outcome | Урок / Lesson |\n"
        "|---|---|---|\n"
        "| Тест / Test | Проверить / Check | |\n\n"
        "## Продвинутый уровень / Advanced\n\n"
        "| Модуль / Module | Результат / Outcome |\n"
        "|---|---|\n"
        "| Тест / Test | Проверить / Check |\n",
        encoding="utf-8",
    )
    (lessons / "sample.md").write_text(
        "# Тест / Test\n\n"
        "## Русский\n### Цель\nЦель\n### Идея и механизм\nИдея\n"
        "### Исследуй и потренируйся\nПрактика\n### Вопрос\nВопрос\n"
        "### Варианты\n1. Да\n### Ответ\n1\n### Разбор\nРазбор\n"
        "### Границы модели\nОграничение\n\n"
        "## English\n### Goal\nGoal\n### Idea and mechanism\nIdea\n"
        "### Explore and practice\nPractice\n### Question\nQuestion\n"
        "### Options\n1. Yes\n### Answer\n1\n### Limits\nLimits\n\n"
        "## Sources\n- [Official source](https://example.org/source)\n",
        encoding="utf-8",
    )

    audit = audit_curriculum_routes(areas, subjects=("Biology",))

    assert any("sample" in issue and "Explanation" in issue for issue in audit.errors)
