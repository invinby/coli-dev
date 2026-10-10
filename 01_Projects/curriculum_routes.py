"""Audit lesson routes and content that the macOS app bundles with its roadmaps.

The parser follows the table and heading rules used by CurriculumCatalog.swift.
It checks file resolution and learner-facing structure; it does not certify the
accuracy or licensing of the linked source.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


BUILT_IN_SUBJECTS = (
    "Mathematics",
    "English",
    "Physics",
    "Biology",
    "Zoology",
    "Programming",
)
LEVELS = {"foundations", "intermediate", "advanced"}
RESOURCE_ID = re.compile(r"^[a-z0-9_-]{1,80}$")
OPTION_PREFIX = re.compile(r"^\d+[.)]\s+")
REQUIRED_SECTIONS = {
    "Русский": (
        ("Цель",),
        ("Идея и механизм",),
        ("Исследуй и потренируйся", "Исследуй 3D-модель", "Исследуй в тренажёре"),
        ("Вопрос",),
        ("Варианты",),
        ("Ответ",),
        ("Разбор",),
        ("Границы модели", "Границы правила", "Границы вывода", "Границы и безопасный запуск"),
    ),
    "English": (
        ("Goal",),
        ("Idea and mechanism",),
        ("Explore and practise", "Explore and practice", "Explore the 3D model", "Explore the lab"),
        ("Question",),
        ("Options",),
        ("Answer",),
        ("Explanation",),
        ("Limits", "Limits of the inference", "Limits and safe execution"),
    ),
}


@dataclass(frozen=True)
class CurriculumRouteAudit:
    subject_count: int
    level_count: int
    routed_lesson_count: int
    errors: tuple[str, ...]


def _localized_english(value: str) -> str:
    _, separator, english = value.partition(" / ")
    return english.strip().lower() if separator else value.strip().lower()


def _table_cells(line: str) -> list[str]:
    return [cell.strip() for cell in line.strip().strip("|").split("|")]


def _is_table_separator(cells: list[str]) -> bool:
    return bool(cells) and all(cell and set(cell) <= {"-", ":"} for cell in cells)


def _section_body(markdown: str, language: str, heading: str) -> str | None:
    lines = markdown.replace("\r\n", "\n").splitlines()
    language_heading = f"## {language}"
    try:
        start = next(index for index, line in enumerate(lines) if line.strip() == language_heading)
    except StopIteration:
        return None

    language_body: list[str] = []
    for line in lines[start + 1 :]:
        if line.strip().startswith("## "):
            break
        language_body.append(line)

    for index, line in enumerate(language_body):
        if line.strip() == f"### {heading}":
            section: list[str] = []
            for following in language_body[index + 1 :]:
                if following.strip().startswith("### "):
                    break
                section.append(following)
            return "\n".join(section).strip()
    return None


def _option_count(options: str) -> int:
    count = 0
    for line in options.splitlines():
        stripped = line.strip()
        if stripped.startswith("- "):
            if stripped[2:].strip():
                count += 1
        elif OPTION_PREFIX.match(stripped):
            count += 1
    return count


def _audit_lesson(subject: str, resource: str, markdown: str) -> list[str]:
    errors: list[str] = []
    lesson_label = f"{subject}/{resource}.md"
    lines = markdown.splitlines()
    if not any(line.startswith("# ") and line[2:].strip() for line in lines):
        errors.append(f"{lesson_label}: missing lesson title / отсутствует заголовок урока")

    for language, required_groups in REQUIRED_SECTIONS.items():
        for heading_group in required_groups:
            bodies = [_section_body(markdown, language, heading) for heading in heading_group]
            body = next((value for value in bodies if value is not None and value.strip()), None)
            if body is None:
                errors.append(
                    f"{lesson_label}: {language} missing section {heading_group[0]} "
                    f"/ в разделе {language} отсутствует раздел {heading_group[0]}"
                )

        options_heading = "Варианты" if language == "Русский" else "Options"
        answer_heading = "Ответ" if language == "Русский" else "Answer"
        options = _section_body(markdown, language, options_heading) or ""
        answer = _section_body(markdown, language, answer_heading) or ""
        option_count = _option_count(options)
        answer_index = answer.strip()
        if not answer_index.isdecimal() or not 1 <= int(answer_index) <= option_count:
            errors.append(
                f"{lesson_label}: {language} answer index does not point to an option "
                f"/ ответ в разделе {language} не указывает на существующий вариант"
            )

    lines = markdown.replace("\r\n", "\n").splitlines()
    try:
        sources_start = next(index for index, line in enumerate(lines) if line.strip() == "## Sources")
    except StopIteration:
        errors.append(f"{lesson_label}: missing Sources section / отсутствует раздел Sources")
    else:
        if not any("https://" in line for line in lines[sources_start + 1 :]):
            errors.append(f"{lesson_label}: Sources has no HTTPS URL / в Sources нет HTTPS-ссылки")
    return errors


def audit_curriculum_routes(
    areas_root: Path,
    subjects: Iterable[str] = BUILT_IN_SUBJECTS,
) -> CurriculumRouteAudit:
    """Check all linked curriculum resources under an ``02_Areas`` directory."""
    subject_names = tuple(subjects)
    errors: list[str] = []
    level_count = 0
    routed_lesson_count = 0

    for subject in subject_names:
        curriculum_path = areas_root / subject / "curriculum.md"
        if not curriculum_path.is_file():
            errors.append(f"{subject}: missing curriculum.md / отсутствует curriculum.md")
            continue

        markdown = curriculum_path.read_text(encoding="utf-8")
        active_level: str | None = None
        subject_levels: set[str] = set()
        seen_resources: set[str] = set()
        for line_number, raw_line in enumerate(markdown.splitlines(), 1):
            line = raw_line.strip()
            if line.startswith("## "):
                level = _localized_english(line[3:])
                active_level = level if level in LEVELS else None
                if active_level:
                    level_count += 1
                    if active_level in subject_levels:
                        errors.append(
                            f"{subject}/curriculum.md:{line_number}: duplicate level {active_level} "
                            "/ повторяется уровень учебного плана"
                        )
                    subject_levels.add(active_level)
                continue
            if not line.startswith("|") or active_level is None:
                continue

            cells = _table_cells(line)
            if len(cells) < 3 or _is_table_separator(cells):
                continue
            if "Модуль" in cells[0] or "Module" in cells[0]:
                continue
            lesson_cell = cells[2]
            if not lesson_cell.startswith("lesson:"):
                continue

            resource = lesson_cell.removeprefix("lesson:").strip()
            routed_lesson_count += 1
            route_label = f"{subject}/{resource}"
            if not RESOURCE_ID.fullmatch(resource):
                errors.append(
                    f"{subject}/curriculum.md:{line_number}: invalid lesson ID {resource!r} "
                    "/ некорректный ID урока"
                )
                continue
            if resource in seen_resources:
                errors.append(
                    f"{subject}/curriculum.md:{line_number}: duplicate lesson route {resource} "
                    "/ повторяется маршрут урока"
                )
            seen_resources.add(resource)

            lesson_path = areas_root / subject / "lessons" / f"{resource}.md"
            if not lesson_path.is_file():
                errors.append(
                    f"{route_label}.md: linked lesson file is missing "
                    "/ файл связанного урока отсутствует"
                )
                continue
            errors.extend(_audit_lesson(subject, resource, lesson_path.read_text(encoding="utf-8")))

        missing_levels = LEVELS - subject_levels
        if missing_levels:
            errors.append(
                f"{subject}/curriculum.md: missing roadmap levels {', '.join(sorted(missing_levels))} "
                f"/ отсутствуют уровни учебного плана: {', '.join(sorted(missing_levels))}"
            )

    return CurriculumRouteAudit(
        subject_count=len(subject_names),
        level_count=level_count,
        routed_lesson_count=routed_lesson_count,
        errors=tuple(errors),
    )


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(
        description="Check curriculum lesson routes and bilingual lesson structure."
    )
    parser.add_argument("areas_root", type=Path, help="Path to bundled or source 02_Areas directory")
    arguments = parser.parse_args()
    audit = audit_curriculum_routes(arguments.areas_root)
    if audit.errors:
        for issue in audit.errors:
            print(f"ERROR: {issue}")
        print(
            f"Curriculum audit failed: {audit.subject_count} subjects, "
            f"{audit.routed_lesson_count} linked lessons, {len(audit.errors)} issues. "
            "/ Проверка учебных маршрутов не пройдена."
        )
        return 1

    print(
        f"Curriculum audit passed: {audit.subject_count} subjects, {audit.level_count} levels, "
        f"{audit.routed_lesson_count} linked lessons resolve and contain RU/EN checks, explanations, limits, and HTTPS source links. "
        "/ Проверка пройдена: все маршруты ведут к двуязычным урокам с вопросами, разборами, ограничениями и ссылками HTTPS."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
