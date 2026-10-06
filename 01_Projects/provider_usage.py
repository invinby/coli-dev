"""Privacy-preserving local records of model usage reported by providers."""

from __future__ import annotations

import sqlite3
import threading
import uuid
import re
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any, Callable

_MAX_COUNTER = 2**63 - 1
_MAX_PROVIDER_LENGTH = 32
_MAX_MODEL_LENGTH = 160
_MAX_FORMAT_LENGTH = 32
_ALLOWED_PROVIDERS = {"gemini", "kimi", "openrouter", "compatible", "ollama"}
_ALLOWED_FORMATS = {"gemini", "openai-compatible", "ollama"}
_RETENTION_DAYS = 90


@dataclass(frozen=True)
class TokenUsage:
    """Exact token counts reported by an upstream provider; missing stays unknown."""

    input_tokens: int | None = None
    output_tokens: int | None = None
    total_tokens: int | None = None

    @property
    def has_reported_counts(self) -> bool:
        return any(value is not None for value in (
            self.input_tokens,
            self.output_tokens,
            self.total_tokens,
        ))


def _counter(value: Any) -> int | None:
    if isinstance(value, bool) or not isinstance(value, int):
        return None
    if value < 0 or value > _MAX_COUNTER:
        return None
    return value


def _usage(input_value: Any, output_value: Any, total_value: Any) -> TokenUsage:
    input_tokens = _counter(input_value)
    output_tokens = _counter(output_value)
    total_tokens = _counter(total_value)
    if total_tokens is None and input_tokens is not None and output_tokens is not None:
        derived_total = input_tokens + output_tokens
        if derived_total <= _MAX_COUNTER:
            total_tokens = derived_total
    return TokenUsage(input_tokens, output_tokens, total_tokens)


def openai_compatible_usage(value: Any) -> TokenUsage:
    if not isinstance(value, dict):
        return TokenUsage()
    return _usage(
        value.get("prompt_tokens"),
        value.get("completion_tokens"),
        value.get("total_tokens"),
    )


def gemini_usage(value: Any) -> TokenUsage:
    if not isinstance(value, dict):
        return TokenUsage()
    return _usage(
        value.get("promptTokenCount"),
        value.get("candidatesTokenCount"),
        value.get("totalTokenCount"),
    )


def ollama_usage(value: Any) -> TokenUsage:
    if not isinstance(value, dict):
        return TokenUsage()
    return _usage(
        value.get("prompt_eval_count"),
        value.get("eval_count"),
        value.get("total_tokens"),
    )


def _bounded_label(value: Any, *, fallback: str, maximum: int) -> str:
    if not isinstance(value, str):
        return fallback
    cleaned = " ".join(value.split())
    return cleaned[:maximum] or fallback


def _safe_model_label(value: Any) -> str:
    if not isinstance(value, str):
        return "unknown"
    cleaned = value.strip()
    if len(cleaned) > _MAX_MODEL_LENGTH or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._:/+-]*", cleaned):
        return "unknown"
    return cleaned


def _timestamp(value: datetime) -> str:
    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


class ProviderUsageStore:
    """Store model/provider counters only, never prompts, answers, or credentials."""

    def __init__(
        self,
        path: Path,
        *,
        clock: Callable[[], datetime] | None = None,
        retention_days: int = _RETENTION_DAYS,
    ) -> None:
        if isinstance(retention_days, bool) or not isinstance(retention_days, int) or not 1 <= retention_days <= 3650:
            raise ValueError("retention_days must be an integer between 1 and 3650")
        self.path = Path(path)
        self._clock = clock or (lambda: datetime.now(timezone.utc))
        self._retention_days = retention_days
        self._lock = threading.RLock()

    def _connect(self) -> sqlite3.Connection:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        connection = sqlite3.connect(self.path, timeout=10)
        connection.row_factory = sqlite3.Row
        connection.execute("PRAGMA busy_timeout = 10000")
        connection.execute(
            """CREATE TABLE IF NOT EXISTS provider_usage_events (
                event_id TEXT PRIMARY KEY,
                occurred_at TEXT NOT NULL,
                provider TEXT NOT NULL,
                model TEXT NOT NULL,
                usage_format TEXT NOT NULL,
                input_tokens INTEGER CHECK (input_tokens IS NULL OR input_tokens >= 0),
                output_tokens INTEGER CHECK (output_tokens IS NULL OR output_tokens >= 0),
                total_tokens INTEGER CHECK (total_tokens IS NULL OR total_tokens >= 0),
                usage_reported INTEGER NOT NULL CHECK (usage_reported IN (0, 1))
            )"""
        )
        connection.execute(
            """CREATE INDEX IF NOT EXISTS provider_usage_date_idx
               ON provider_usage_events (occurred_at)"""
        )
        return connection

    def initialize(self) -> None:
        with self._lock, self._connect() as connection:
            connection.execute("PRAGMA journal_mode = WAL")
            self._prune(connection)

    def _now(self) -> datetime:
        value = self._clock()
        if value.tzinfo is None:
            value = value.replace(tzinfo=timezone.utc)
        return value.astimezone(timezone.utc)

    def _prune(self, connection: sqlite3.Connection, *, now: datetime | None = None) -> None:
        cutoff = _timestamp((now or self._now()) - timedelta(days=self._retention_days))
        connection.execute(
            "DELETE FROM provider_usage_events WHERE occurred_at < ?",
            (cutoff,),
        )

    def record(
        self,
        provider: str,
        model: str,
        usage_format: str,
        usage: TokenUsage,
    ) -> None:
        if not isinstance(provider, str) or provider not in _ALLOWED_PROVIDERS:
            raise ValueError("unsupported provider")
        if not isinstance(usage_format, str) or usage_format not in _ALLOWED_FORMATS:
            raise ValueError("unsupported usage format")
        if not isinstance(usage, TokenUsage):
            raise ValueError("usage must be a TokenUsage record")
        input_tokens = _counter(usage.input_tokens)
        output_tokens = _counter(usage.output_tokens)
        total_tokens = _counter(usage.total_tokens)
        if any(
            original is not None and normalized is None
            for original, normalized in (
                (usage.input_tokens, input_tokens),
                (usage.output_tokens, output_tokens),
                (usage.total_tokens, total_tokens),
            )
        ):
            raise ValueError("token counters must be non-negative integers")
        if total_tokens is None and input_tokens is not None and output_tokens is not None:
            total_tokens = input_tokens + output_tokens
            if total_tokens > _MAX_COUNTER:
                raise ValueError("total token count exceeds the supported range")

        now = self._now()
        with self._lock, self._connect() as connection:
            connection.execute("BEGIN IMMEDIATE")
            self._prune(connection, now=now)
            connection.execute(
                """INSERT INTO provider_usage_events (
                       event_id, occurred_at, provider, model, usage_format,
                       input_tokens, output_tokens, total_tokens, usage_reported
                   ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                (
                    uuid.uuid4().hex,
                    _timestamp(now),
                    _bounded_label(provider, fallback="unknown", maximum=_MAX_PROVIDER_LENGTH),
                    _safe_model_label(model),
                    _bounded_label(usage_format, fallback="unknown", maximum=_MAX_FORMAT_LENGTH),
                    input_tokens,
                    output_tokens,
                    total_tokens,
                    int(usage.has_reported_counts),
                ),
            )

    def summary(self, days: int = 30) -> dict[str, Any]:
        if isinstance(days, bool) or not isinstance(days, int) or not 1 <= days <= _RETENTION_DAYS:
            raise ValueError(f"days must be an integer between 1 and {_RETENTION_DAYS}")
        now = self._now()
        start = now.replace(hour=0, minute=0, second=0, microsecond=0) - timedelta(days=days - 1)
        start_text = _timestamp(start)
        end_text = _timestamp(now)
        with self._lock, self._connect() as connection:
            self._prune(connection, now=now)
            totals = connection.execute(
                """SELECT COUNT(*) AS responses,
                          COALESCE(SUM(usage_reported), 0) AS reported,
                          COALESCE(SUM(input_tokens), 0) AS input_tokens,
                          COALESCE(SUM(output_tokens), 0) AS output_tokens,
                          COALESCE(SUM(total_tokens), 0) AS total_tokens,
                          COALESCE(SUM(input_tokens IS NOT NULL), 0) AS input_responses,
                          COALESCE(SUM(output_tokens IS NOT NULL), 0) AS output_responses,
                          COALESCE(SUM(total_tokens IS NOT NULL), 0) AS total_responses
                   FROM provider_usage_events
                   WHERE occurred_at >= ? AND occurred_at <= ?""",
                (start_text, end_text),
            ).fetchone()
            providers = connection.execute(
                """SELECT provider, model, COUNT(*) AS responses,
                          COALESCE(SUM(usage_reported), 0) AS reported,
                          COALESCE(SUM(input_tokens), 0) AS input_tokens,
                          COALESCE(SUM(output_tokens), 0) AS output_tokens,
                          COALESCE(SUM(total_tokens), 0) AS total_tokens,
                          COALESCE(SUM(input_tokens IS NOT NULL), 0) AS input_responses,
                          COALESCE(SUM(output_tokens IS NOT NULL), 0) AS output_responses,
                          COALESCE(SUM(total_tokens IS NOT NULL), 0) AS total_responses
                   FROM provider_usage_events
                   WHERE occurred_at >= ? AND occurred_at <= ?
                   GROUP BY provider, model
                   ORDER BY responses DESC, provider, model""",
                (start_text, end_text),
            ).fetchall()

        def counts(row: sqlite3.Row) -> dict[str, int]:
            responses = int(row["responses"])
            reported = int(row["reported"])
            return {
                "successful_responses": responses,
                "responses_with_reported_usage": reported,
                "responses_without_reported_usage": responses - reported,
                "input_tokens": int(row["input_tokens"]),
                "output_tokens": int(row["output_tokens"]),
                "total_tokens": int(row["total_tokens"]),
                "responses_with_input_count": int(row["input_responses"]),
                "responses_with_output_count": int(row["output_responses"]),
                "responses_with_total_count": int(row["total_responses"]),
            }

        return {
            "generated_at": _timestamp(now),
            "period_days": days,
            "period_start": start_text,
            "totals": counts(totals),
            "providers": [
                {
                    "provider": row["provider"],
                    "model": row["model"],
                    **counts(row),
                }
                for row in providers
            ],
            "note": (
                "Token counts are included only when returned by the provider. "
                "Missing counters are not estimated; provider charges are not calculated."
            ),
        }
