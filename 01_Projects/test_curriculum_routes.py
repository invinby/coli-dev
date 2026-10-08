from pathlib import Path

from curriculum_routes import audit_curriculum_routes


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]


def test_all_published_curriculum_routes_resolve_in_the_repository():
    audit = audit_curriculum_routes(REPOSITORY_ROOT / "02_Areas")

    assert audit.errors == (), "\n".join(audit.errors)
    assert audit.subject_count == 6
    assert audit.routed_lesson_count >= 49


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
