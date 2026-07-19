#!/usr/bin/env python3
"""
test_orchestrator.py — тесты для coli-dev Orchestrator v4.0 (Коворкинг)

Запуск:
    .venv/bin/python -m pytest 01_Projects/test_orchestrator.py -v --tb=long

Или напрямую:
    .venv/bin/python 01_Projects/test_orchestrator.py
"""

from __future__ import annotations

import asyncio
import gc
import json
import os
import sys
from unittest.mock import AsyncMock, MagicMock, patch

import httpx
import psutil
import pytest
from fastapi.testclient import TestClient

# ─── Поднимаем проект в sys.path — он в подпапке ───
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import orchestrator  # noqa: E402
from orchestrator import (
    DebateLog,
    SessionTracker,
    app,
    session_tracker,
)

# Константы для тестов
TEST_MSG = "Напиши hello world на Python"
SYSTEM_PROMPT = "You are a test assistant."
FAKE_ANSWER = "print('Hello, world!')"
PROC = psutil.Process(os.getpid())


# ─── Fixtures ──────────────────────────────────────────


@pytest.fixture(autouse=True)
def _reset_session_tracker():
    """Сброс сессий перед каждым тестом."""
    session_tracker.reset_mode()
    session_tracker._sessions = []
    session_tracker._mark_dirty()
    session_tracker._save()
    yield
    session_tracker.reset_mode()
    session_tracker._sessions = []
    session_tracker._mark_dirty()
    session_tracker._save()


@pytest.fixture
def client():
    """TestClient с замоканными внешними вызовами."""
    mock_obsidian = MagicMock()
    mock_obsidian.ping = AsyncMock(return_value=False)
    mock_obsidian.available = False

    with (
        patch.object(orchestrator, "_check_network", AsyncMock(return_value=True)),
        patch.object(orchestrator, "_check_ollama", AsyncMock(return_value={
            "available": False, "version": None, "models": None, "model_ready": None,
        })),
        patch.object(orchestrator.state, "obsidian", mock_obsidian),
    ):
        orchestrator.logger.disabled = True
        with TestClient(app) as c:
            yield c


@pytest.fixture
def client_offline():
    """TestClient в offline-режиме."""
    mock_obsidian = MagicMock()
    mock_obsidian.ping = AsyncMock(return_value=False)
    mock_obsidian.available = False

    with (
        patch.object(orchestrator, "_check_network", AsyncMock(return_value=False)),
        patch.object(orchestrator, "_check_ollama", AsyncMock(return_value={
            "available": False, "version": None, "models": None, "model_ready": None,
        })),
        patch.object(orchestrator.state, "obsidian", mock_obsidian),
    ):
        orchestrator.logger.disabled = True
        with TestClient(app) as c:
            yield c


# ─── Тесты API Endpoints ───────────────────────────────


class TestAPIEndpoints:
    """Проверка базовых API эндпоинтов."""

    def test_root_returns_html(self, client):
        """Корень / отдаёт HTML-страницу."""
        resp = client.get("/")
        assert resp.status_code == 200
        assert "text/html" in resp.headers.get("content-type", "")
        assert "coli-dev" in resp.text



    def test_api_status_returns_json(self, client):
        """/api/status возвращает JSON со статусом."""
        resp = client.get("/api/status")
        assert resp.status_code == 200
        data = resp.json()
        assert data["service"] == "coli-dev Orchestrator v4.0"
        assert data["version"] == "4.0.0"
        assert "online" in data
        assert "session" in data
        assert data["session"]["mode"] == "online"

    def test_health_returns_expected_structure(self, client):
        """/health возвращает все обязательные поля."""
        resp = client.get("/health")
        assert resp.status_code == 200
        data = resp.json()
        assert "status" in data
        assert "online" in data
        assert "provider" in data
        assert "gemini_model" in data
        assert "ollama_model" in data
        assert "ollama_available" in data
        assert "uptime_sec" in data
        assert "session_mode" in data
        assert "session_current" in data
        assert "session_max" in data

    def test_api_session_returns_status(self, client):
        """/api/session возвращает статус сессий."""
        resp = client.get("/api/session")
        assert resp.status_code == 200
        data = resp.json()
        assert data["mode"] == "online"
        assert data["current"] == 0
        assert data["max"] == 5
        assert data["can_start"] is True

    def test_api_session_reset(self, client):
        """/api/session/reset сбрасывает режим."""
        session_tracker._mode = "local"
        resp = client.post("/api/session/reset")
        assert resp.status_code == 200
        data = resp.json()
        assert data["status"] == "ok"
        assert data["mode"] == "online"


class TestObsidianEndpoints:
    """Проверка Obsidian-эндпоинтов (503 если недоступен)."""

    def test_obsidian_ping_503_when_unavailable(self, client):
        """Obsidian ping возвращает 503 если не настроен."""
        resp = client.get("/obsidian/ping")
        assert resp.status_code == 503

    def test_obsidian_list_503_when_unavailable(self, client):
        """Obsidian list возвращает 503 если не настроен."""
        resp = client.get("/obsidian/list")
        assert resp.status_code == 503

    def test_obsidian_read_503_when_unavailable(self, client):
        """Obsidian read возвращает 503 если не настроен."""
        resp = client.get("/obsidian/read/test.md")
        assert resp.status_code == 503

    def test_obsidian_write_503_when_unavailable(self, client):
        """Obsidian write возвращает 503 если не настроен."""
        resp = client.put("/obsidian/write/test.md", json={"content": "test"})
        assert resp.status_code == 503

    def test_obsidian_delete_503_when_unavailable(self, client):
        """Obsidian delete возвращает 503 если не настроен."""
        resp = client.delete("/obsidian/delete/test.md")
        assert resp.status_code == 503

    def test_obsidian_search_503_when_unavailable(self, client):
        """Obsidian search возвращает 503 если не настроен."""
        resp = client.post("/obsidian/search", json={"query": "test"})
        assert resp.status_code == 503


# ─── Тесты SessionTracker ─────────────────────────────


class TestSessionTracker:
    """Проверка трекера сессий."""

    def test_can_start_session_initially(self):
        """Изначально можно начать сессию."""
        tracker = SessionTracker(max_per_day=5, duration_hours=1)
        tracker.reset_mode()
        tracker._sessions = []
        assert tracker.can_start_session() is True
        assert tracker.mode == "online"

    def test_session_limit_switches_to_local(self):
        """При исчерпании лимита переключается на local."""
        tracker = SessionTracker(max_per_day=2, duration_hours=1)
        tracker.reset_mode()
        tracker._sessions = []
        tracker.start_session()
        tracker.start_session()
        status = tracker.start_session()
        assert status["mode"] == "local"
        assert status["remaining"] == 0

    def test_local_mode_blocks_sessions(self):
        """В local-режиме новые сессии не начинаются."""
        tracker = SessionTracker(max_per_day=5, duration_hours=1)
        tracker._mode = "local"
        tracker._sessions = []
        assert tracker.can_start_session() is False

    def test_get_status_returns_correct_fields(self):
        """get_status возвращает все нужные поля."""
        tracker = SessionTracker(max_per_day=3, duration_hours=1)
        tracker.reset_mode()
        tracker._sessions = []
        status = tracker.get_status()
        assert "mode" in status
        assert "current" in status
        assert "max" in status
        assert "remaining" in status
        assert "can_start" in status
        assert status["max"] == 3


# ─── Тесты DebateLog ───────────────────────────────────


class TestDebateLog:
    """Проверка лога дебатов."""

    def test_empty_log_html(self):
        """Пустой лог генерирует пустой HTML."""
        log = DebateLog()
        html = log.to_html()
        assert "пуст" in html

    def test_log_add_and_html(self):
        """Добавление записи и генерация HTML."""
        log = DebateLog()
        log.add("cloud-code", "gemini-flash", "Test content", 100)
        log.add("consilium", "freebuff", "Review content", 200)
        html = log.to_html()
        assert "gemini-flash" in html or "Gemini 3.5 Flash" in html
        assert "freebuff" in html or "Freebuff" in html
        assert "300" in html  # total duration

    def test_log_agent_icons(self):
        """Проверка иконок агентов."""
        log = DebateLog()
        assert log._agent_icon("gemini-flash") == "⚡"
        assert log._agent_icon("glm") == "🔮"
        assert log._agent_icon("freebuff") == "🦊"
        assert log._agent_icon("qwen") == "🐉"
        assert log._agent_icon("unknown") == "🤖"

    def test_log_agent_colors(self):
        """Проверка цветов агентов."""
        log = DebateLog()
        assert log._agent_color("gemini-flash") == "#7c5bf0"
        assert log._agent_color("freebuff") == "#f78166"
        assert log._agent_color("qwen") == "#3fb950"


# ─── Тесты SSE Streaming ───────────────────────────────


def _parse_sse(text: str) -> list[dict]:
    """Парсит SSE-ответ в список событий."""
    events = []
    for block in text.split("\n\n"):
        block = block.strip()
        if not block or not block.startswith("data: "):
            continue
        for line in block.split("\n"):
            line = line.strip()
            if line.startswith("data: "):
                try:
                    events.append(json.loads(line[6:]))
                except json.JSONDecodeError:
                    pass
    return events


class TestStreamingChat:
    """Проверка SSE-стриминга через /chat/stream."""

    def test_stream_returns_sse(self, client):
        """/chat/stream возвращает SSE-ответ."""
        mock_answer = "print('Hello, world!')"
        mock_log = DebateLog()
        mock_log.add("consilium", "consensus", "Final answer", 500)

        mock_engine = MagicMock()
        mock_engine.run = AsyncMock(return_value=(mock_answer, mock_log))

        with patch("orchestrator.ConsiliumEngine", return_value=mock_engine):
            resp = client.post("/chat/stream", json={"message": TEST_MSG})
            assert resp.status_code == 200
            assert "text/event-stream" in resp.headers.get("content-type", "")

    def test_stream_contains_debate_log_and_tokens(self, client):
        """Стрим содержит лог дебатов и токены ответа."""
        mock_answer = "Hello world code"
        mock_log = DebateLog()
        mock_log.add("cloud-code", "gemini-flash", "Draft", 100)
        mock_log.add("consilium", "consensus", "Final", 200)

        mock_engine = MagicMock()
        mock_engine.run = AsyncMock(return_value=(mock_answer, mock_log))

        with patch("orchestrator.ConsiliumEngine", return_value=mock_engine):
            resp = client.post("/chat/stream", json={"message": TEST_MSG})
            events = _parse_sse(resp.text)

            types = [e["type"] for e in events]
            assert "debate_log" in types
            assert "token" in types
            assert "done" in types

            tokens = [e["content"] for e in events if e["type"] == "token"]
            full_text = "".join(tokens)
            assert "Hello" in full_text
            assert "world" in full_text

    def test_stream_done_event_has_metadata(self, client):
        """Событие done содержит метаданные (provider, model, duration_ms)."""
        mock_answer = "test"
        mock_log = DebateLog()

        mock_engine = MagicMock()
        mock_engine.run = AsyncMock(return_value=(mock_answer, mock_log))

        with patch("orchestrator.ConsiliumEngine", return_value=mock_engine):
            resp = client.post("/chat/stream", json={"message": TEST_MSG})
            events = _parse_sse(resp.text)
            done_events = [e for e in events if e["type"] == "done"]
            assert len(done_events) == 1
            done = done_events[0]
            assert done["provider"] == "consilium"
            assert done["model"] == "multi-agent"
            assert "duration_ms" in done
            assert "tokens" in done

    def test_stream_local_mode(self, client_offline):
        """В offline-режиме стрим идёт через Digital Twin (Qwen)."""
        mock_answer = "Локальный ответ"
        mock_log = DebateLog()
        mock_log.add("consilium", "qwen", "Local response", 100)

        mock_engine = MagicMock()
        mock_engine.run_local = AsyncMock(return_value=(mock_answer, mock_log))

        with patch("orchestrator.ConsiliumEngine", return_value=mock_engine):
            resp = client_offline.post("/chat/stream", json={"message": TEST_MSG})
            assert resp.status_code == 200
            events = _parse_sse(resp.text)
            done_events = [e for e in events if e["type"] == "done"]
            assert len(done_events) == 1
            assert done_events[0]["provider"] == "local"


# ─── Тесты ConsiliumEngine ─────────────────────────────


class TestConsiliumEngine:
    """Проверка движка консилиума (без async/await — используем asyncio.run)."""

    def test_engine_run_returns_tuple(self):
        """run возвращает (answer, log) кортеж."""
        mock_client = MagicMock(spec=httpx.AsyncClient)

        # OpenRouter-формат для Gemini/Freebuff
        mock_or_response = MagicMock()
        mock_or_response.status_code = 200
        mock_or_response.json.return_value = {
            "choices": [{"message": {"content": FAKE_ANSWER}}]
        }
        mock_or_response.raise_for_status = MagicMock()
        mock_or_response.text = ""

        # Ollama-формат для Qwen Researcher
        mock_ollama_response = MagicMock()
        mock_ollama_response.status_code = 200
        mock_ollama_response.json.return_value = {
            "message": {"content": "Ключевые моменты из исследования"}
        }
        mock_ollama_response.raise_for_status = MagicMock()
        mock_ollama_response.text = ""

        def side_effect(*args, **kwargs):
            url = args[0] if args else kwargs.get("url", "")
            if "ollama" in str(url).lower() or "localhost:11434" in str(url):
                return mock_ollama_response
            return mock_or_response

        mock_client.post = AsyncMock(side_effect=side_effect)

        engine = orchestrator.ConsiliumEngine(mock_client)
        answer, log = asyncio.run(engine.run(TEST_MSG, SYSTEM_PROMPT))

        assert isinstance(answer, str)
        assert isinstance(log, DebateLog)
        assert len(answer) > 0
        assert "[Ошибка" not in answer

    def test_engine_run_local_returns_tuple(self):
        """run_local возвращает (answer, log) кортеж."""
        mock_client = MagicMock(spec=httpx.AsyncClient)

        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "message": {"content": "Локальный ответ"}
        }
        mock_response.raise_for_status = MagicMock()
        mock_response.text = ""
        mock_client.post = AsyncMock(return_value=mock_response)

        engine = orchestrator.ConsiliumEngine(mock_client)
        answer, log = asyncio.run(engine.run_local(TEST_MSG, SYSTEM_PROMPT))

        assert isinstance(answer, str)
        assert isinstance(log, DebateLog)
        assert "[Ошибка" not in answer


# ─── Тест замера памяти ────────────────────────────────


class TestMemoryFootprint:
    """Замер потребления RAM."""

    RSS_THRESHOLD_MB = 20

    def _rss_mb(self) -> float:
        gc.collect()
        return PROC.memory_info().rss / 1024 / 1024

    def test_memory_does_not_leak(self, client):
        """Память не должна существенно расти после 10 запросов."""
        rss_before = self._rss_mb()

        mock_answer = "test response"
        mock_log = DebateLog()
        mock_log.add("consilium", "consensus", "answer", 100)

        mock_engine = MagicMock()
        mock_engine.run = AsyncMock(return_value=(mock_answer, mock_log))
        mock_engine.run_local = AsyncMock(return_value=(mock_answer, mock_log))

        with patch("orchestrator.ConsiliumEngine", return_value=mock_engine):
            for i in range(10):
                resp = client.post(
                    "/chat/stream",
                    json={"message": f"Запрос номер {i}"},
                )
                assert resp.status_code == 200

        rss_after = self._rss_mb()
        growth = rss_after - rss_before

        print(
            f"\n📊 Memory: {rss_before:.1f} MB → {rss_after:.1f} MB  "
            f"(growth: {growth:+.1f} MB, limit: {self.RSS_THRESHOLD_MB} MB)"
        )
        assert growth < self.RSS_THRESHOLD_MB, (
            f"Возможная утечка памяти: {growth:+.1f} MB за 10 запросов "
            f"(лимит: {self.RSS_THRESHOLD_MB} MB)"
        )


# ─── Запуск напрямую ──────────────────────────────────


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
