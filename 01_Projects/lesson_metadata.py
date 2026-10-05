"""Parse conservative source-review metadata from bundled Markdown lessons."""

from __future__ import annotations

import re
from datetime import date, datetime, timedelta, timezone


def _frontmatter_bounds(lines: list[str]) -> tuple[int, int] | None:
    """Return inclusive zero-based frontmatter bounds for a fenced YAML header."""
    if not lines or lines[0].lstrip("\ufeff").strip() != "---":
        return None
    for index in range(1, len(lines)):
        if lines[index].strip() == "---":
            return 0, index
    return None


def _frontmatter_values(lines: list[str], bounds: tuple[int, int], key: str) -> list[str]:
    """Return all top-level-looking scalar values for one simple frontmatter key."""
    values: list[str] = []
    for line in lines[bounds[0] + 1:bounds[1]]:
        if not line.strip() or line.lstrip().startswith("#") or line[:1].isspace() or ":" not in line:
            continue
        field, value = line.split(":", 1)
        if field.strip() == key:
            values.append(value.strip())
    return values


def _source_checked_date(text: str) -> str | None:
    """Read one strict YYYY-MM-DD source review date from Markdown frontmatter."""
    lines = text.splitlines()
    bounds = _frontmatter_bounds(lines)
    if bounds is None:
        return None
    values = _frontmatter_values(lines, bounds, "source_checked")
    if len(values) != 1 or not re.fullmatch(r"\d{4}-\d{2}-\d{2}", values[0]):
        return None
    try:
        return date.fromisoformat(values[0]).isoformat()
    except ValueError:
        return None


def _source_review_interval_days(text: str) -> int | None:
    """Read one author-declared review interval, bounded to 1 day through 10 years."""
    lines = text.splitlines()
    bounds = _frontmatter_bounds(lines)
    if bounds is None:
        return None
    values = _frontmatter_values(lines, bounds, "source_review_interval_days")
    if len(values) != 1 or not re.fullmatch(r"\d+", values[0]):
        return None
    interval = int(values[0])
    return interval if 1 <= interval <= 3650 else None


def _source_review_schedule(
    checked_at: str | None,
    interval_days: int | None,
    today: date | None = None,
) -> tuple[str | None, str | None]:
    """Return the author-scheduled review date and whether that date has been reached."""
    if (
        checked_at is None
        or interval_days is None
        or not 1 <= interval_days <= 3650
        or not re.fullmatch(r"\d{4}-\d{2}-\d{2}", checked_at)
    ):
        return None, None
    try:
        checked_date = date.fromisoformat(checked_at)
        due_date = checked_date + timedelta(days=interval_days)
    except (OverflowError, ValueError):
        return None, None
    current_date = today or datetime.now(timezone.utc).date()
    return due_date.isoformat(), "due" if due_date <= current_date else "scheduled"
