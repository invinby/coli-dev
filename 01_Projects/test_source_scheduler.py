from __future__ import annotations

import asyncio
from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock

import pytest

import orchestrator


def test_source_scheduler_retries_if_due_time_cannot_be_read(monkeypatch):
    check_sources = AsyncMock()
    monkeypatch.setattr(
        orchestrator.trusted_source_monitor,
        "seconds_until_automatic_check",
        MagicMock(side_effect=RuntimeError("database temporarily unavailable")),
    )
    monkeypatch.setattr(orchestrator.trusted_source_monitor, "check_sources", check_sources)
    sleep = AsyncMock(side_effect=asyncio.CancelledError)
    monkeypatch.setattr(orchestrator.asyncio, "sleep", sleep)

    with pytest.raises(asyncio.CancelledError):
        asyncio.run(orchestrator._trusted_source_check_scheduler())

    sleep.assert_awaited_once_with(6 * 60 * 60)
    check_sources.assert_not_awaited()


def test_source_inventory_exposes_next_automatic_check_time(monkeypatch):
    fixed_now = datetime(2026, 10, 15, 12, 0, tzinfo=timezone.utc)

    class FixedDateTime:
        @staticmethod
        def now(tz=None):
            return fixed_now if tz is not None else fixed_now.replace(tzinfo=None)

    inventory = {"status": "ok", "sources": []}
    monkeypatch.setattr(orchestrator, "datetime", FixedDateTime)
    monkeypatch.setattr(orchestrator, "AUTO_SOURCE_CHECK_ENABLED", True)
    monkeypatch.setattr(orchestrator, "_require_local_settings_request", lambda _request: None)
    monkeypatch.setattr(orchestrator.trusted_source_monitor, "inventory", lambda: dict(inventory))
    monkeypatch.setattr(
        orchestrator.trusted_source_monitor,
        "seconds_until_automatic_check",
        lambda: 900,
    )

    result = asyncio.run(orchestrator.get_trusted_source_inventory(object()))

    assert result["automatic_check_enabled"] is True
    assert result["automatic_check_due_at"] == "2026-10-15T12:15:00Z"


def test_source_inventory_reports_no_next_check_when_automatic_checks_are_disabled(monkeypatch):
    monkeypatch.setattr(orchestrator, "AUTO_SOURCE_CHECK_ENABLED", False)
    monkeypatch.setattr(orchestrator, "_require_local_settings_request", lambda _request: None)
    monkeypatch.setattr(
        orchestrator.trusted_source_monitor,
        "inventory",
        lambda: {"status": "ok", "sources": []},
    )
    next_delay = MagicMock(return_value=60)
    monkeypatch.setattr(orchestrator.trusted_source_monitor, "seconds_until_automatic_check", next_delay)

    result = asyncio.run(orchestrator.get_trusted_source_inventory(object()))

    assert result["automatic_check_enabled"] is False
    assert result["automatic_check_due_at"] is None
    next_delay.assert_not_called()


def test_source_inventory_stays_available_if_next_check_cannot_be_calculated(monkeypatch):
    monkeypatch.setattr(orchestrator, "AUTO_SOURCE_CHECK_ENABLED", True)
    monkeypatch.setattr(orchestrator, "_require_local_settings_request", lambda _request: None)
    monkeypatch.setattr(
        orchestrator.trusted_source_monitor,
        "inventory",
        lambda: {"status": "ok", "listed_count": 1, "sources": [{"url": "https://example.org"}]},
    )
    monkeypatch.setattr(
        orchestrator.trusted_source_monitor,
        "seconds_until_automatic_check",
        MagicMock(side_effect=RuntimeError("database temporarily unavailable")),
    )

    result = asyncio.run(orchestrator.get_trusted_source_inventory(object()))

    assert result["status"] == "ok"
    assert result["listed_count"] == 1
    assert result["automatic_check_due_at"] is None
