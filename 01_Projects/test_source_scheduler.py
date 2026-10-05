from __future__ import annotations

import asyncio
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
